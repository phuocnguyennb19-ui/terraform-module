include "root" { path = find_in_parent_folders() }

terraform { source = "../../../modules//aws-route53" }

locals { cfg = yamldecode(file("${get_terragrunt_dir()}/values.yaml")) }

inputs = {
  zone_name = local.cfg.zone_name
  records   = {}
  tags      = local.cfg.tags
}
