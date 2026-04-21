module "s3_bucket" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v4.1.2"

  bucket = local.s3_config.bucket
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  # Dynamic encryption: Use KMS if provided, otherwise fallback to AES256 (SSE-S3)
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = merge(
        { sse_algorithm = try(local.s3_config.kms_key_id, null) != null ? "aws:kms" : "AES256" },
        try(local.s3_config.kms_key_id, null) != null ? { kms_master_key_id = local.s3_config.kms_key_id } : {}
      )
    }
  }

  tags = local.tags
}
