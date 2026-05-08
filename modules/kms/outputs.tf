output "key_arn" {
  description = "ARN of the KMS key"
  value       = module.kms.key_arn
}

output "key_id" {
  description = "ID of the KMS key"
  value       = module.kms.key_id
}

output "key_alias_arn" {
  description = "ARN of the primary KMS key alias"
  value       = try(module.kms.aliases[local.kms_config.aliases[0]].arn, null)
}

output "key_alias_name" {
  description = "Name of the primary KMS key alias"
  value       = try(local.kms_config.aliases[0], null)
}

output "all_aliases" {
  description = "Map of all KMS key aliases"
  value       = try(module.kms.aliases, {})
}
