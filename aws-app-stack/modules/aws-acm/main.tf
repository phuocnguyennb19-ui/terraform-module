module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names

  # Tự động tạo DNS validation record trong Route53
  zone_id             = var.zone_id
  validation_method   = "DNS"
  wait_for_validation = var.wait_for_validation

  tags = var.tags
}
