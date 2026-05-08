output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "task_exec_iam_role_arn" {
  description = "ARN of the default task execution IAM role"
  value       = try(module.ecs.task_exec_iam_role_arn, null)
}

output "task_exec_iam_role_name" {
  description = "Name of the default task execution IAM role"
  value       = try(module.ecs.task_exec_iam_role_name, null)
}
