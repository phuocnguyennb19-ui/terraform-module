include "root" { path = find_in_parent_folders() }

terraform { source = "../../../modules//aws-ecr" }

locals { cfg = yamldecode(file("${get_terragrunt_dir()}/values.yaml")) }

inputs = {
  name        = local.cfg.name
  environment = local.cfg.environment

  image_tag_mutability = local.cfg.image_tag_mutability
  scan_on_push         = local.cfg.scan_on_push
  encryption_type      = local.cfg.encryption_type
  force_delete         = local.cfg.force_delete
  lifecycle            = local.cfg.lifecycle

  tags = local.cfg.tags
}
