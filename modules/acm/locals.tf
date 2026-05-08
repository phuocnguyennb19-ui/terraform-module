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

  # 4. Smart Defaults for acm
  raw_acm_cfg = try(local.config_local.acm, {})
  acm_defaults = {
    domain_name               = lookup(local.raw_acm_cfg, "domain_name", null)
    subject_alternative_names = lookup(local.raw_acm_cfg, "subject_alternative_names", [])
    validation_method         = lookup(local.raw_acm_cfg, "validation_method", "DNS")
    wait_for_validation       = lookup(local.raw_acm_cfg, "wait_for_validation", true)
    key_algorithm             = lookup(local.raw_acm_cfg, "key_algorithm", "RSA_2048")
    certificate_transparency_logging_preference = lookup(local.raw_acm_cfg, "certificate_transparency_logging_preference", "ENABLED")
  }
  acm_config = merge(local.acm_defaults, try(local.config_local.acm, {}))

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
