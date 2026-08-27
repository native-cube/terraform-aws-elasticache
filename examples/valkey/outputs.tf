output "serverless_cache_id" {
  description = "Valkey serverless cache ID."
  value       = module.valkey.serverless_cache_id
}

output "endpoint" {
  description = "Valkey serverless cache endpoint."
  value       = module.valkey.serverless_cache_endpoint
}

output "reader_endpoint" {
  description = "Valkey serverless cache reader endpoint."
  value       = module.valkey.serverless_cache_reader_endpoint
}
