include "root" { path = find_in_parent_folders() }

terraform { source = "../../../modules//aws-route53" }

dependency "route53" {
  config_path = "../route53"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = { zone_id = "Z00000000MOCKZONEID" }
}

dependency "alb" {
  config_path = "../alb"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    alb_dns_name = "mock-alb.ap-southeast-1.elb.amazonaws.com"
    alb_zone_id  = "Z32O12XQLNTSW2"
  }
}

locals {
  cfg = yamldecode(file("${get_terragrunt_dir()}/values.yaml"))

  alb_alias_record = {
    "${local.cfg.alb_record_name}" = {
      type = "A"
      alias = {
        name                   = dependency.alb.outputs.alb_dns_name
        zone_id                = dependency.alb.outputs.alb_zone_id
        evaluate_target_health = true
      }
    }
  }

  all_records = merge(local.alb_alias_record, try(local.cfg.records, {}))
}

inputs = {
  zone_name   = local.cfg.zone_name
  create_zone = false
  zone_id     = dependency.route53.outputs.zone_id
  records     = local.all_records
  tags        = local.cfg.tags
}
