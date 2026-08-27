mock_provider "aws" {
  override_during = plan
}

run "standalone_cluster_requires_configuration" {
  command = plan

  variables {
    name            = "invalid-cluster"
    deployment_type = "cluster"
    engine          = "redis"
  }

  expect_failures = [aws_elasticache_cluster.main[0]]
}

run "redis_cluster_is_single_node" {
  command = plan

  variables {
    name                 = "invalid-redis-nodes"
    deployment_type      = "cluster"
    engine               = "redis"
    node_type            = "cache.t4g.small"
    num_cache_nodes      = 2
    parameter_group_name = "default.redis7"
  }

  expect_failures = [aws_elasticache_cluster.main[0]]
}

run "replication_group_rejects_conflicting_topology" {
  command = plan

  variables {
    name                    = "invalid-topology"
    deployment_type         = "replication_group"
    engine                  = "redis"
    node_type               = "cache.t4g.small"
    num_cache_clusters      = 2
    num_node_groups         = 2
    replicas_per_node_group = 1
  }

  expect_failures = [aws_elasticache_replication_group.main[0]]
}

run "multi_az_requires_failover" {
  command = plan

  variables {
    name                       = "invalid-multi-az"
    deployment_type            = "replication_group"
    engine                     = "redis"
    node_type                  = "cache.t4g.small"
    num_cache_clusters         = 2
    multi_az_enabled           = true
    automatic_failover_enabled = false
  }

  expect_failures = [aws_elasticache_replication_group.main[0]]
}

run "memcached_serverless_rejects_snapshots" {
  command = plan

  variables {
    name                     = "invalid-memcached"
    deployment_type          = "serverless"
    engine                   = "memcached"
    snapshot_retention_limit = 1
  }

  expect_failures = [aws_elasticache_serverless_cache.main[0]]
}

run "serverless_rejects_parameter_group" {
  command = plan

  variables {
    name                   = "invalid-serverless-group"
    deployment_type        = "serverless"
    engine                 = "valkey"
    create_parameter_group = true
    parameter_group_family = "valkey8"
  }

  expect_failures = [aws_elasticache_serverless_cache.main[0]]
}

run "created_parameter_group_requires_family" {
  command = plan

  variables {
    name                   = "invalid-parameters"
    deployment_type        = "replication_group"
    engine                 = "valkey"
    node_type              = "cache.t4g.small"
    create_parameter_group = true
  }

  expect_failures = [aws_elasticache_parameter_group.main[0]]
}

run "created_subnet_group_requires_subnets" {
  command = plan

  variables {
    name                = "invalid-subnets"
    deployment_type     = "replication_group"
    engine              = "redis"
    node_type           = "cache.t4g.small"
    create_subnet_group = true
  }

  expect_failures = [aws_elasticache_subnet_group.main[0]]
}

run "global_creation_requires_primary_replication_group" {
  command = plan

  variables {
    name                            = "invalid-global-cluster"
    deployment_type                 = "cluster"
    engine                          = "redis"
    node_type                       = "cache.t4g.small"
    num_cache_nodes                 = 1
    parameter_group_name            = "default.redis7"
    create_global_replication_group = true
  }

  expect_failures = [var.create_global_replication_group]
}

run "global_primary_cannot_also_be_secondary" {
  command = plan

  variables {
    name                            = "invalid-global-member"
    deployment_type                 = "replication_group"
    global_replication_group_id     = "existing-global-datastore"
    num_cache_clusters              = 1
    create_global_replication_group = true
  }

  expect_failures = [var.create_global_replication_group]
}
