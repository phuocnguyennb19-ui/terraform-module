include "root" { path = find_in_parent_folders() }

terraform { source = "../../../modules//aws-s3-cdn" }

# Nếu dùng custom domain → thêm dependency "acm" (cert phải ở us-east-1)
# dependency "acm" { config_path = "../acm" }

locals {
  all = yamldecode(file("${get_terragrunt_dir()}/../values.base.yml"))
  cfg = local.all["s3-cdn"]
}

inputs = {
  name        = local.cfg.name
  environment = local.cfg.environment

  versioning_enabled  = local.cfg.versioning_enabled
  force_destroy       = local.cfg.force_destroy
  create_cloudfront   = local.cfg.create_cloudfront
  price_class         = local.cfg.price_class
  default_root_object = local.cfg.default_root_object
  aliases             = try(local.cfg.aliases, [])
  acm_certificate_arn = try(local.cfg.acm_certificate_arn, null)

  custom_error_responses = local.cfg.custom_error_responses
  cache_ttl              = local.cfg.cache_ttl

  tags = local.cfg.tags
}
