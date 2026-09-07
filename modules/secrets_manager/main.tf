# Upstream v1.1.0 ALWAYS creates a version resource — aws_secretsmanager_secret_version.this
# when nothing is ignored, .ignore_changes when ignore_secret_changes or
# enable_rotation is set. There is no path to a secret with no version. Passing
# neither secret_string nor create_random_password therefore failed every apply
# with the opaque:
#
#   InvalidRequestException: You must provide either SecretString or SecretBinary
#
# Both are now forwarded, and locals.tf refuses a secret that sets neither.
module "secrets_manager" {
  for_each = local.secrets
  source   = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git?ref=v1.1.0"

  name        = each.value.name
  description = each.value.description

  recovery_window_in_days = each.value.recovery_window_in_days
  kms_key_id              = each.value.kms_key_id
  ignore_secret_changes   = each.value.ignore_secret_changes

  # The initial value. `create_random_password` seeds one Terraform never has to
  # be told, which is the right choice when the real value is written out of band
  # afterwards — pair it with ignore_secret_changes so the replacement is not
  # reverted on the next apply.
  secret_string          = each.value.secret_string
  create_random_password = each.value.create_random_password
  random_password_length = each.value.random_password_length

  # Rotation was inert before: upstream gates it on enable_rotation, which was
  # never passed, so a rotation_lambda_arn in config did nothing.
  enable_rotation     = each.value.enable_rotation
  rotation_lambda_arn = each.value.rotation_lambda_arn
  rotation_rules      = each.value.rotation_rules

  tags = local.tags
}
