# ACCESS LOG BUCKET
#
# Optional, and created here rather than in a shared S3 module because its
# bucket policy is specific to ELB log delivery and nothing else uses it.
#
# Two delivery identities exist and which one applies depends on the region's
# age. Availability Zones launched before August 2022 deliver from a per-region
# ELB service account; newer ones deliver as the logdelivery service principal.
# Both statements are written, so the bucket works either way — but the service
# account lookup itself fails in a region AWS never assigned one to, which is
# what use_elb_service_account_principal exists to turn off.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

data "aws_elb_service_account" "this" {
  count = local.create_logs_bucket && var.use_elb_service_account_principal ? 1 : 0
}

locals {
  create_logs_bucket = var.enable_access_logs && var.access_logs_bucket == null && var.create_access_logs_bucket
  logs_bucket_name   = local.create_logs_bucket ? "${var.name}-alb-logs-${data.aws_caller_identity.current.account_id}" : var.access_logs_bucket
}

resource "aws_s3_bucket" "logs" {
  count = local.create_logs_bucket ? 1 : 0

  bucket        = local.logs_bucket_name
  force_destroy = false

  tags = merge(var.tags, { Name = local.logs_bucket_name, Purpose = "alb-access-logs" })
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count = local.create_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count = local.create_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# SSE-S3, not SSE-KMS. ELB log delivery cannot write to a bucket encrypted with
# a customer-managed KMS key — it fails silently, producing an empty bucket and
# no error anywhere. AES256 is the supported option.
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count = local.create_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  count = local.create_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = local.create_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "expire-access-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.access_logs_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "logs" {
  count = local.create_logs_bucket ? 1 : 0

  # Pre-August-2022 regions: the regional ELB service account writes the objects.
  dynamic "statement" {
    for_each = var.use_elb_service_account_principal ? [1] : []

    content {
      sid       = "AllowELBServiceAccountPut"
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${aws_s3_bucket.logs[0].arn}/${var.access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

      principals {
        type        = "AWS"
        identifiers = [data.aws_elb_service_account.this[0].arn]
      }
    }
  }

  # Post-August-2022 regions: delivery arrives as a service principal.
  statement {
    sid       = "AllowLogDeliveryPut"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs[0].arn}/${var.access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid       = "AllowLogDeliveryAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs[0].arn]

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }
  }

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.logs[0].arn, "${aws_s3_bucket.logs[0].arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  count = local.create_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id
  policy = data.aws_iam_policy_document.logs[0].json
}
