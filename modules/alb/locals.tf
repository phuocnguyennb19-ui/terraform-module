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
  app_name     = lookup(local.config_local, "app_name", null)
  service_type = lookup(local.config_local, "service_type", "infra")
  name_prefix  = join("-", compact([local.env, local.app_name == "base" ? null : local.app_name, local.service_type]))

  # 4. ALB Configuration (Full-Spec for v9.x)
  raw_alb_cfg = try(local.config_local.alb, {})
  alb_defaults = {
    name                       = "${local.name_prefix}-alb"
    internal                   = lookup(local.raw_alb_cfg, "internal", false)
    idle_timeout               = lookup(local.raw_alb_cfg, "idle_timeout", 60)
    enable_deletion_protection = lookup(local.raw_alb_cfg, "enable_deletion_protection", local.env == "prod")
    drop_invalid_header_fields = lookup(local.raw_alb_cfg, "drop_invalid_header_fields", true)
    preserve_host_header       = lookup(local.raw_alb_cfg, "preserve_host_header", false)
    xff_header_processing_mode = lookup(local.raw_alb_cfg, "xff_header_processing_mode", "append")
    desync_mitigation_mode     = lookup(local.raw_alb_cfg, "desync_mitigation_mode", "defensive")
    enable_waf_fail_open       = lookup(local.raw_alb_cfg, "enable_waf_fail_open", false)
    access_logs                = lookup(local.raw_alb_cfg, "access_logs", {})
    connection_logs            = lookup(local.raw_alb_cfg, "connection_logs", {})

    # full upstream surface
    # Remaining upstream arguments with a simple literal default, mapped with
    # that same default as the fallback: omitting a key behaves as before.
    additional_target_group_attachments                          = try(local.raw_alb_cfg.additional_target_group_attachments, {})
    associate_web_acl                                            = try(local.raw_alb_cfg.associate_web_acl, false)
    client_keep_alive                                            = try(local.raw_alb_cfg.client_keep_alive, null)
    create                                                       = try(local.raw_alb_cfg.create, true)
    create_security_group                                        = try(local.raw_alb_cfg.create_security_group, true)
    customer_owned_ipv4_pool                                     = try(local.raw_alb_cfg.customer_owned_ipv4_pool, null)
    default_port                                                 = try(local.raw_alb_cfg.default_port, 80)
    default_protocol                                             = try(local.raw_alb_cfg.default_protocol, "HTTP")
    dns_record_client_routing_policy                             = try(local.raw_alb_cfg.dns_record_client_routing_policy, null)
    enable_cross_zone_load_balancing                             = try(local.raw_alb_cfg.enable_cross_zone_load_balancing, true)
    enable_http2                                                 = try(local.raw_alb_cfg.enable_http2, null)
    enable_tls_version_and_cipher_suite_headers                  = try(local.raw_alb_cfg.enable_tls_version_and_cipher_suite_headers, null)
    enable_xff_client_port                                       = try(local.raw_alb_cfg.enable_xff_client_port, null)
    enforce_security_group_inbound_rules_on_private_link_traffic = try(local.raw_alb_cfg.enforce_security_group_inbound_rules_on_private_link_traffic, null)
    ip_address_type                                              = try(local.raw_alb_cfg.ip_address_type, null)
    name_prefix                                                  = try(local.raw_alb_cfg.name_prefix, null)
    putin_khuylo                                                 = try(local.raw_alb_cfg.putin_khuylo, true)
    route53_records                                              = try(local.raw_alb_cfg.route53_records, {})
    security_group_description                                   = try(local.raw_alb_cfg.security_group_description, null)
    security_group_egress_rules                                  = try(local.raw_alb_cfg.security_group_egress_rules, {})
    security_group_ingress_rules                                 = try(local.raw_alb_cfg.security_group_ingress_rules, {})
    security_group_name                                          = try(local.raw_alb_cfg.security_group_name, null)
    security_group_tags                                          = try(local.raw_alb_cfg.security_group_tags, {})
    security_group_use_name_prefix                               = try(local.raw_alb_cfg.security_group_use_name_prefix, true)
    subnet_mapping                                               = try(local.raw_alb_cfg.subnet_mapping, [])
    timeouts                                                     = try(local.raw_alb_cfg.timeouts, {})
    web_acl_arn                                                  = try(local.raw_alb_cfg.web_acl_arn, null)
  }
  alb_config = merge(local.alb_defaults, try(local.config_local.alb, {}))

  # 4.1. Security Group Mapping
  alb_sg_config = {
    ingress_rules = lookup(local.alb_config, "security_group_ingress_rules", {})
    egress_rules  = lookup(local.alb_config, "security_group_egress_rules", { all_all = { ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" } })
  }

  # 4.2. Listeners & Target Groups Mapping (Standardized for v9.x)
  # When not declared in YAML, create the default port-80 listener (backward compatibility)
  listeners = lookup(local.alb_config, "listeners", {
    http80 = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "default"
      }
    }
  })

  target_groups = lookup(local.alb_config, "target_groups", {
    default = {
      name_prefix = "def-"
      protocol    = "HTTP"
      port        = lookup(local.alb_config, "backend_port", 80)
      target_type = "ip"
      # Upstream ALB v9 creates an aws_lb_target_group_attachment for every
      # target group unless this is false, and an attachment needs a target_id
      # that this default cannot know. Targets are registered by whatever runs
      # behind the load balancer — an ECS service, or a TargetGroupBinding.
      create_attachment = false
      health_check = {
        enabled             = true
        path                = lookup(local.alb_config, "health_check_path", "/")
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        interval            = 30
        matcher             = "200"
      }
    }
  })

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
