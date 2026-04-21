module "ecr" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ecr.git?ref=v1.6.0"
  
  for_each = toset(local.ecr_config.repository_names)

  repository_name = each.value
  repository_type = "private"

  repository_image_tag_mutability = local.ecr_config.image_tag_mutability
  repository_read_access_arns     = [] # Optional: Grant read access to specific roles
  
  # Image Scanning
  repository_image_scan_on_push = local.ecr_config.scan_on_push

  # Lifecycle Policy
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = local.tags
}
