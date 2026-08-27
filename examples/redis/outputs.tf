output "replication_group_id" {
  description = "Redis OSS replication group ID."
  value       = module.redis.replication_group_id
}

output "primary_endpoint" {
  description = "Redis OSS primary endpoint."
  value       = module.redis.replication_group_primary_endpoint
}

output "reader_endpoint" {
  description = "Redis OSS reader endpoint."
  value       = module.redis.replication_group_reader_endpoint
}
