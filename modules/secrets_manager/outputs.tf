output "secret_arns" {
  description = "Map of secret keys to their ARNs"
  value       = { for k, v in module.secrets_manager : k => v.secret_arn }
}

output "secret_ids" {
  description = "Map of secret keys to their IDs"
  value       = { for k, v in module.secrets_manager : k => v.secret_id }
}

output "secret_names" {
  description = "Map of secret keys to their names"
  # Taken from the config, not from the child module: upstream
  # terraform-aws-secrets-manager v1.1.0 exposes secret_arn, secret_id,
  # secret_replica and secret_version_id — there is no secret_name. Reading one
  # made every apply of this module fail, and `validate` never caught it because
  # it does not evaluate a child module's outputs.
  value = { for k, v in local.secrets : k => v.name }
}

output "secret_version_ids" {
  description = "Map of secret keys to their current version IDs"
  value       = { for k, v in module.secrets_manager : k => try(v.secret_version_id, null) }
}
