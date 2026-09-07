module "s3_bucket" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v4.2.1"

  force_destroy = local.s3_config.force_destroy

  bucket = local.s3_config.bucket
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  block_public_acls       = local.s3_config.block_public_acls
  block_public_policy     = local.s3_config.block_public_policy
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = local.s3_config.versioning_enabled
  }

  server_side_encryption_configuration = local.s3_config.kms_key_id != null ? {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = local.s3_config.kms_key_id
        sse_algorithm     = "aws:kms"
      }
    }
    } : {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule      = local.s3_config.lifecycle_rule
  cors_rule           = local.s3_config.cors_rule
  logging             = local.s3_config.logging
  acceleration_status = local.s3_config.acceleration_status
  website             = local.s3_config.website

  object_lock_enabled       = local.s3_config.object_lock_enabled
  object_lock_configuration = local.s3_config.object_lock_configuration

  intelligent_tiering       = local.s3_config.intelligent_tiering
  metric_configuration      = local.s3_config.metric_configuration
  replication_configuration = local.s3_config.replication_configuration
  # notification_configurations is NOT an argument of terraform-aws-s3-bucket v4.2.1
  # (bucket notifications live in that repo's //modules/notification submodule).
  # Passing it made this module fail `terraform validate` outright. The local is kept
  # so the key can be re-wired if the module is ever pointed at the submodule.

  tags = local.tags

  # full upstream surface
  access_log_delivery_policy_source_accounts = local.s3_config.access_log_delivery_policy_source_accounts
  access_log_delivery_policy_source_buckets  = local.s3_config.access_log_delivery_policy_source_buckets
  allowed_kms_key_arn                        = local.s3_config.allowed_kms_key_arn
  analytics_configuration                    = local.s3_config.analytics_configuration
  analytics_self_source_destination          = local.s3_config.analytics_self_source_destination
  analytics_source_account_id                = local.s3_config.analytics_source_account_id
  analytics_source_bucket_arn                = local.s3_config.analytics_source_bucket_arn
  attach_access_log_delivery_policy          = local.s3_config.attach_access_log_delivery_policy
  attach_analytics_destination_policy        = local.s3_config.attach_analytics_destination_policy
  attach_deny_incorrect_encryption_headers   = local.s3_config.attach_deny_incorrect_encryption_headers
  attach_deny_incorrect_kms_key_sse          = local.s3_config.attach_deny_incorrect_kms_key_sse
  attach_deny_insecure_transport_policy      = local.s3_config.attach_deny_insecure_transport_policy
  attach_deny_unencrypted_object_uploads     = local.s3_config.attach_deny_unencrypted_object_uploads
  attach_elb_log_delivery_policy             = local.s3_config.attach_elb_log_delivery_policy
  attach_inventory_destination_policy        = local.s3_config.attach_inventory_destination_policy
  attach_lb_log_delivery_policy              = local.s3_config.attach_lb_log_delivery_policy
  attach_policy                              = local.s3_config.attach_policy
  attach_public_policy                       = local.s3_config.attach_public_policy
  attach_require_latest_tls_policy           = local.s3_config.attach_require_latest_tls_policy
  bucket_prefix                              = local.s3_config.bucket_prefix
  create_bucket                              = local.s3_config.create_bucket
  expected_bucket_owner                      = local.s3_config.expected_bucket_owner
  grant                                      = local.s3_config.grant
  inventory_configuration                    = local.s3_config.inventory_configuration
  inventory_self_source_destination          = local.s3_config.inventory_self_source_destination
  inventory_source_account_id                = local.s3_config.inventory_source_account_id
  inventory_source_bucket_arn                = local.s3_config.inventory_source_bucket_arn
  owner                                      = local.s3_config.owner
  policy                                     = local.s3_config.policy
  putin_khuylo                               = local.s3_config.putin_khuylo
  request_payer                              = local.s3_config.request_payer
  transition_default_minimum_object_size     = local.s3_config.transition_default_minimum_object_size
}
