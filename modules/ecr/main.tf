module "ecr" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ecr.git?ref=v2.2.1"

  for_each = toset(local.ecr_config.repository_names)

  repository_name = each.key
  repository_type = "private"

  repository_image_tag_mutability    = local.ecr_config.image_tag_mutability
  repository_force_delete            = local.ecr_config.repository_force_delete
  repository_read_access_arns        = local.ecr_config.read_access_arns
  repository_read_write_access_arns  = local.ecr_config.read_write_access_arns

  repository_encryption_type = local.ecr_config.encryption_type
  repository_kms_key         = local.ecr_config.kms_key

  # Image Scanning
  repository_image_scan_on_push = local.ecr_config.scan_on_push

  # Lifecycle Policy
  repository_lifecycle_policy = local.ecr_config.lifecycle_policy != null ? local.ecr_config.lifecycle_policy : jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = local.tags
}
