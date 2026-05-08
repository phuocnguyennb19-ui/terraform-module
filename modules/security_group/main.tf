module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.sg_config.name
  description = local.sg_config.description
  vpc_id      = local.sg_config.vpc_id

  # Ingress Rules
  ingress_rules            = local.sg_config.ingress_rules
  ingress_cidr_blocks      = local.sg_config.ingress_cidr_blocks
  ingress_with_cidr_blocks = local.sg_config.ingress_with_cidr_blocks

  # Egress Rules
  egress_rules       = local.sg_config.egress_rules
  egress_cidr_blocks = local.sg_config.egress_cidr_blocks

  # Source SG Rules
  ingress_with_source_security_group_id = local.sg_config.ingress_with_source_security_group_id
  egress_with_source_security_group_id  = local.sg_config.egress_with_source_security_group_id

  revoke_rules_on_delete = local.sg_config.revoke_rules_on_delete

  tags = local.tags
}
