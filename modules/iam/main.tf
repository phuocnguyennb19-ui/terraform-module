module "iam_assumable_role" {
  source  = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.44.0"

  trusted_role_services   = try(local.iam_config.trusted_role_services, [])
  create_role             = true
  role_name               = local.iam_config.role_name
  role_requires_mfa       = try(local.iam_config.role_requires_mfa, false)
  custom_role_policy_arns = try(local.iam_config.custom_role_policy_arns, [])

  tags = local.tags
}
