output "global_replication_group_id" {
  description = "Global replication group ID shared by both regional members."
  value       = module.primary.global_replication_group_id
}

output "global_replication_group_arn" {
  description = "Global replication group ARN."
  value       = module.primary.global_replication_group_arn
}

output "primary_endpoint" {
  description = "Writable primary replication group endpoint."
  value       = module.primary.replication_group_primary_endpoint
}

output "primary_reader_endpoint" {
  description = "Primary Region reader endpoint."
  value       = module.primary.replication_group_reader_endpoint
}

output "secondary_reader_endpoint" {
  description = "Secondary Region reader endpoint."
  value       = module.secondary.replication_group_reader_endpoint
}
