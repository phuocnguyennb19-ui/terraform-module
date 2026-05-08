module "acm" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-acm.git?ref=v4.3.2"

  domain_name               = local.acm_config.domain_name
  subject_alternative_names = local.acm_config.subject_alternative_names
  validation_method         = local.acm_config.validation_method
  wait_for_validation       = local.acm_config.wait_for_validation
  key_algorithm             = local.acm_config.key_algorithm

  certificate_transparency_logging_preference = local.acm_config.certificate_transparency_logging_preference

  tags = local.tags
}
