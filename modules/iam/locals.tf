locals {

  # 2. Local Module Config (Support dynamic config file name)
  config_local = merge(
    try(yamldecode(file("${path.cwd}/${var.config_file}")), {}),
    var.manual_config
  )

  # 3. Context & Naming (Strict mapping from config.yml)
  env          = lookup(var.global_config, "environment", "dev")
  region       = lookup(var.global_config, "region", "ap-southeast-1")
  project      = lookup(var.global_config, "project", "core")
  app_name     = lookup(local.config_local, "app_name", null)
  service_type = lookup(local.config_local, "service_type", "infra")
  name_prefix  = join("-", compact([local.env, local.app_name == "base" ? null : local.app_name, local.service_type]))

  # 4. IAM Factory Mapping (Key:Value Sync)
  iam_raw = try(local.config_local.iam, {})

  # 4.1 Policies Factory
  policies = try(local.iam_raw.policies, {})

  # 4.2 Roles Factory
  roles = try(local.iam_raw.roles, {})

  # 4.3 Groups Factory
  groups = try(local.iam_raw.groups, {})

  # 4.4 Users Factory
  users = try(local.iam_raw.users, {})

  # Fallback for simple single-role config (backward compatibility)
  iam_config = {
    role_name               = lookup(local.iam_raw, "role_name", "${local.name_prefix}-role")
    trusted_role_services   = lookup(local.iam_raw, "trusted_role_services", ["ecs-tasks.amazonaws.com"])
    role_requires_mfa       = lookup(local.iam_raw, "role_requires_mfa", false)
    custom_role_policy_arns = lookup(local.iam_raw, "custom_role_policy_arns", [])
    assume_role_policy      = lookup(local.iam_raw, "assume_role_policy", null)
  }

  # 5. Global Alias & Tags
  config = local.config_local
  tags = merge(
    {
      Environment = local.env,
      Project     = local.project,
      ManagedBy   = lookup(var.global_config, "managed_by", "DylanDevOps"),
      CostCenter  = lookup(var.global_config, "cost_center", "shared-services"),
      Terraform   = "true"
    },
    var.tags, try(var.global_config.tags, {})
  )
}
