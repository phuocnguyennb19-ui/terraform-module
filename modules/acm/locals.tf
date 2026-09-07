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
    domain_name                                 = lookup(local.raw_acm_cfg, "domain_name", null)
    subject_alternative_names                   = lookup(local.raw_acm_cfg, "subject_alternative_names", [])
    validation_method                           = lookup(local.raw_acm_cfg, "validation_method", "DNS")
    wait_for_validation                         = lookup(local.raw_acm_cfg, "wait_for_validation", true)
    key_algorithm                               = lookup(local.raw_acm_cfg, "key_algorithm", "RSA_2048")
    certificate_transparency_logging_preference = lookup(local.raw_acm_cfg, "certificate_transparency_logging_preference", "ENABLED")

    # full upstream surface
    # Remaining upstream arguments with a simple literal default, mapped with
    # that same default as the fallback: omitting a key behaves as before.
    acm_certificate_domain_validation_options = try(local.raw_acm_cfg.acm_certificate_domain_validation_options, {})
    create_certificate                        = try(local.raw_acm_cfg.create_certificate, true)
    create_route53_records                    = try(local.raw_acm_cfg.create_route53_records, true)
    create_route53_records_only               = try(local.raw_acm_cfg.create_route53_records_only, false)
    distinct_domain_names                     = try(local.raw_acm_cfg.distinct_domain_names, [])
    dns_ttl                                   = try(local.raw_acm_cfg.dns_ttl, 60)
    putin_khuylo                              = try(local.raw_acm_cfg.putin_khuylo, true)
    validate_certificate                      = try(local.raw_acm_cfg.validate_certificate, true)
    validation_allow_overwrite_records        = try(local.raw_acm_cfg.validation_allow_overwrite_records, true)
    validation_option                         = try(local.raw_acm_cfg.validation_option, {})
    validation_record_fqdns                   = try(local.raw_acm_cfg.validation_record_fqdns, [])
    validation_timeout                        = try(local.raw_acm_cfg.validation_timeout, null)
    zone_id                                   = try(local.raw_acm_cfg.zone_id, "")
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
