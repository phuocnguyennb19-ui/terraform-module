output "alb_dns_name"      { value = module.alb.dns_name }
output "alb_zone_id"       { value = module.alb.zone_id }
output "alb_arn"           { value = module.alb.arn }
output "security_group_id" { value = module.alb.security_group_id }
output "internal"          { value = var.internal }

# Map tên target group → ARN (dùng cho ECS service từng app)
output "target_group_arns" {
  value = { for k, v in module.alb.target_groups : k => v.arn }
}

# Backward compat — trả về ARN của default target group
output "target_group_arn" {
  value = module.alb.target_groups[local.default_tg_key].arn
}
