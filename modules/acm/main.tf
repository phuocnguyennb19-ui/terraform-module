module "acm" {
  source  = "git::https://github.com/terraform-aws-modules/terraform-aws-acm.git?ref=v4.3.2"

  domain_name               = local.acm_config.domain_name
  subject_alternative_names = try(local.acm_config.subject_alternative_names, [])
  validation_method         = try(local.acm_config.validation_method, "DNS")
  wait_for_validation       = try(local.acm_config.wait_for_validation, true)

  tags = local.tags
}
