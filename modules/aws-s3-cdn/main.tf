locals {
  bucket_name = coalesce(var.bucket_name, "${var.name}-${var.environment}-static")
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  versioning = { enabled = var.versioning_enabled }

  # Block tất cả public access — CloudFront dùng OAC để access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = var.tags
}

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 3.0"

  count = var.create_cloudfront ? 1 : 0

  comment             = "${var.name}-${var.environment} CDN"
  enabled             = true
  price_class         = var.price_class
  default_root_object = var.default_root_object
  aliases             = var.aliases

  # Origin: S3 với OAC (Origin Access Control)
  origin = {
    s3 = {
      domain_name           = module.s3_bucket.s3_bucket_bucket_regional_domain_name
      origin_id             = "s3-${local.bucket_name}"
      origin_access_control = "s3_oac"
    }
  }

  origin_access_control = {
    s3_oac = {
      description      = "OAC for ${local.bucket_name}"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3-${local.bucket_name}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    min_ttl     = var.cache_ttl.min
    default_ttl = var.cache_ttl.default
    max_ttl     = var.cache_ttl.max
  }

  # SPA: redirect 403/404 → index.html
  custom_error_response = [
    for r in var.custom_error_responses : {
      error_code            = r.error_code
      response_code         = r.response_code
      response_page_path    = r.response_page_path
      error_caching_min_ttl = r.error_caching_min_ttl
    }
  ]

  viewer_certificate = var.acm_certificate_arn != null ? {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  } : {
    cloudfront_default_certificate = true
  }

  restrictions = {
    geo_restriction = { restriction_type = "none" }
  }

  tags = var.tags
}
