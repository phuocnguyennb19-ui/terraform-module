include "root" { path = find_in_parent_folders() }

terraform { source = "../../../modules//aws-acm" }

dependency "route53" {
  config_path = "../route53"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = { zone_id = "Z00000000MOCKZONEID" }
}

locals { cfg = yamldecode(file("${get_terragrunt_dir()}/values.yaml")) }

inputs = {
  domain_name               = local.cfg.domain_name
  subject_alternative_names = local.cfg.subject_alternative_names
  wait_for_validation       = local.cfg.wait_for_validation
  zone_id                   = dependency.route53.outputs.zone_id
  tags                      = local.cfg.tags
}
