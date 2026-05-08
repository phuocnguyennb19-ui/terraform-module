output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = module.alb_sg.security_group_id
}

output "alb_sg_arn" {
  description = "ARN of the ALB security group"
  value       = module.alb_sg.security_group_arn
}

output "lb_id" { value = module.alb.id }
output "lb_arn" { value = module.alb.arn }
output "lb_dns_name" { value = module.alb.dns_name }
output "lb_zone_id" { value = module.alb.zone_id }

# V9 Migration: Listeners & Target Groups hiện là Maps
output "listeners" { value = module.alb.listeners }
output "target_groups" { value = module.alb.target_groups }

# Backward Compatibility cho Engine cũ (nếu cần)
output "http_tcp_listener_arns" {
  value = [for k, v in module.alb.listeners : v.arn]
}

output "target_group_arns" {
  value = [for k, v in module.alb.target_groups : v.arn]
}
