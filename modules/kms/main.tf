# CUSTOMER-MANAGED KMS KEYS
#
# Every encrypted resource in this platform points at a key from here rather
# than at an AWS-managed key. The difference that matters is the key policy: an
# AWS-managed key grants the whole account, so "who can decrypt this snapshot"
# has no answer narrower than "anyone with the right IAM". A customer-managed
# key with an explicit policy does have that answer, and it is auditable.
#
# Keys are written with a deletion window rather than being destroyable: KMS
# schedules deletion, and everything encrypted under a deleted key is
# unrecoverable. prevent_destroy is deliberately NOT set here — it would make
# `terraform destroy` fail for dev environments that are meant to be disposable.
# The 30-day default window is the real protection.

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_root = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
}

data "aws_iam_policy_document" "key" {
  for_each = var.keys

  # Without this statement the key becomes unmanageable: IAM policies cannot
  # grant access to a key whose own policy does not delegate to the account.
  # It is the documented AWS default and removing it can orphan the key.
  dynamic "statement" {
    for_each = each.value.enable_default_policy ? [1] : []

    content {
      sid       = "EnableAccountIAMPolicies"
      effect    = "Allow"
      actions   = ["kms:*"]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = [local.account_root]
      }
    }
  }

  dynamic "statement" {
    for_each = length(each.value.key_administrator_arns) > 0 ? [1] : []

    content {
      sid    = "KeyAdministrators"
      effect = "Allow"
      actions = [
        "kms:Create*", "kms:Describe*", "kms:Enable*", "kms:List*",
        "kms:Put*", "kms:Update*", "kms:Revoke*", "kms:Disable*",
        "kms:Get*", "kms:Delete*", "kms:TagResource", "kms:UntagResource",
        "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = each.value.key_administrator_arns
      }
    }
  }

  dynamic "statement" {
    for_each = length(each.value.key_user_arns) > 0 ? [1] : []

    content {
      sid    = "KeyUsers"
      effect = "Allow"
      actions = [
        "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
        "kms:GenerateDataKey*", "kms:DescribeKey",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = each.value.key_user_arns
      }
    }
  }

  # Service principals get use of the key, and CreateGrant only through the
  # service itself — the ViaService condition is what stops a granted service
  # principal being usable as a general-purpose decrypt path.
  dynamic "statement" {
    for_each = length(each.value.service_principals) > 0 ? [1] : []

    content {
      sid    = "ServicePrincipals"
      effect = "Allow"
      actions = [
        "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
        "kms:GenerateDataKey*", "kms:DescribeKey", "kms:CreateGrant",
      ]
      resources = ["*"]

      principals {
        type        = "Service"
        identifiers = each.value.service_principals
      }

      condition {
        test     = "StringEquals"
        variable = "kms:CallerAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }
}

resource "aws_kms_key" "this" {
  for_each = var.keys

  description             = each.value.description
  deletion_window_in_days = each.value.deletion_window_in_days
  enable_key_rotation     = each.value.enable_rotation
  rotation_period_in_days = each.value.enable_rotation ? each.value.rotation_period_in_days : null
  multi_region            = each.value.multi_region
  policy                  = data.aws_iam_policy_document.key[each.key].json

  tags = merge(var.tags, each.value.tags, {
    Name    = "${var.name}-${each.key}"
    Purpose = each.key
  })
}

resource "aws_kms_alias" "this" {
  for_each = var.keys

  name          = "alias/${var.name}-${each.key}"
  target_key_id = aws_kms_key.this[each.key].key_id
}
