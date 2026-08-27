resource "aws_elasticache_serverless_cache" "main" {
  count = local.create_serverless ? 1 : 0

  name                     = var.name
  engine                   = local.engine
  region                   = var.region
  daily_snapshot_time      = var.daily_snapshot_time
  description              = var.description
  kms_key_id               = var.kms_key_id
  major_engine_version     = var.major_engine_version
  network_type             = var.network_type
  security_group_ids       = length(var.security_group_ids) == 0 ? null : var.security_group_ids
  snapshot_arns_to_restore = length(var.snapshot_arns_to_restore) == 0 ? null : var.snapshot_arns_to_restore
  snapshot_retention_limit = var.snapshot_retention_limit
  subnet_ids               = length(var.subnet_ids) == 0 ? null : var.subnet_ids
  tags                     = local.common_tags
  user_group_id            = var.user_group_id

  dynamic "cache_usage_limits" {
    for_each = var.cache_usage_limits == null ? [] : [1]

    content {
      dynamic "data_storage" {
        for_each = var.cache_usage_limits.data_storage == null ? [] : [1]

        content {
          minimum = var.cache_usage_limits.data_storage.minimum
          maximum = var.cache_usage_limits.data_storage.maximum
          unit    = var.cache_usage_limits.data_storage.unit
        }
      }

      dynamic "ecpu_per_second" {
        for_each = var.cache_usage_limits.ecpu_per_second == null ? [] : [1]

        content {
          minimum = var.cache_usage_limits.ecpu_per_second.minimum
          maximum = var.cache_usage_limits.ecpu_per_second.maximum
        }
      }
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
      condition     = local.engine == null ? false : contains(["memcached", "redis", "valkey"], local.engine)
      error_message = "A serverless cache requires engine memcached, redis, or valkey."
    }

    precondition {
      condition = local.engine != "memcached" || (
        var.daily_snapshot_time == null &&
        length(var.snapshot_arns_to_restore) == 0 &&
        var.snapshot_retention_limit == null &&
        var.user_group_id == null
      )
      error_message = "Memcached serverless caches do not support snapshots or user groups."
    }

    precondition {
      condition     = !var.create_parameter_group
      error_message = "Serverless caches do not support ElastiCache parameter groups."
    }

    precondition {
      condition     = !var.create_subnet_group
      error_message = "Serverless caches use subnet_ids directly and do not support ElastiCache subnet groups."
    }

    precondition {
      condition = !var.enforce_security_baseline ? true : (
        var.major_engine_version != null &&
        length(var.subnet_ids) > 0 &&
        length(var.security_group_ids) > 0 &&
        (local.engine == "memcached" || var.user_group_id != null)
      )
      error_message = "The security baseline requires an explicit major engine version, subnets, and VPC security groups; Redis OSS and Valkey serverless caches also require an RBAC user group."
    }

    precondition {
      condition = !var.enforce_resilience_baseline ? true : (
        local.engine == "memcached" ||
        (var.snapshot_retention_limit == null ? false : var.snapshot_retention_limit >= 1)
      )
      error_message = "The resilience baseline requires retained automatic snapshots for Redis OSS and Valkey serverless caches. Serverless caches are Multi-AZ by design."
    }
  }
}
