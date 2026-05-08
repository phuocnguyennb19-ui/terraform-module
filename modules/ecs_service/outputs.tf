output "id" {
  description = "The ID of the service"
  value       = module.ecs_service.id
}

output "name" {
  description = "The name of the service"
  value       = module.ecs_service.name
}

output "task_definition_arn" {
  description = "The ARN of the task definition"
  value       = module.ecs_service.task_definition_arn
}

output "iam_role_name" {
  description = "The name of the IAM service-linked role"
  value       = module.ecs_service.iam_role_name
}

output "iam_role_arn" {
  description = "The ARN of the IAM service-linked role"
  value       = module.ecs_service.iam_role_arn
}

output "target_group_arn" {
  description = "The ARN of the ALB target group (null when no LB configured)"
  value       = length(aws_lb_target_group.app) > 0 ? aws_lb_target_group.app[0].arn : null
}

output "target_group_name" {
  description = "The name of the ALB target group (null when no LB configured)"
  value       = length(aws_lb_target_group.app) > 0 ? aws_lb_target_group.app[0].name : null
}

output "security_group_id" {
  description = "The ID of the ECS service security group (null when external SG IDs supplied)"
  value       = try(module.ecs_service.security_group_id, null)
}

output "security_group_arn" {
  description = "The ARN of the ECS service security group (null when external SG IDs supplied)"
  value       = try(module.ecs_service.security_group_arn, null)
}

output "task_exec_iam_role_arn" {
  description = "ARN of the task execution IAM role"
  value       = try(module.ecs_service.task_exec_iam_role_arn, null)
}

output "task_iam_role_arn" {
  description = "ARN of the task IAM role"
  value       = try(module.ecs_service.tasks_iam_role_arn, null)
}
