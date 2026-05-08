output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = module.acm.acm_certificate_arn
}

output "acm_certificate_domain_validation_options" {
  description = "Domain validation options (CNAME records to create)"
  value       = module.acm.acm_certificate_domain_validation_options
}

output "acm_certificate_status" {
  description = "Status of the certificate (PENDING_VALIDATION, ISSUED, etc.)"
  value       = module.acm.acm_certificate_status
}

output "acm_certificate_domain" {
  description = "Primary domain name of the certificate"
  value       = local.acm_config.domain_name
}
