# Chuẩn hóa: Sử dụng module cho Security Group
module "alb_sg" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=v5.1.0"

  name        = "${local.alb_config.name}-sg"
  description = "Security group for ALB ${local.alb_config.name}"
  vpc_id      = var.vpc_id

  # Full-Spec Ingress/Egress mapping
  ingress_rules = [for k, v in local.alb_sg_config.ingress_rules : k]
  ingress_with_cidr_blocks = [
    for k, v in local.alb_sg_config.ingress_rules : {
      from_port   = v.from_port
      to_port     = v.to_port
      protocol    = v.ip_protocol
      cidr_blocks = v.cidr_ipv4
      description = lookup(v, "description", k)
    } if can(v.cidr_ipv4)
  ]

  egress_rules = [for k, v in local.alb_sg_config.egress_rules : k]
  egress_with_cidr_blocks = [
    for k, v in local.alb_sg_config.egress_rules : {
      from_port   = v.from_port
      to_port     = v.to_port
      protocol    = v.ip_protocol
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

  # V9 Migration: Chuyển sang dùng Maps
  listeners     = local.listeners
  target_groups = local.target_groups

  tags = local.tags
}
