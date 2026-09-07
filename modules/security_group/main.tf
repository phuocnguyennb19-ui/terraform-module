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

  # full upstream surface
  computed_egress_rules                                    = local.sg_config.computed_egress_rules
  computed_egress_with_cidr_blocks                         = local.sg_config.computed_egress_with_cidr_blocks
  computed_egress_with_ipv6_cidr_blocks                    = local.sg_config.computed_egress_with_ipv6_cidr_blocks
  computed_egress_with_prefix_list_ids                     = local.sg_config.computed_egress_with_prefix_list_ids
  computed_egress_with_self                                = local.sg_config.computed_egress_with_self
  computed_egress_with_source_security_group_id            = local.sg_config.computed_egress_with_source_security_group_id
  computed_ingress_rules                                   = local.sg_config.computed_ingress_rules
  computed_ingress_with_cidr_blocks                        = local.sg_config.computed_ingress_with_cidr_blocks
  computed_ingress_with_ipv6_cidr_blocks                   = local.sg_config.computed_ingress_with_ipv6_cidr_blocks
  computed_ingress_with_prefix_list_ids                    = local.sg_config.computed_ingress_with_prefix_list_ids
  computed_ingress_with_self                               = local.sg_config.computed_ingress_with_self
  computed_ingress_with_source_security_group_id           = local.sg_config.computed_ingress_with_source_security_group_id
  create                                                   = local.sg_config.create
  create_sg                                                = local.sg_config.create_sg
  create_timeout                                           = local.sg_config.create_timeout
  delete_timeout                                           = local.sg_config.delete_timeout
  egress_prefix_list_ids                                   = local.sg_config.egress_prefix_list_ids
  egress_with_cidr_blocks                                  = local.sg_config.egress_with_cidr_blocks
  egress_with_ipv6_cidr_blocks                             = local.sg_config.egress_with_ipv6_cidr_blocks
  egress_with_prefix_list_ids                              = local.sg_config.egress_with_prefix_list_ids
  egress_with_self                                         = local.sg_config.egress_with_self
  ingress_ipv6_cidr_blocks                                 = local.sg_config.ingress_ipv6_cidr_blocks
  ingress_prefix_list_ids                                  = local.sg_config.ingress_prefix_list_ids
  ingress_with_ipv6_cidr_blocks                            = local.sg_config.ingress_with_ipv6_cidr_blocks
  ingress_with_prefix_list_ids                             = local.sg_config.ingress_with_prefix_list_ids
  ingress_with_self                                        = local.sg_config.ingress_with_self
  number_of_computed_egress_rules                          = local.sg_config.number_of_computed_egress_rules
  number_of_computed_egress_with_cidr_blocks               = local.sg_config.number_of_computed_egress_with_cidr_blocks
  number_of_computed_egress_with_ipv6_cidr_blocks          = local.sg_config.number_of_computed_egress_with_ipv6_cidr_blocks
  number_of_computed_egress_with_prefix_list_ids           = local.sg_config.number_of_computed_egress_with_prefix_list_ids
  number_of_computed_egress_with_self                      = local.sg_config.number_of_computed_egress_with_self
  number_of_computed_egress_with_source_security_group_id  = local.sg_config.number_of_computed_egress_with_source_security_group_id
  number_of_computed_ingress_rules                         = local.sg_config.number_of_computed_ingress_rules
  number_of_computed_ingress_with_cidr_blocks              = local.sg_config.number_of_computed_ingress_with_cidr_blocks
  number_of_computed_ingress_with_ipv6_cidr_blocks         = local.sg_config.number_of_computed_ingress_with_ipv6_cidr_blocks
  number_of_computed_ingress_with_prefix_list_ids          = local.sg_config.number_of_computed_ingress_with_prefix_list_ids
  number_of_computed_ingress_with_self                     = local.sg_config.number_of_computed_ingress_with_self
  number_of_computed_ingress_with_source_security_group_id = local.sg_config.number_of_computed_ingress_with_source_security_group_id
  putin_khuylo                                             = local.sg_config.putin_khuylo
  security_group_id                                        = local.sg_config.security_group_id
  use_name_prefix                                          = local.sg_config.use_name_prefix
}
