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

  # 4. Route53 Config (Full-Spec)
  raw_dns_cfg      = try(local.config_local.dns, try(local.config_local.route53, {}))
  raw_record_zones = lookup(local.raw_dns_cfg, "records", {})

  # Alias targets the caller wired in. CloudFront always sits in this fixed zone.
  alias_targets = {
    alb        = { name = var.alb_dns_name, zone_id = var.alb_zone_id }
    cloudfront = { name = var.cloudfront_domain_name, zone_id = "Z2FDTNDATAQYW2" }
  }

  # A record may declare either a literal alias {name, zone_id} — passed through
  # untouched — or alias.target = "<key>", resolved from alias_targets above.
  record_zones = {
    for zone, recs in local.raw_record_zones : zone => [
      for r in recs :
      try(r.alias.target, null) != null
      ? merge(r, {
        alias = merge(
          { evaluate_target_health = try(r.alias.evaluate_target_health, true) },
          local.alias_targets[r.alias.target],
        )
      })
      : r
    ]
  }

  dns_defaults = {
    zones        = lookup(local.raw_dns_cfg, "zones", {})
    record_zones = local.record_zones
  }
  dns_config = merge(local.dns_defaults, local.raw_dns_cfg, { record_zones = local.record_zones })

  # 6. Global Alias & Tags
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
