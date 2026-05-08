output "cluster_id" {
  description = "ID of the ElastiCache cluster"
  value       = try(module.elasticache.cluster_id, null)
}

output "cluster_arn" {
  description = "ARN of the ElastiCache cluster"
  value       = try(module.elasticache.arn, null)
}

output "primary_endpoint_address" {
  description = "Primary endpoint address (Redis replication group)"
  value       = try(module.elasticache.primary_endpoint_address, null)
}

output "reader_endpoint_address" {
  description = "Reader endpoint address (Redis replication group)"
  value       = try(module.elasticache.reader_endpoint_address, null)
}

output "cluster_endpoint" {
  description = "Cluster endpoint (Memcached / Redis Cluster Mode)"
  value       = try(module.elasticache.cluster_address, null)
}

output "port" {
  description = "Port of the ElastiCache cluster"
  value       = local.elasticache_config.port
}
