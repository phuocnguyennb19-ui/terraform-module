output "lb_id"      { value = module.alb.lb_id }
output "lb_arn"     { value = module.alb.lb_arn }
output "lb_dns_name" { value = module.alb.lb_dns_name }
output "lb_zone_id" { value = module.alb.lb_zone_id }

# Fix 2: Export http_tcp_listener_arns — cần thiết để ecs-service auto-attach
output "http_tcp_listener_arns" {
  description = "HTTP Listener ARNs for ECS Service rule attachment"
  value       = module.alb.http_tcp_listener_arns
}

output "target_group_arns" {
  description = "Target Group ARNs"
  value       = module.alb.target_group_arns
}

output "target_groups" {
  description = "Map of target groups by name"
  value = {
    for i, name in module.alb.target_group_names :
    name => {
      arn = module.alb.target_group_arns[i]
    }
  }
}
