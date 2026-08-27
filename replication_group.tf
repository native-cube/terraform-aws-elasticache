resource "aws_elasticache_replication_group" "main" {
  count = local.create_replication_group ? 1 : 0

  replication_group_id        = var.name
  description                 = var.description
  region                      = var.region
  apply_immediately           = var.apply_immediately
  at_rest_encryption_enabled  = var.at_rest_encryption_enabled
  auth_token                  = var.auth_token
  auth_token_update_strategy  = var.auth_token_update_strategy == null ? null : upper(var.auth_token_update_strategy)
  auth_token_wo               = var.auth_token_wo
  auth_token_wo_version       = var.auth_token_wo_version
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  automatic_failover_enabled  = var.automatic_failover_enabled
  cluster_mode                = var.cluster_mode
  data_tiering_enabled        = var.data_tiering_enabled
  durability                  = var.durability
  engine                      = local.engine
  engine_version              = var.engine_version
  final_snapshot_identifier   = var.final_snapshot_identifier
  global_replication_group_id = var.global_replication_group_id
  ip_discovery                = var.ip_discovery
  kms_key_id                  = var.kms_key_id
  maintenance_window          = var.maintenance_window
  multi_az_enabled            = var.multi_az_enabled
  network_type                = var.network_type
  node_type                   = var.node_type
  notification_topic_arn      = var.notification_topic_arn
  num_cache_clusters          = var.num_cache_clusters
  num_node_groups             = var.num_node_groups
  parameter_group_name        = local.parameter_group_name
  port                        = var.port
  preferred_cache_cluster_azs = var.preferred_cache_cluster_azs
  replicas_per_node_group     = var.replicas_per_node_group
  security_group_ids          = length(var.security_group_ids) == 0 ? null : var.security_group_ids
  security_group_names        = length(var.security_group_names) == 0 ? null : var.security_group_names
  snapshot_arns               = length(var.snapshot_arns) == 0 ? null : var.snapshot_arns
  snapshot_name               = var.snapshot_name
  snapshot_retention_limit    = var.snapshot_retention_limit
  snapshot_window             = var.snapshot_window
  subnet_group_name           = local.subnet_group_name
  tags                        = local.common_tags
  transit_encryption_enabled  = var.transit_encryption_enabled
  transit_encryption_mode     = var.transit_encryption_mode
  user_group_ids              = length(var.user_group_ids) == 0 ? null : var.user_group_ids

  dynamic "log_delivery_configuration" {
    for_each = var.log_delivery_configuration

    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.value.log_type
    }
  }

  dynamic "node_group_configuration" {
    for_each = var.node_group_configuration

    content {
      node_group_id              = node_group_configuration.value.node_group_id
      primary_availability_zone  = node_group_configuration.value.primary_availability_zone
      primary_outpost_arn        = node_group_configuration.value.primary_outpost_arn
      replica_availability_zones = node_group_configuration.value.replica_availability_zones
      replica_count              = node_group_configuration.value.replica_count
      replica_outpost_arns       = node_group_configuration.value.replica_outpost_arns
      slots                      = node_group_configuration.value.slots
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
      condition     = local.engine == null ? true : contains(["redis", "valkey"], local.engine)
      error_message = "Replication groups support engine redis or valkey; omit engine only when joining a global replication group."
    }

    precondition {
      condition     = var.global_replication_group_id != null || local.engine != null
      error_message = "engine is required unless global_replication_group_id is set."
    }

    precondition {
      condition     = var.global_replication_group_id != null || var.node_type != null
      error_message = "node_type is required unless global_replication_group_id is set."
    }

    precondition {
      condition = !(
        var.num_cache_clusters != null &&
        (var.num_node_groups != null || var.replicas_per_node_group != null)
      )
      error_message = "num_cache_clusters conflicts with num_node_groups and replicas_per_node_group."
    }

    precondition {
      condition     = length(var.node_group_configuration) == 0 || var.num_node_groups != null
      error_message = "node_group_configuration requires num_node_groups."
    }

    precondition {
      condition     = var.replicas_per_node_group == null || var.num_node_groups != null
      error_message = "replicas_per_node_group requires num_node_groups."
    }

    precondition {
      condition     = length(var.node_group_configuration) == 0 || var.preferred_cache_cluster_azs == null
      error_message = "node_group_configuration conflicts with preferred_cache_cluster_azs."
    }

    precondition {
      condition     = var.multi_az_enabled != true || var.automatic_failover_enabled == true
      error_message = "multi_az_enabled requires automatic_failover_enabled."
    }

    precondition {
      condition     = var.automatic_failover_enabled != true || local.replication_group_has_replica
      error_message = "automatic_failover_enabled requires at least one replica: num_cache_clusters >= 2 or at least one replica in every shard."
    }

    precondition {
      condition     = var.kms_key_id == null || var.at_rest_encryption_enabled == true
      error_message = "kms_key_id requires at_rest_encryption_enabled."
    }

    precondition {
      condition     = var.auth_token == null || var.auth_token_wo == null
      error_message = "Set auth_token or auth_token_wo, not both."
    }

    precondition {
      condition     = (var.auth_token_wo == null) == (var.auth_token_wo_version == null)
      error_message = "auth_token_wo and auth_token_wo_version must be set together."
    }

    precondition {
      condition = var.auth_token_update_strategy == null ? true : (
        upper(var.auth_token_update_strategy) == "DELETE"
        ? var.auth_token == null && var.auth_token_wo == null
        : var.auth_token != null || var.auth_token_wo != null
      )
      error_message = "auth_token_update_strategy SET or ROTATE requires a token; DELETE requires both token inputs to be null."
    }

    precondition {
      condition     = (var.auth_token == null && var.auth_token_wo == null) || length(var.user_group_ids) == 0
      error_message = "AUTH tokens conflict with user_group_ids."
    }

    precondition {
      condition = (
        (var.auth_token == null && var.auth_token_wo == null) ||
        var.transit_encryption_enabled == true
      )
      error_message = "AUTH tokens require transit_encryption_enabled."
    }

    precondition {
      condition     = var.transit_encryption_mode == null || var.transit_encryption_enabled == true
      error_message = "transit_encryption_mode requires transit_encryption_enabled."
    }

    precondition {
      condition     = var.global_replication_group_id == null || var.num_node_groups == null
      error_message = "num_node_groups cannot be set when global_replication_group_id is set."
    }

    precondition {
      condition     = !local.global_deployment || var.durability == null
      error_message = "ElastiCache global datastores do not support durability-enabled replication groups."
    }

    precondition {
      condition = !local.global_deployment || (
        (var.network_type == null || var.network_type == "ipv4") &&
        (var.ip_discovery == null || var.ip_discovery == "ipv4")
      )
      error_message = "ElastiCache global datastores support IPv4 only."
    }

    precondition {
      condition     = !local.global_deployment || var.auto_minor_version_upgrade != true
      error_message = "ElastiCache disables automatic minor version upgrades for global datastore members; set auto_minor_version_upgrade to false or null."
    }

    precondition {
      condition = !var.enforce_security_baseline ? true : (
        local.subnet_group_name != null &&
        length(var.security_group_ids) > 0 &&
        (
          var.global_replication_group_id != null ||
          (
            var.engine_version != null &&
            var.at_rest_encryption_enabled == true &&
            var.transit_encryption_enabled == true &&
            (var.auth_token != null || var.auth_token_wo != null || length(var.user_group_ids) > 0)
          )
        )
      )
      error_message = "The security baseline requires an explicit subnet group and VPC security groups plus at-rest encryption, TLS, and AUTH or RBAC for a primary replication group. Global secondaries inherit encryption and authentication."
    }

    precondition {
      condition = !var.enforce_resilience_baseline ? true : (
        local.replication_group_has_replica &&
        (
          var.global_replication_group_id != null ||
          (var.automatic_failover_enabled == true && var.multi_az_enabled == true)
        ) &&
        (var.snapshot_retention_limit == null ? false : var.snapshot_retention_limit >= 1) &&
        var.final_snapshot_identifier != null
      )
      error_message = "The resilience baseline requires replicas, Multi-AZ automatic failover for primaries, retained automatic snapshots, and a final snapshot identifier."
    }
  }
}
