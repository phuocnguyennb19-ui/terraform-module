module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.0"

  create          = var.create
  repository_name = "${var.name}-${var.environment}"
  repository_type = var.repository_type

  repository_image_tag_mutability   = var.image_tag_mutability
  repository_image_scan_on_push     = var.scan_on_push
  repository_encryption_type        = var.encryption_type
  repository_kms_key                = var.kms_key
  repository_force_delete           = var.force_delete
  repository_read_write_access_arns = var.read_write_access_arns

  create_lifecycle_policy = var.create_lifecycle_policy
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.lifecycle.untagged_expire_days} day(s)"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.lifecycle.untagged_expire_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep last ${var.lifecycle.tagged_keep_count} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = var.lifecycle.tagged_prefix_list
          countType     = "imageCountMoreThan"
          countNumber   = var.lifecycle.tagged_keep_count
        }
        action = { type = "expire" }
      }
    ]
  })

  tags = var.tags
}
