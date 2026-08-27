resource "aws_elasticache_global_replication_group" "main" {
  count = local.create_global_replication_group ? 1 : 0

  region                               = var.region
  automatic_failover_enabled           = local.global_automatic_failover_enabled
  cache_node_type                      = local.global_cache_node_type
  engine                               = local.global_engine
  engine_version                       = local.global_engine_version
  global_replication_group_description = var.global_replication_group_description
  global_replication_group_id_suffix   = local.global_replication_group_id_suffix
  num_node_groups                      = local.global_num_node_groups
  parameter_group_name                 = local.global_parameter_group_name
  primary_replication_group_id         = aws_elasticache_replication_group.main[0].id

  dynamic "timeouts" {
    for_each = var.global_replication_group_timeouts == null ? [] : [1]

    content {
      create = var.global_replication_group_timeouts.create
      update = var.global_replication_group_timeouts.update
      delete = var.global_replication_group_timeouts.delete
    }
  }

  lifecycle {
    precondition {
      condition     = local.global_engine == null ? true : contains(["redis", "valkey"], local.global_engine)
      error_message = "Global replication groups support engine redis or valkey."
    }

    precondition {
      condition     = local.global_automatic_failover_enabled != true || local.replication_group_has_replica
      error_message = "Global datastore intra-Region automatic failover requires at least one replica in every member shard."
    }

    precondition {
      condition     = !var.enforce_security_baseline || local.global_engine_version != null
      error_message = "The security baseline requires an explicit global datastore engine version."
    }
  }
}
