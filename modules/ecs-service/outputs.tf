output "id" {
  description = "The ID of the service"
  value       = module.service.id
}

output "name" {
  description = "The name of the service"
  value       = module.service.name
}

output "task_definition_arn" {
  description = "The ARN of the task definition"
  value       = module.service.task_definition_arn
}

output "iam_role_name" {
  description = "The name of the IAM role"
  value       = module.service.iam_role_name
}

output "iam_role_arn" {
  description = "The ARN of the IAM role"
  value       = module.service.iam_role_arn
}
