# Fix 4b: WAF — Bỏ for_each, dùng single waf_config object
# Đọc cấu hình từ waf_config thay vì waf_acls map
module "wafv2" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-wafv2.git?ref=v1.1.0"

  name        = try(local.waf_config.name, "${local.name_prefix}-waf")
  description = try(local.waf_config.description, "WAF ACL for ${local.name_prefix}")
  scope       = try(local.waf_config.scope, "REGIONAL")

  default_action = try(local.waf_config.default_action, "allow")

  rules = try(local.waf_config.rules, [])

  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = try(local.waf_config.name, "${local.name_prefix}-waf")
    sampled_requests_enabled   = true
  }

  tags = local.tags
}
