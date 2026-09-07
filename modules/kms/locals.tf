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

  # 4. Smart Defaults for kms
  raw_kms_cfg = try(local.config_local.kms, {})
  kms_defaults = {
    aliases                  = lookup(local.raw_kms_cfg, "aliases", ["alias/${local.name_prefix}-key"])
    description              = lookup(local.raw_kms_cfg, "description", "Master key for ${local.name_prefix}")
    deletion_window_in_days  = lookup(local.raw_kms_cfg, "deletion_window_in_days", 30)
    key_users                = lookup(local.raw_kms_cfg, "key_users", [])
    key_administrators       = lookup(local.raw_kms_cfg, "key_administrators", [])
    key_usage                = lookup(local.raw_kms_cfg, "key_usage", "ENCRYPT_DECRYPT")
    customer_master_key_spec = lookup(local.raw_kms_cfg, "customer_master_key_spec", "SYMMETRIC_DEFAULT")
    multi_region             = lookup(local.raw_kms_cfg, "multi_region", false)
    rotation_period_in_days  = lookup(local.raw_kms_cfg, "rotation_period_in_days", 365)
    policy                   = lookup(local.raw_kms_cfg, "policy", null)

    # full upstream surface
    # Remaining upstream arguments with a simple literal default, mapped with
    # that same default as the fallback: omitting a key behaves as before.
    aliases_use_name_prefix                = try(local.raw_kms_cfg.aliases_use_name_prefix, false)
    bypass_policy_lockout_safety_check     = try(local.raw_kms_cfg.bypass_policy_lockout_safety_check, null)
    computed_aliases                       = try(local.raw_kms_cfg.computed_aliases, {})
    create                                 = try(local.raw_kms_cfg.create, true)
    create_external                        = try(local.raw_kms_cfg.create_external, false)
    create_replica                         = try(local.raw_kms_cfg.create_replica, false)
    create_replica_external                = try(local.raw_kms_cfg.create_replica_external, false)
    custom_key_store_id                    = try(local.raw_kms_cfg.custom_key_store_id, null)
    enable_default_policy                  = try(local.raw_kms_cfg.enable_default_policy, true)
    enable_route53_dnssec                  = try(local.raw_kms_cfg.enable_route53_dnssec, false)
    grants                                 = try(local.raw_kms_cfg.grants, {})
    is_enabled                             = try(local.raw_kms_cfg.is_enabled, null)
    key_asymmetric_public_encryption_users = try(local.raw_kms_cfg.key_asymmetric_public_encryption_users, [])
    key_asymmetric_sign_verify_users       = try(local.raw_kms_cfg.key_asymmetric_sign_verify_users, [])
    key_hmac_users                         = try(local.raw_kms_cfg.key_hmac_users, [])
    key_material_base64                    = try(local.raw_kms_cfg.key_material_base64, null)
    key_owners                             = try(local.raw_kms_cfg.key_owners, [])
    key_service_roles_for_autoscaling      = try(local.raw_kms_cfg.key_service_roles_for_autoscaling, [])
    key_service_users                      = try(local.raw_kms_cfg.key_service_users, [])
    key_statements                         = try(local.raw_kms_cfg.key_statements, {})
    key_symmetric_encryption_users         = try(local.raw_kms_cfg.key_symmetric_encryption_users, [])
    override_policy_documents              = try(local.raw_kms_cfg.override_policy_documents, [])
    primary_external_key_arn               = try(local.raw_kms_cfg.primary_external_key_arn, null)
    primary_key_arn                        = try(local.raw_kms_cfg.primary_key_arn, null)
    route53_dnssec_sources                 = try(local.raw_kms_cfg.route53_dnssec_sources, [])
    source_policy_documents                = try(local.raw_kms_cfg.source_policy_documents, [])
    valid_to                               = try(local.raw_kms_cfg.valid_to, null)
  }
  kms_config = merge(local.kms_defaults, try(local.config_local.kms, {}))

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
