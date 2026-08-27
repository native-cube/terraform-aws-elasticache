output "cluster_id" {
  description = "Memcached cluster ID."
  value       = module.memcached.cluster_id
}

output "configuration_endpoint" {
  description = "Memcached configuration endpoint."
  value       = module.memcached.cluster_configuration_endpoint
}

output "cache_nodes" {
  description = "Memcached cache node connection details."
  value       = module.memcached.cache_nodes
}
