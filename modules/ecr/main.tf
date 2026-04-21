resource "aws_ecr_repository" "this" {
  for_each = toset(local.ecr_config.repository_names)

  name                 = each.value
  image_tag_mutability = local.ecr_config.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = local.ecr_config.scan_on_push
  }

  tags = local.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode({
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
}
