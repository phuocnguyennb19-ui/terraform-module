module "acm" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-acm.git?ref=v4.3.2"

  domain_name               = local.acm_config.domain_name
  subject_alternative_names = local.acm_config.subject_alternative_names
  validation_method         = local.acm_config.validation_method
  wait_for_validation       = local.acm_config.wait_for_validation
  key_algorithm             = local.acm_config.key_algorithm

  certificate_transparency_logging_preference = local.acm_config.certificate_transparency_logging_preference

  tags = local.tags

  # full upstream surface
  acm_certificate_domain_validation_options = local.acm_config.acm_certificate_domain_validation_options
  create_certificate                        = local.acm_config.create_certificate
  create_route53_records                    = local.acm_config.create_route53_records
  create_route53_records_only               = local.acm_config.create_route53_records_only
  distinct_domain_names                     = local.acm_config.distinct_domain_names
  dns_ttl                                   = local.acm_config.dns_ttl
  putin_khuylo                              = local.acm_config.putin_khuylo
  validate_certificate                      = local.acm_config.validate_certificate
  validation_allow_overwrite_records        = local.acm_config.validation_allow_overwrite_records
  validation_option                         = local.acm_config.validation_option
  validation_record_fqdns                   = local.acm_config.validation_record_fqdns
  validation_timeout                        = local.acm_config.validation_timeout
  zone_id                                   = local.acm_config.zone_id
}
