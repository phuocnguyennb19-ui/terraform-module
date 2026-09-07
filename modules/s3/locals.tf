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

  # 4. Smart Defaults for s3
  raw_s3_cfg = try(local.config_local.s3, {})
  s3_defaults = {
    bucket              = "${local.name_prefix}-bucket"
    versioning_enabled  = lookup(local.raw_s3_cfg, "versioning_enabled", true)
    kms_key_id          = lookup(local.raw_s3_cfg, "kms_key_id", null)
    block_public_acls   = lookup(local.raw_s3_cfg, "block_public_acls", true)
    block_public_policy = lookup(local.raw_s3_cfg, "block_public_policy", true)
    force_destroy       = lookup(local.raw_s3_cfg, "force_destroy", false)

    lifecycle_rule              = lookup(local.raw_s3_cfg, "lifecycle_rule", [])
    cors_rule                   = lookup(local.raw_s3_cfg, "cors_rule", [])
    logging                     = lookup(local.raw_s3_cfg, "logging", {})
    acceleration_status         = lookup(local.raw_s3_cfg, "acceleration_status", null)
    website                     = lookup(local.raw_s3_cfg, "website", {})
    object_lock_enabled         = lookup(local.raw_s3_cfg, "object_lock_enabled", false)
    object_lock_configuration   = lookup(local.raw_s3_cfg, "object_lock_configuration", {})
    intelligent_tiering         = lookup(local.raw_s3_cfg, "intelligent_tiering", {})
    metric_configuration        = lookup(local.raw_s3_cfg, "metric_configuration", [])
    replication_configuration   = lookup(local.raw_s3_cfg, "replication_configuration", {})
    notification_configurations = lookup(local.raw_s3_cfg, "notification_configurations", {})

    # full upstream surface
    # Remaining upstream arguments with a simple literal default, mapped with
    # that same default as the fallback: omitting a key behaves as before.
    access_log_delivery_policy_source_accounts = try(local.raw_s3_cfg.access_log_delivery_policy_source_accounts, [])
    access_log_delivery_policy_source_buckets  = try(local.raw_s3_cfg.access_log_delivery_policy_source_buckets, [])
    allowed_kms_key_arn                        = try(local.raw_s3_cfg.allowed_kms_key_arn, null)
    analytics_configuration                    = try(local.raw_s3_cfg.analytics_configuration, {})
    analytics_self_source_destination          = try(local.raw_s3_cfg.analytics_self_source_destination, false)
    analytics_source_account_id                = try(local.raw_s3_cfg.analytics_source_account_id, null)
    analytics_source_bucket_arn                = try(local.raw_s3_cfg.analytics_source_bucket_arn, null)
    attach_access_log_delivery_policy          = try(local.raw_s3_cfg.attach_access_log_delivery_policy, false)
    attach_analytics_destination_policy        = try(local.raw_s3_cfg.attach_analytics_destination_policy, false)
    attach_deny_incorrect_encryption_headers   = try(local.raw_s3_cfg.attach_deny_incorrect_encryption_headers, false)
    attach_deny_incorrect_kms_key_sse          = try(local.raw_s3_cfg.attach_deny_incorrect_kms_key_sse, false)
    attach_deny_insecure_transport_policy      = try(local.raw_s3_cfg.attach_deny_insecure_transport_policy, false)
    attach_deny_unencrypted_object_uploads     = try(local.raw_s3_cfg.attach_deny_unencrypted_object_uploads, false)
    attach_elb_log_delivery_policy             = try(local.raw_s3_cfg.attach_elb_log_delivery_policy, false)
    attach_inventory_destination_policy        = try(local.raw_s3_cfg.attach_inventory_destination_policy, false)
    attach_lb_log_delivery_policy              = try(local.raw_s3_cfg.attach_lb_log_delivery_policy, false)
    attach_policy                              = try(local.raw_s3_cfg.attach_policy, false)
    attach_public_policy                       = try(local.raw_s3_cfg.attach_public_policy, true)
    attach_require_latest_tls_policy           = try(local.raw_s3_cfg.attach_require_latest_tls_policy, false)
    bucket_prefix                              = try(local.raw_s3_cfg.bucket_prefix, null)
    create_bucket                              = try(local.raw_s3_cfg.create_bucket, true)
    expected_bucket_owner                      = try(local.raw_s3_cfg.expected_bucket_owner, null)
    grant                                      = try(local.raw_s3_cfg.grant, [])
    inventory_configuration                    = try(local.raw_s3_cfg.inventory_configuration, {})
    inventory_self_source_destination          = try(local.raw_s3_cfg.inventory_self_source_destination, false)
    inventory_source_account_id                = try(local.raw_s3_cfg.inventory_source_account_id, null)
    inventory_source_bucket_arn                = try(local.raw_s3_cfg.inventory_source_bucket_arn, null)
    owner                                      = try(local.raw_s3_cfg.owner, {})
    policy                                     = try(local.raw_s3_cfg.policy, null)
    putin_khuylo                               = try(local.raw_s3_cfg.putin_khuylo, true)
    request_payer                              = try(local.raw_s3_cfg.request_payer, null)
    transition_default_minimum_object_size     = try(local.raw_s3_cfg.transition_default_minimum_object_size, null)
  }
  s3_config = merge(local.s3_defaults, try(local.config_local.s3, {}))

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
