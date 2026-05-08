# 1. Custom Policies Factory
resource "aws_iam_policy" "custom" {
  for_each = local.policies

  name        = each.key
  path        = lookup(each.value, "path", "/")
  description = lookup(each.value, "description", "Custom policy created by Terraform")
  policy      = each.value.policy

  tags = local.tags
}

# 2. Multi-Role Factory (Main Role Set)
module "iam_assumable_role_factory" {
  for_each = local.roles
  source   = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.44.0"

  create_role           = true
  role_name             = each.key
  role_requires_mfa     = lookup(each.value, "role_requires_mfa", false)
  trusted_role_services = lookup(each.value, "trusted_role_services", ["ecs-tasks.amazonaws.com"])

  # Merge global ARNs with generated ARNs from this module
  custom_role_policy_arns = concat(
    lookup(each.value, "custom_role_policy_arns", []),
    [for p in lookup(each.value, "custom_policy_names", []) : aws_iam_policy.custom[p].arn]
  )

  # Custom trust policy (if provided)
  create_custom_role_trust_policy = lookup(each.value, "assume_role_policy", null) != null ? true : false
  custom_role_trust_policy        = lookup(each.value, "assume_role_policy", null)

  tags = local.tags
}

# 2b. Instance Profile Factory (optional — for EC2 roles)
resource "aws_iam_instance_profile" "this" {
  for_each = { for k, v in local.roles : k => v if lookup(v, "create_instance_profile", false) }

  name = each.key
  role = module.iam_assumable_role_factory[each.key].iam_role_name

  tags = local.tags
}

# 3. Legacy/Default Role Support (Backward compatible with single role config)
module "iam_assumable_role_default" {
  count  = length(keys(local.roles)) == 0 ? 1 : 0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.44.0"

  create_role             = true
  role_name               = local.iam_config.role_name
  role_requires_mfa       = local.iam_config.role_requires_mfa
  trusted_role_services   = local.iam_config.trusted_role_services
  custom_role_policy_arns = local.iam_config.custom_role_policy_arns

  # Custom trust policy (if provided)
  create_custom_role_trust_policy = local.iam_config.assume_role_policy != null ? true : false
  custom_role_trust_policy        = local.iam_config.assume_role_policy

  tags = local.tags
}
