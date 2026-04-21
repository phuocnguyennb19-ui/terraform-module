output "secret_arns" { value = { for k, v in module.secrets_manager : k => v.secret_arn } }
