mock_provider "aws" {
  override_during = plan
}

run "cluster_read_replica" {
  command = plan

  variables {
    name                         = "unit-read-replica"
    deployment_type              = "cluster"
    cluster_replication_group_id = "existing-redis"
  }

  assert {
    condition     = aws_elasticache_cluster.main[0].replication_group_id == "existing-redis"
    error_message = "Read-replica clusters must attach to an existing replication group and inherit its engine settings."
  }
}

run "sharded_valkey_with_logs_and_timeouts" {
  command = plan

  variables {
    name                       = "unit-sharded-valkey"
    deployment_type            = "replication_group"
    description                = "Sharded Valkey"
    engine                     = "valkey"
    engine_version             = "9.0"
    node_type                  = "cache.r7g.large"
    cluster_mode               = "enabled"
    durability                 = "sync"
    num_node_groups            = 2
    replicas_per_node_group    = 1
    automatic_failover_enabled = true
    multi_az_enabled           = true
    at_rest_encryption_enabled = true
    transit_encryption_enabled = true
    log_delivery_configuration = [{
      destination      = "elasticache-engine"
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "engine-log"
    }]
    timeouts = {
      create = "90m"
      update = "90m"
      delete = "60m"
    }
  }

  assert {
    condition = (
      aws_elasticache_replication_group.main[0].durability == "sync" &&
      aws_elasticache_replication_group.main[0].num_node_groups == 2 &&
      length(aws_elasticache_replication_group.main[0].log_delivery_configuration) == 1 &&
      aws_elasticache_replication_group.main[0].timeouts.create == "90m"
    )
    error_message = "Replication groups must expose Valkey durability, sharding, logs, and custom timeouts."
  }
}

run "explicit_node_group_configuration" {
  command = plan

  variables {
    name                       = "unit-node-groups"
    deployment_type            = "replication_group"
    engine                     = "redis"
    node_type                  = "cache.r7g.large"
    num_node_groups            = 2
    automatic_failover_enabled = true
    node_group_configuration = [
      {
        node_group_id              = "0001"
        primary_availability_zone  = "eu-west-2a"
        replica_availability_zones = ["eu-west-2b"]
        replica_count              = 1
        slots                      = "0-8191"
      },
      {
        node_group_id              = "0002"
        primary_availability_zone  = "eu-west-2b"
        replica_availability_zones = ["eu-west-2a"]
        replica_count              = 1
        slots                      = "8192-16383"
      }
    ]
  }

  assert {
    condition     = aws_elasticache_replication_group.main[0].num_node_groups == 2
    error_message = "Explicit shard placement and slot configuration must be supported."
  }
}

run "serverless_memcached" {
  command = plan

  variables {
    name                 = "unit-memcached-serverless"
    deployment_type      = "serverless"
    engine               = "memcached"
    major_engine_version = "1.6"
    network_type         = "dual_stack"
    subnet_ids           = ["subnet-0123456789abcdef0"]
    security_group_ids   = ["sg-0123456789abcdef0"]
  }

  assert {
    condition = (
      aws_elasticache_serverless_cache.main[0].engine == "memcached" &&
      aws_elasticache_serverless_cache.main[0].network_type == "dual_stack"
    )
    error_message = "Serverless Memcached must support current engine and network arguments."
  }
}

run "write_only_auth_token" {
  command = plan

  variables {
    name                       = "unit-secure-valkey"
    deployment_type            = "replication_group"
    engine                     = "valkey"
    node_type                  = "cache.t4g.small"
    num_cache_clusters         = 1
    transit_encryption_enabled = true
    auth_token_wo              = "UnitTestWriteOnlyToken-2026!"
    auth_token_wo_version      = 1
  }

  assert {
    condition = (
      aws_elasticache_replication_group.main[0].auth_token_wo_version == 1 &&
      aws_elasticache_replication_group.main[0].transit_encryption_enabled == true
    )
    error_message = "Replication groups must accept the provider 6.62 write-only AUTH token and version arguments."
  }
}

run "global_replication_group_secondary" {
  command = plan

  variables {
    name                        = "unit-global-secondary"
    deployment_type             = "replication_group"
    global_replication_group_id = "global-datastore-example"
    num_cache_clusters          = 1
  }

  assert {
    condition     = aws_elasticache_replication_group.main[0].global_replication_group_id == "global-datastore-example"
    error_message = "Global secondaries must inherit engine and node settings from the primary global datastore."
  }
}

run "global_replication_group_primary" {
  command = plan

  variables {
    name                                 = "unit-global-primary"
    deployment_type                      = "replication_group"
    description                          = "Global Valkey primary"
    engine                               = "valkey"
    engine_version                       = "8.0"
    node_type                            = "cache.r7g.large"
    num_cache_clusters                   = 2
    automatic_failover_enabled           = true
    multi_az_enabled                     = true
    create_global_replication_group      = true
    global_replication_group_id_suffix   = "unit-global"
    global_replication_group_description = "Unit global datastore"
    global_automatic_failover_enabled    = true
    global_cache_node_type               = "cache.r7g.xlarge"
    global_engine                        = "valkey"
    global_engine_version                = "8.1"
    global_num_node_groups               = 1
    global_parameter_group_name          = "default.valkey8"
    global_replication_group_timeouts = {
      create = "45m"
      update = "60m"
      delete = "30m"
    }
  }

  assert {
    condition = (
      length(aws_elasticache_global_replication_group.main) == 1 &&
      aws_elasticache_global_replication_group.main[0].global_replication_group_id_suffix == "unit-global" &&
      aws_elasticache_global_replication_group.main[0].global_replication_group_description == "Unit global datastore" &&
      aws_elasticache_global_replication_group.main[0].automatic_failover_enabled == true &&
      aws_elasticache_global_replication_group.main[0].cache_node_type == "cache.r7g.xlarge" &&
      aws_elasticache_global_replication_group.main[0].engine == "valkey" &&
      aws_elasticache_global_replication_group.main[0].engine_version == "8.1" &&
      aws_elasticache_global_replication_group.main[0].num_node_groups == 1 &&
      aws_elasticache_global_replication_group.main[0].parameter_group_name == "default.valkey8" &&
      aws_elasticache_global_replication_group.main[0].timeouts.update == "60m"
    )
    error_message = "Global replication groups must expose every configurable provider argument and custom timeouts."
  }
}
