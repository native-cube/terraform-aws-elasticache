output "cluster_id" {
  description = "Provisioned cluster ID, or null for another deployment type."
  value       = try(aws_elasticache_cluster.main[0].id, null)
}

output "cluster_arn" {
  description = "Provisioned cluster ARN, or null for another deployment type."
  value       = try(aws_elasticache_cluster.main[0].arn, null)
}

output "cluster_engine_version_actual" {
  description = "Actual engine version running on the provisioned cluster, or null for another deployment type."
  value       = try(aws_elasticache_cluster.main[0].engine_version_actual, null)
}

output "cache_nodes" {
  description = "Provisioned cluster cache node connection details, or an empty list for another deployment type."
  value       = try(aws_elasticache_cluster.main[0].cache_nodes, [])
}

output "cluster_address" {
  description = "Memcached cluster DNS address without a port, or null when unavailable."
  value       = try(aws_elasticache_cluster.main[0].cluster_address, null)
}

output "cluster_configuration_endpoint" {
  description = "Memcached cluster configuration endpoint, or null when unavailable."
  value       = try(aws_elasticache_cluster.main[0].configuration_endpoint, null)
}

output "replication_group_id" {
  description = "Redis OSS or Valkey replication group ID, or null for another deployment type."
  value       = try(aws_elasticache_replication_group.main[0].id, null)
}

output "replication_group_arn" {
  description = "Redis OSS or Valkey replication group ARN, or null for another deployment type."
  value       = try(aws_elasticache_replication_group.main[0].arn, null)
}

output "replication_group_engine_version_actual" {
  description = "Actual engine version running on the replication group, or null for another deployment type."
  value       = try(aws_elasticache_replication_group.main[0].engine_version_actual, null)
}

output "replication_group_configuration_endpoint" {
  description = "Configuration endpoint for a cluster-mode-enabled replication group, or null when unavailable."
  value       = try(aws_elasticache_replication_group.main[0].configuration_endpoint_address, null)
}

output "replication_group_primary_endpoint" {
  description = "Primary endpoint for a cluster-mode-disabled replication group, or null when unavailable."
  value       = try(aws_elasticache_replication_group.main[0].primary_endpoint_address, null)
}

output "replication_group_reader_endpoint" {
  description = "Reader endpoint for a cluster-mode-disabled replication group, or null when unavailable."
  value       = try(aws_elasticache_replication_group.main[0].reader_endpoint_address, null)
}

output "replication_group_member_clusters" {
  description = "Cache cluster IDs belonging to the replication group, or an empty set for another deployment type."
  value       = try(aws_elasticache_replication_group.main[0].member_clusters, toset([]))
}

output "global_replication_group_id" {
  description = "Created global replication group ID, joined global replication group ID for a secondary, or null when global replication is unused."
  value       = try(aws_elasticache_global_replication_group.main[0].global_replication_group_id, var.global_replication_group_id)
}

output "global_replication_group_arn" {
  description = "Module-created global replication group ARN, or null when creation is disabled."
  value       = try(aws_elasticache_global_replication_group.main[0].arn, null)
}

output "global_replication_group_engine" {
  description = "Engine of the module-created global replication group, or null when creation is disabled."
  value       = try(aws_elasticache_global_replication_group.main[0].engine, null)
}

output "global_replication_group_engine_version_actual" {
  description = "Actual engine version running across the module-created global replication group, or null when creation is disabled."
  value       = try(aws_elasticache_global_replication_group.main[0].engine_version_actual, null)
}

output "global_replication_group_node_groups" {
  description = "Shard IDs and slot ranges for the module-created global replication group, or an empty set when creation is disabled."
  value       = try(aws_elasticache_global_replication_group.main[0].global_node_groups, toset([]))
}

output "serverless_cache_id" {
  description = "Serverless cache ID, or null for another deployment type."
  value       = try(aws_elasticache_serverless_cache.main[0].id, null)
}

output "serverless_cache_arn" {
  description = "Serverless cache ARN, or null for another deployment type."
  value       = try(aws_elasticache_serverless_cache.main[0].arn, null)
}

output "serverless_cache_endpoint" {
  description = "Serverless cache endpoint details, or an empty list for another deployment type."
  value       = try(aws_elasticache_serverless_cache.main[0].endpoint, [])
}

output "serverless_cache_reader_endpoint" {
  description = "Serverless cache reader endpoint details, or an empty list when unavailable."
  value       = try(aws_elasticache_serverless_cache.main[0].reader_endpoint, [])
}

output "serverless_cache_full_engine_version" {
  description = "Full serverless cache engine version, or null for another deployment type."
  value       = try(aws_elasticache_serverless_cache.main[0].full_engine_version, null)
}

output "serverless_cache_status" {
  description = "Serverless cache status, or null for another deployment type."
  value       = try(aws_elasticache_serverless_cache.main[0].status, null)
}

output "parameter_group_id" {
  description = "Module-created parameter group ID, or null when creation is disabled."
  value       = try(aws_elasticache_parameter_group.main[0].id, null)
}

output "parameter_group_arn" {
  description = "Module-created parameter group ARN, or null when creation is disabled."
  value       = try(aws_elasticache_parameter_group.main[0].arn, null)
}

output "parameter_group_name" {
  description = "Created or existing parameter group name associated with the provisioned deployment, or null when unset."
  value       = local.parameter_group_name
}

output "subnet_group_id" {
  description = "Module-created subnet group ID, or null when creation is disabled."
  value       = try(aws_elasticache_subnet_group.main[0].id, null)
}

output "subnet_group_arn" {
  description = "Module-created subnet group ARN, or null when creation is disabled."
  value       = try(aws_elasticache_subnet_group.main[0].arn, null)
}

output "subnet_group_name" {
  description = "Created or existing subnet group name associated with the provisioned deployment, or null when unset."
  value       = local.subnet_group_name
}

output "subnet_group_vpc_id" {
  description = "VPC ID of the module-created subnet group, or null when creation is disabled."
  value       = try(aws_elasticache_subnet_group.main[0].vpc_id, null)
}
