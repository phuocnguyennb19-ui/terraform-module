output "alb_dns_name" {
  description = "Public DNS name of the load balancer."
  value       = module.alb.lb_dns_name
}

output "ecs_service_name" {
  description = "Name of the ECS service."
  value       = module.ecs_service.name
}
