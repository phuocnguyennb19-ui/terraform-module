output "repository_urls" {
  description = "Map of repository names to their registry URLs"
  value       = { for k, v in module.ecr : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of repository names to their ARNs"
  value       = { for k, v in module.ecr : k => v.repository_arn }
}

output "repository_registry_ids" {
  description = "Map of repository names to their registry IDs"
  value       = { for k, v in module.ecr : k => v.repository_registry_id }
}
