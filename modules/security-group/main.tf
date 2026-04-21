module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.sg_config.name
  description = local.sg_config.description
  vpc_id      = var.vpc_id

  # Ingress Rules
  ingress_rules            = try(local.sg_config.ingress_rules, [])
  ingress_cidr_blocks      = try(local.sg_config.ingress_cidr_blocks, ["0.0.0.0/0"])
  ingress_with_cidr_blocks = try(local.sg_config.ingress_with_cidr_blocks, [])

  # Egress Rules
  egress_rules            = try(local.sg_config.egress_rules, ["all-all"])
  egress_cidr_blocks      = try(local.sg_config.egress_cidr_blocks, ["0.0.0.0/0"])

  tags = local.tags
}
