# Standardised: use the security-group module rather than inline rules
module "alb_sg" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=v5.1.0"

  name        = "${local.alb_config.name}-sg"
  description = "Security group for ALB ${local.alb_config.name}"
  vpc_id      = var.vpc_id

  # Each rule is EITHER a predefined rule from the upstream module's catalogue
  # (a bare key such as https-443-tcp, with no fields) OR a custom rule defined
  # by its own fields. `cidr_ipv4` is what tells the two apart.
  ingress_rules = [
    for k, v in local.alb_sg_config.ingress_rules : k if !can(v.cidr_ipv4)
  ]
  ingress_with_cidr_blocks = [
    for k, v in local.alb_sg_config.ingress_rules : {
      # from_port/to_port are optional: an "all protocols" rule (ip_protocol -1)
      # carries neither, and reading them unconditionally crashed the plan on
      # this module's own default egress rule.
      from_port   = try(v.from_port, 0)
      to_port     = try(v.to_port, 0)
      protocol    = lookup(v, "ip_protocol", "tcp")
      cidr_blocks = v.cidr_ipv4
      description = lookup(v, "description", k)
    } if can(v.cidr_ipv4)
  ]

  egress_rules = [
    for k, v in local.alb_sg_config.egress_rules : k if !can(v.cidr_ipv4)
  ]
  egress_with_cidr_blocks = [
    for k, v in local.alb_sg_config.egress_rules : {
      from_port   = try(v.from_port, 0)
      to_port     = try(v.to_port, 0)
      protocol    = lookup(v, "ip_protocol", "tcp")
      cidr_blocks = v.cidr_ipv4
      description = lookup(v, "description", k)
    } if can(v.cidr_ipv4)
  ]

  tags = local.tags
}

module "alb" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-alb.git?ref=v9.11.0"

  name               = local.alb_config.name
  load_balancer_type = "application"
  internal           = local.alb_config.internal
  idle_timeout       = local.alb_config.idle_timeout

  vpc_id  = var.vpc_id
  subnets = local.alb_config.internal ? coalesce(var.private_subnets, var.public_subnets) : var.public_subnets

  # Security Groups
  security_groups = [module.alb_sg.security_group_id]

  enable_deletion_protection = local.alb_config.enable_deletion_protection
  drop_invalid_header_fields = local.alb_config.drop_invalid_header_fields
  preserve_host_header       = local.alb_config.preserve_host_header
  xff_header_processing_mode = local.alb_config.xff_header_processing_mode
  desync_mitigation_mode     = local.alb_config.desync_mitigation_mode
  enable_waf_fail_open       = local.alb_config.enable_waf_fail_open

  access_logs     = local.alb_config.access_logs
  connection_logs = local.alb_config.connection_logs

  # v9 migration: switched to maps
  listeners     = local.listeners
  target_groups = local.target_groups

  tags = local.tags

  # full upstream surface
  additional_target_group_attachments                          = local.alb_config.additional_target_group_attachments
  associate_web_acl                                            = local.alb_config.associate_web_acl
  client_keep_alive                                            = local.alb_config.client_keep_alive
  create                                                       = local.alb_config.create
  create_security_group                                        = local.alb_config.create_security_group
  customer_owned_ipv4_pool                                     = local.alb_config.customer_owned_ipv4_pool
  default_port                                                 = local.alb_config.default_port
  default_protocol                                             = local.alb_config.default_protocol
  dns_record_client_routing_policy                             = local.alb_config.dns_record_client_routing_policy
  enable_cross_zone_load_balancing                             = local.alb_config.enable_cross_zone_load_balancing
  enable_http2                                                 = local.alb_config.enable_http2
  enable_tls_version_and_cipher_suite_headers                  = local.alb_config.enable_tls_version_and_cipher_suite_headers
  enable_xff_client_port                                       = local.alb_config.enable_xff_client_port
  enforce_security_group_inbound_rules_on_private_link_traffic = local.alb_config.enforce_security_group_inbound_rules_on_private_link_traffic
  ip_address_type                                              = local.alb_config.ip_address_type
  name_prefix                                                  = local.alb_config.name_prefix
  putin_khuylo                                                 = local.alb_config.putin_khuylo
  route53_records                                              = local.alb_config.route53_records
  security_group_description                                   = local.alb_config.security_group_description
  security_group_egress_rules                                  = local.alb_config.security_group_egress_rules
  security_group_ingress_rules                                 = local.alb_config.security_group_ingress_rules
  security_group_name                                          = local.alb_config.security_group_name
  security_group_tags                                          = local.alb_config.security_group_tags
  security_group_use_name_prefix                               = local.alb_config.security_group_use_name_prefix
  subnet_mapping                                               = local.alb_config.subnet_mapping
  timeouts                                                     = local.alb_config.timeouts
  web_acl_arn                                                  = local.alb_config.web_acl_arn
}
