locals {
  create_cluster           = var.create && var.deployment_type == "cluster"
  create_replication_group = var.create && var.deployment_type == "replication_group"
  create_global_replication_group = (
    local.create_replication_group && var.create_global_replication_group
  )
  create_serverless      = var.create && var.deployment_type == "serverless"
  create_parameter_group = var.create && var.create_parameter_group
  create_subnet_group    = var.create && var.create_subnet_group
  cluster_read_replica   = local.create_cluster && var.cluster_replication_group_id != null

  engine = var.engine == null ? null : lower(var.engine)

  global_engine = var.global_engine == null ? local.engine : lower(var.global_engine)
  global_replication_group_id_suffix = coalesce(
    var.global_replication_group_id_suffix,
    var.name
  )
  global_automatic_failover_enabled = var.global_automatic_failover_enabled == null ? var.automatic_failover_enabled : var.global_automatic_failover_enabled
  global_cache_node_type            = var.global_cache_node_type == null ? var.node_type : var.global_cache_node_type
  global_engine_version             = var.global_engine_version == null ? var.engine_version : var.global_engine_version
  global_num_node_groups            = var.global_num_node_groups == null ? var.num_node_groups : var.global_num_node_groups

  parameter_group_name = local.create_parameter_group ? aws_elasticache_parameter_group.main[0].name : var.parameter_group_name
  subnet_group_name    = local.create_subnet_group ? aws_elasticache_subnet_group.main[0].name : var.subnet_group_name
  global_parameter_group_name = (
    var.global_parameter_group_name == null
    ? local.parameter_group_name
    : var.global_parameter_group_name
  )

  common_tags = merge(
    var.tags,
    {
      "terraform-module"  = "elasticache"
      "elasticache-cache" = var.name
    }
  )
}
