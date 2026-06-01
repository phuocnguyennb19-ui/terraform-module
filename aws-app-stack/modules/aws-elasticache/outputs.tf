output "endpoint"          { value = try(module.elasticache.replication_group_primary_endpoint_address, module.elasticache.cluster_cache_nodes[0].address, "") }
output "reader_endpoint"   { value = try(module.elasticache.replication_group_reader_endpoint_address, "") }
output "port"              { value = var.port }
output "engine"            { value = var.engine }
output "security_group_id" { value = module.elasticache_sg.security_group_id }
