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

  # 4. ECR Config (Full-Spec)
  raw_ecr_cfg = try(local.config_local.ecr, {})
  ecr_defaults = {
    repository_names        = lookup(local.raw_ecr_cfg, "repository_names", ["${local.name_prefix}-app"])
    image_tag_mutability    = lookup(local.raw_ecr_cfg, "image_tag_mutability", local.env == "prod" ? "IMMUTABLE" : "MUTABLE")
    scan_on_push            = lookup(local.raw_ecr_cfg, "scan_on_push", true)
    repository_force_delete = lookup(local.raw_ecr_cfg, "repository_force_delete", false)
    encryption_type         = lookup(local.raw_ecr_cfg, "encryption_type", "AES256")
    kms_key                 = lookup(local.raw_ecr_cfg, "kms_key", null)
    read_access_arns        = lookup(local.raw_ecr_cfg, "read_access_arns", [])
    read_write_access_arns  = lookup(local.raw_ecr_cfg, "read_write_access_arns", [])
    lifecycle_policy        = lookup(local.raw_ecr_cfg, "lifecycle_policy", null)
  }
  ecr_config = merge(local.ecr_defaults, try(local.config_local.ecr, {}))

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
