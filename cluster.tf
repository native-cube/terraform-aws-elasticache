resource "aws_elasticache_cluster" "main" {
  count = local.create_cluster ? 1 : 0

  cluster_id                   = var.name
  region                       = var.region
  engine                       = local.cluster_read_replica ? null : local.engine
  node_type                    = local.cluster_read_replica ? null : var.node_type
  num_cache_nodes              = local.cluster_read_replica ? null : var.num_cache_nodes
  parameter_group_name         = local.cluster_read_replica ? null : local.parameter_group_name
  apply_immediately            = local.cluster_read_replica ? null : var.apply_immediately
  auto_minor_version_upgrade   = local.cluster_read_replica ? null : var.auto_minor_version_upgrade
  availability_zone            = local.cluster_read_replica ? null : var.availability_zone
  az_mode                      = local.cluster_read_replica ? null : var.az_mode
  engine_version               = local.cluster_read_replica ? null : var.engine_version
  final_snapshot_identifier    = local.cluster_read_replica ? null : var.final_snapshot_identifier
  ip_discovery                 = local.cluster_read_replica ? null : var.ip_discovery
  maintenance_window           = local.cluster_read_replica ? null : var.maintenance_window
  network_type                 = local.cluster_read_replica ? null : var.network_type
  notification_topic_arn       = local.cluster_read_replica ? null : var.notification_topic_arn
  outpost_mode                 = local.cluster_read_replica ? null : var.outpost_mode
  port                         = local.cluster_read_replica ? null : var.port
  preferred_availability_zones = local.cluster_read_replica ? null : var.preferred_availability_zones
  preferred_outpost_arn        = local.cluster_read_replica ? null : var.preferred_outpost_arn
  replication_group_id         = var.cluster_replication_group_id
  security_group_ids           = local.cluster_read_replica || length(var.security_group_ids) == 0 ? null : var.security_group_ids
  snapshot_arns                = local.cluster_read_replica || length(var.snapshot_arns) == 0 ? null : var.snapshot_arns
  snapshot_name                = local.cluster_read_replica ? null : var.snapshot_name
  snapshot_retention_limit     = local.cluster_read_replica ? null : var.snapshot_retention_limit
  snapshot_window              = local.cluster_read_replica ? null : var.snapshot_window
  subnet_group_name            = local.cluster_read_replica ? null : local.subnet_group_name
  tags                         = local.common_tags
  transit_encryption_enabled   = local.cluster_read_replica ? null : var.transit_encryption_enabled

  dynamic "log_delivery_configuration" {
    for_each = local.cluster_read_replica ? [] : var.log_delivery_configuration

    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.value.log_type
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [1]

    content {
      create = var.timeouts.create
      update = var.timeouts.update
      delete = var.timeouts.delete
    }
  }

  lifecycle {
    precondition {
      condition = local.cluster_read_replica ? true : (
        (local.engine == null ? false : contains(["memcached", "redis"], local.engine)) &&
        var.node_type != null &&
        var.num_cache_nodes != null &&
        local.parameter_group_name != null
      )
      error_message = "A standalone cluster requires engine memcached or redis, node_type, num_cache_nodes, and a created or existing parameter group."
    }

    precondition {
      condition     = local.engine != "redis" || var.num_cache_nodes == null || var.num_cache_nodes == 1
      error_message = "A standalone Redis OSS cluster must set num_cache_nodes to 1; use a replication group for replicas or sharding."
    }

    precondition {
      condition     = local.engine != "memcached" || (var.num_cache_nodes == null ? true : var.num_cache_nodes <= 40)
      error_message = "A Memcached cluster supports between 1 and 40 cache nodes."
    }

    precondition {
      condition     = var.availability_zone == null || var.preferred_availability_zones == null
      error_message = "availability_zone conflicts with preferred_availability_zones."
    }

    precondition {
      condition     = var.preferred_availability_zones == null ? true : (var.num_cache_nodes == null ? true : length(var.preferred_availability_zones) == var.num_cache_nodes)
      error_message = "preferred_availability_zones must contain one entry per cache node."
    }

    precondition {
      condition     = var.outpost_mode == null || var.preferred_outpost_arn != null
      error_message = "preferred_outpost_arn is required when outpost_mode is set."
    }

    precondition {
      condition     = length(var.snapshot_arns) <= 1
      error_message = "A standalone cluster accepts at most one snapshot ARN."
    }

    precondition {
      condition = local.engine != "memcached" || (
        var.final_snapshot_identifier == null &&
        length(var.snapshot_arns) == 0 &&
        var.snapshot_name == null &&
        var.snapshot_retention_limit == null &&
        var.snapshot_window == null
      )
      error_message = "Provisioned Memcached clusters do not support snapshots; use serverless Memcached when backups are required."
    }

    precondition {
      condition     = local.engine != "memcached" || length(var.log_delivery_configuration) == 0
      error_message = "Provisioned Memcached clusters do not support ElastiCache log delivery."
    }

    precondition {
      condition = !local.cluster_read_replica || (
        var.engine == null &&
        var.node_type == null &&
        var.num_cache_nodes == null &&
        var.parameter_group_name == null &&
        !var.create_parameter_group
      )
      error_message = "A read-replica cluster inherits engine, node type, node count, and parameter group settings from cluster_replication_group_id."
    }

    precondition {
      condition = !var.enforce_security_baseline ? true : local.cluster_read_replica || (
        local.engine == "memcached" &&
        var.engine_version != null &&
        var.transit_encryption_enabled == true &&
        local.subnet_group_name != null &&
        length(var.security_group_ids) > 0
      )
      error_message = "The security baseline requires provisioned clusters to use Memcached with TLS, an explicit subnet group, and explicit VPC security groups. Use a replication group or serverless cache for securely encrypted Redis OSS."
    }

    precondition {
      condition = !var.enforce_resilience_baseline ? true : local.cluster_read_replica || (
        local.engine == "memcached" &&
        (var.num_cache_nodes == null ? false : var.num_cache_nodes >= 2) &&
        (
          var.az_mode == "cross-az" ||
          (var.preferred_availability_zones == null ? false : length(distinct(var.preferred_availability_zones)) >= 2)
        )
      )
      error_message = "The resilience baseline requires provisioned Memcached to use at least two nodes across Availability Zones; standalone Redis OSS cannot satisfy this baseline."
    }
  }
}
