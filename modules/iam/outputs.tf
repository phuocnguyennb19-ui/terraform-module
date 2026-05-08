# Single-role mode (backward compat — when no roles map defined in config)
output "iam_role_arn" {
  description = "ARN of the primary IAM role (single-role mode)"
  value = try(
    module.iam_assumable_role_default[0].iam_role_arn,
    module.iam_assumable_role_factory[keys(module.iam_assumable_role_factory)[0]].iam_role_arn,
    null
  )
}

output "iam_role_name" {
  description = "Name of the primary IAM role (single-role mode)"
  value = try(
    module.iam_assumable_role_default[0].iam_role_name,
    module.iam_assumable_role_factory[keys(module.iam_assumable_role_factory)[0]].iam_role_name,
    null
  )
}

# Multi-role factory outputs
output "all_role_arns" {
  description = "Map of all role names to ARNs created by the factory (key = role name)"
  value       = { for k, v in module.iam_assumable_role_factory : k => v.iam_role_arn }
}

output "all_role_names" {
  description = "Map of all role names created by the factory"
  value       = { for k, v in module.iam_assumable_role_factory : k => v.iam_role_name }
}

output "policy_arns" {
  description = "Map of custom policy names to ARNs"
  value       = { for k, v in aws_iam_policy.custom : k => v.arn }
}

output "instance_profile_arns" {
  description = "Map of IAM instance profile ARNs (for EC2 roles)"
  value       = { for k, v in aws_iam_instance_profile.this : k => v.arn }
}

output "instance_profile_names" {
  description = "Map of IAM instance profile names"
  value       = { for k, v in aws_iam_instance_profile.this : k => v.name }
}
