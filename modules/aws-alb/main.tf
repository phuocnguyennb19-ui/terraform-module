locals {
  # Target group mặc định (priority = null → default listener rule)
  default_tg = { for k, v in var.target_groups : k => v if length(v.path_patterns) == 0 && length(v.host_headers) == 0 }
  # Target groups có path/host routing
  routed_tgs = { for k, v in var.target_groups : k => v if length(v.path_patterns) > 0 || length(v.host_headers) > 0 }

  default_tg_key = length(local.default_tg) > 0 ? keys(local.default_tg)[0] : keys(var.target_groups)[0]
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  create                = var.create
  create_security_group = var.create_security_group

  name             = "${var.name}-${var.environment}-alb"
  vpc_id           = var.vpc_id
  subnets          = var.subnet_ids
  internal         = var.internal       # false=internet-facing | true=internal
  ip_address_type  = var.ip_address_type
  idle_timeout     = var.idle_timeout

  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true
  preserve_host_header       = true

  access_logs = var.access_logs.enabled ? {
    bucket = var.access_logs.bucket; prefix = var.access_logs.prefix; enabled = true
  } : { enabled = false }

  # SG: internal ALB chỉ nhận từ VPC CIDR, internet-facing nhận từ 0.0.0.0/0
  security_group_ingress_rules = var.internal ? {
    internal_http  = { from_port = 80;  to_port = 80;  ip_protocol = "tcp"; cidr_ipv4 = var.vpc_cidr_block }
    internal_https = { from_port = 443; to_port = 443; ip_protocol = "tcp"; cidr_ipv4 = var.vpc_cidr_block }
  } : {
    public_http  = { from_port = 80;  to_port = 80;  ip_protocol = "tcp"; cidr_ipv4 = "0.0.0.0/0" }
    public_https = { from_port = 443; to_port = 443; ip_protocol = "tcp"; cidr_ipv4 = "0.0.0.0/0" }
  }

  security_group_egress_rules = {
    all = { ip_protocol = "-1"; cidr_ipv4 = var.vpc_cidr_block }
  }

  listeners = var.internal ? {
    # Internal ALB: HTTP only (no cert needed, TLS terminated at service mesh or VPN)
    http = {
      port     = 80
      protocol = "HTTP"
      forward  = { target_group_key = local.default_tg_key }
    }
  } : {
    # Internet-facing: redirect HTTP → HTTPS, forward to default target group
    http_redirect = {
      port     = 80; protocol = "HTTP"
      redirect = { port = "443"; protocol = "HTTPS"; status_code = "HTTP_301" }
    }
    https = {
      port            = 443; protocol = "HTTPS"
      certificate_arn = var.acm_certificate_arn
      forward         = { target_group_key = local.default_tg_key }

      # Path-based rules cho các service có routing
      rules = {
        for k, v in local.routed_tgs : k => {
          priority = v.priority
          actions  = [{ type = "forward"; target_group_key = k }]
          conditions = concat(
            length(v.path_patterns) > 0 ? [{ path_pattern = { values = v.path_patterns } }] : [],
            length(v.host_headers) > 0  ? [{ host_header  = { values = v.host_headers } }]  : []
          )
        }
      }
    }
  }

  # Tạo target group cho mỗi service
  target_groups = {
    for k, v in var.target_groups : k => {
      backend_protocol  = "HTTP"
      backend_port      = v.port
      target_type       = "ip"
      create_attachment = false
      health_check = {
        path                = v.health_check_path
        healthy_threshold   = v.health_check.healthy_threshold
        unhealthy_threshold = v.health_check.unhealthy_threshold
        interval            = v.health_check.interval
        timeout             = v.health_check.timeout
        matcher             = v.health_check.matcher
      }
    }
  }

  tags = var.tags
}
