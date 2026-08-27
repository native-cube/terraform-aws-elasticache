mock_provider "aws" {
  override_during = plan
}

run "disabled" {
  command = plan

  variables {
    name            = "unit-disabled"
    deployment_type = "cluster"
    create          = false
  }

  assert {
    condition = (
      length(aws_elasticache_cluster.main) == 0 &&
      length(aws_elasticache_replication_group.main) == 0 &&
      length(aws_elasticache_global_replication_group.main) == 0 &&
      length(aws_elasticache_serverless_cache.main) == 0 &&
      length(aws_elasticache_parameter_group.main) == 0 &&
      length(aws_elasticache_subnet_group.main) == 0
    )
    error_message = "create=false must disable the primary deployment and supporting resources."
  }
}

run "memcached_cluster" {
  command = plan

  variables {
    name                       = "unit-memcached"
    deployment_type            = "cluster"
    engine                     = "memcached"
    engine_version             = "1.6.22"
    node_type                  = "cache.t4g.small"
    num_cache_nodes            = 2
    port                       = 11211
    transit_encryption_enabled = true

    create_parameter_group = true
    parameter_group_family = "memcached1.6"

    create_subnet_group = true
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]

    security_group_ids = ["sg-0123456789abcdef0"]
    tags = {
      Environment = "unit"
    }
  }

  assert {
    condition = (
      length(aws_elasticache_cluster.main) == 1 &&
      length(aws_elasticache_replication_group.main) == 0 &&
      length(aws_elasticache_serverless_cache.main) == 0
    )
    error_message = "deployment_type=cluster must create only the provisioned cluster resource."
  }

  assert {
    condition = (
      aws_elasticache_cluster.main[0].cluster_id == "unit-memcached" &&
      aws_elasticache_cluster.main[0].parameter_group_name == "unit-memcached-parameters" &&
      aws_elasticache_cluster.main[0].subnet_group_name == "unit-memcached-subnets"
    )
    error_message = "The cluster must use the module name and module-created parameter and subnet groups."
  }

  assert {
    condition = (
      aws_elasticache_cluster.main[0].tags["Environment"] == "unit" &&
      aws_elasticache_cluster.main[0].tags["terraform-module"] == "elasticache" &&
      aws_elasticache_cluster.main[0].tags["elasticache-cache"] == "unit-memcached"
    )
    error_message = "Module common tags must follow the MQ/S3 tagging convention."
  }
}

run "redis_replication_group" {
  command = plan

  variables {
    name                       = "unit-redis"
    deployment_type            = "replication_group"
    description                = "Unit Redis replication group"
    engine                     = "redis"
    engine_version             = "7.2"
    node_type                  = "cache.t4g.small"
    num_cache_clusters         = 2
    automatic_failover_enabled = true
    multi_az_enabled           = true
    at_rest_encryption_enabled = true
    transit_encryption_enabled = true
  }

  assert {
    condition = (
      length(aws_elasticache_cluster.main) == 0 &&
      length(aws_elasticache_replication_group.main) == 1 &&
      length(aws_elasticache_serverless_cache.main) == 0
    )
    error_message = "deployment_type=replication_group must create only the replication group resource."
  }

  assert {
    condition = (
      aws_elasticache_replication_group.main[0].replication_group_id == "unit-redis" &&
      aws_elasticache_replication_group.main[0].engine == "redis" &&
      aws_elasticache_replication_group.main[0].num_cache_clusters == 2
    )
    error_message = "Redis replication-group inputs must be passed to the main resource."
  }
}

run "valkey_serverless" {
  command = plan

  variables {
    name                     = "unit-valkey-serverless"
    deployment_type          = "serverless"
    engine                   = "valkey"
    major_engine_version     = "8"
    subnet_ids               = ["subnet-0123456789abcdef0"]
    security_group_ids       = ["sg-0123456789abcdef0"]
    snapshot_retention_limit = 7
    cache_usage_limits = {
      data_storage = {
        minimum = 1
        maximum = 10
      }
      ecpu_per_second = {
        minimum = 1000
        maximum = 5000
      }
    }
  }

  assert {
    condition = (
      length(aws_elasticache_cluster.main) == 0 &&
      length(aws_elasticache_replication_group.main) == 0 &&
      length(aws_elasticache_serverless_cache.main) == 1
    )
    error_message = "deployment_type=serverless must create only the serverless cache resource."
  }

  assert {
    condition = (
      aws_elasticache_serverless_cache.main[0].name == "unit-valkey-serverless" &&
      aws_elasticache_serverless_cache.main[0].engine == "valkey" &&
      aws_elasticache_serverless_cache.main[0].cache_usage_limits[0].data_storage[0].maximum == 10 &&
      aws_elasticache_serverless_cache.main[0].cache_usage_limits[0].ecpu_per_second[0].maximum == 5000
    )
    error_message = "Valkey serverless settings and both usage-limit blocks must be passed to the main resource."
  }
}
