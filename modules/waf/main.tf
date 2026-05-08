module "wafv2" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-wafv2.git?ref=v1.1.0"

  name        = local.waf_config.name
  description = local.waf_config.description
  scope       = local.waf_config.scope

  default_action = local.waf_config.default_action

  rules         = local.waf_config.rules
  token_domains = local.waf_config.token_domains

  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = local.waf_config.name
    sampled_requests_enabled   = true
  }

  logging_configuration = local.waf_config.logging_configuration

  tags = local.tags
}

# Associate WAF with ALB(s) if ARNs provided
resource "aws_wafv2_web_acl_association" "this" {
  for_each = toset(local.waf_config.associate_alb_arns)

  resource_arn = each.value
  web_acl_arn  = module.wafv2.web_acl_arn
}
