locals {
  config_local = merge(
    try(yamldecode(file("${path.cwd}/${var.config_file}")), {}),
    var.manual_config
  )

  env          = lookup(var.global_config, "environment", "dev")
  region       = lookup(var.global_config, "region", "ap-southeast-1")
  project      = lookup(var.global_config, "project", "core")
  app_name     = lookup(local.config_local, "app_name", null)
  service_type = lookup(local.config_local, "service_type", "infra")
  name_prefix  = join("-", compact([local.env, local.app_name == "base" ? null : local.app_name, local.service_type]))

  raw_waf_cfg = try(local.config_local.waf, {})
  waf_defaults = {
    name                  = "${local.name_prefix}-waf"
    description           = lookup(local.raw_waf_cfg, "description", "WAF managed by Terraform for ${local.name_prefix}")
    scope                 = lookup(local.raw_waf_cfg, "scope", "REGIONAL")
    default_action        = lookup(local.raw_waf_cfg, "default_action", "allow")
    rules                 = lookup(local.raw_waf_cfg, "rules", [])
    associate_alb_arns    = lookup(local.raw_waf_cfg, "associate_alb_arns", [])
    logging_configuration = lookup(local.raw_waf_cfg, "logging_configuration", {})
    token_domains         = lookup(local.raw_waf_cfg, "token_domains", [])
  }
  waf_config = merge(local.waf_defaults, try(local.config_local.waf, {}))

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
