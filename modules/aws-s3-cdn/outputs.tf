output "bucket_name"            { value = module.s3_bucket.s3_bucket_id }
output "bucket_arn"             { value = module.s3_bucket.s3_bucket_arn }
output "bucket_regional_domain" { value = module.s3_bucket.s3_bucket_bucket_regional_domain_name }

output "cloudfront_id"          { value = var.create_cloudfront ? module.cloudfront[0].cloudfront_distribution_id : "" }
output "cloudfront_domain"      { value = var.create_cloudfront ? module.cloudfront[0].cloudfront_distribution_domain_name : "" }
output "cloudfront_zone_id"     { value = var.create_cloudfront ? module.cloudfront[0].cloudfront_distribution_hosted_zone_id : "" }
output "cloudfront_arn"         { value = var.create_cloudfront ? module.cloudfront[0].cloudfront_distribution_arn : "" }
