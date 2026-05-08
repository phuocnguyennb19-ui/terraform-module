module "zones" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/zones?ref=v4.1.0"

  zones = local.dns_config.zones

  tags = local.tags
}

module "records" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/records?ref=v4.1.0"

  for_each = local.dns_config.record_zones

  zone_name = each.key
  records   = each.value

  depends_on = [module.zones]
}
