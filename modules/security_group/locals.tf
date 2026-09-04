locals {

  # 2. Local Module Config (Support dynamic config file name)
  config_local = merge(
    try(yamldecode(file("${path.cwd}/${var.config_file}")), {}),
    var.manual_config
  )

  # 3. Context & Naming (Strict mapping from config.yml)
  env          = lookup(var.global_config, "environment", "dev")
  region       = lookup(var.global_config, "region", "ap-southeast-1")
  project      = lookup(var.global_config, "project", "core")
  app_name     = lookup(local.config_local, "app_name", "security")
  service_type = lookup(local.config_local, "service_type", "infra")
  name_prefix  = join("-", compact([local.env, local.app_name == "base" ? null : local.app_name, local.service_type]))

  # 4. Security Group Configuration
  raw_sg_cfg = try(local.config_local.security_group, {})
  sg_defaults = {
    name                                  = "${local.name_prefix}-sg"
    description                           = try(local.raw_sg_cfg.description, "Security group managed by Terraform")
    vpc_id                                = var.vpc_id
    ingress_rules                         = try(local.raw_sg_cfg.ingress_rules, [])
    ingress_cidr_blocks                   = try(local.raw_sg_cfg.ingress_cidr_blocks, [])
    ingress_with_cidr_blocks              = try(local.raw_sg_cfg.ingress_with_cidr_blocks, [])
    egress_rules                          = try(local.raw_sg_cfg.egress_rules, ["all-all"])
    egress_cidr_blocks                    = try(local.raw_sg_cfg.egress_cidr_blocks, ["0.0.0.0/0"])
    ingress_with_source_security_group_id = try(local.raw_sg_cfg.ingress_with_source_security_group_id, [])
    egress_with_source_security_group_id  = try(local.raw_sg_cfg.egress_with_source_security_group_id, [])
    revoke_rules_on_delete                = try(local.raw_sg_cfg.revoke_rules_on_delete, false)
  }
  sg_config = merge(local.sg_defaults, try(local.config_local.security_group, {}))

  # 5. Global Alias & Tags
  config = local.config_local
  tags = merge(
    {
      Environment = local.env,
      Project     = local.project,
      ManagedBy   = lookup(var.global_config, "managed_by", "DylanDevOps"),
      CostCenter  = lookup(var.global_config, "cost_center", "shared-services"),
      Terraform   = "true"
    },
    var.tags, try(var.global_config.tags, {})
  )
}
