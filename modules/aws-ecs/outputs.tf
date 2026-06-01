output "cluster_arn"  { value = module.ecs.cluster_arn }
output "cluster_name" { value = module.ecs.cluster_name }

# try() bảo vệ khi create_service = false
output "service_name" { value = try(module.ecs.services[var.app_name].name, "") }
output "service_id"   { value = try(module.ecs.services[var.app_name].id, "") }

output "ecs_service_security_group_id" {
  value = try(module.ecs.services[var.app_name].security_group_ids[0], "")
}
