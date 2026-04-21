module "zones" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/zones?ref=v2.11.0"

  zones = try(local.route53_config.zones, {})

  tags = local.tags
}
