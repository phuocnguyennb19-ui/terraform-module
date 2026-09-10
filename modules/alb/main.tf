# APPLICATION LOAD BALANCER
#
# Consumes the foundation and never creates network infrastructure: vpc_id,
# subnet_ids and security_group_ids all arrive as inputs. Placing it in public
# subnets makes it internet-facing; private subnets plus internal = true makes
# it VPC-only. Either way the subnets came from the shared VPC.
#
# Upstream: terraform-aws-modules/alb/aws v9. Wrapped so the platform's
# target_groups/listener_rules shape stays put across upstream major versions —
# v8 and v9 have materially different listener schemas, and callers should not
# have to care.

locals {
  # Decided from a plain bool when the caller supplies one. Inferring it from
  # certificate_arn != null fails at plan whenever the certificate is issued in
  # the same configuration: the ARN is unknown until apply, so the listener map
  # keys are unknown too. Null keeps the old inference for a literal ARN.
  https_enabled = var.enable_https != null ? var.enable_https : var.certificate_arn != null

  # A default action is mandatory on a listener. When no default target group is
  # named, fall back to the first target group by key order so the listener is
  # still valid; a caller with more than one group should set it explicitly.
  default_tg_key = coalesce(
    var.default_target_group_key,
    try(sort(keys(var.target_groups))[0], null),
  )

  # ---- Target groups ------------------------------------------------------
  target_groups = {
    for k, tg in var.target_groups : k => {
      name             = substr("${var.name}-${k}", 0, 32)
      port             = tg.port
      protocol         = tg.protocol
      protocol_version = tg.protocol_version
      target_type      = tg.target_type

      deregistration_delay          = tg.deregistration_delay
      slow_start                    = tg.slow_start
      load_balancing_algorithm_type = tg.load_balancing_algorithm_type

      health_check = {
        enabled             = tg.health_check.enabled
        path                = tg.health_check.path
        port                = tg.health_check.port
        protocol            = tg.health_check.protocol
        matcher             = tg.health_check.matcher
        interval            = tg.health_check.interval
        timeout             = tg.health_check.timeout
        healthy_threshold   = tg.health_check.healthy_threshold
        unhealthy_threshold = tg.health_check.unhealthy_threshold
      }

      stickiness = {
        enabled         = tg.stickiness.enabled
        type            = tg.stickiness.type
        cookie_duration = tg.stickiness.cookie_duration
      }

      # Targets are registered by whatever owns them — the AWS Load Balancer
      # Controller for EKS, an autoscaling group's target_group_arns for EC2.
      # This module creates the group and stops there.
      create_attachment = false

      tags = merge(var.tags, tg.tags)
    }
  }

  # ---- Listener rules -----------------------------------------------------
  listener_rules = {
    for k, r in var.listener_rules : k => {
      priority = r.priority

      actions = [{
        type             = "forward"
        target_group_key = r.target_group_key
      }]

      conditions = concat(
        r.path_patterns != null ? [{ path_pattern = { values = r.path_patterns } }] : [],
        r.host_headers != null ? [{ host_header = { values = r.host_headers } }] : [],
        r.source_ips != null ? [{ source_ip = { values = r.source_ips } }] : [],
        [for h, vals in r.http_headers : {
          http_header = { http_header_name = h, values = vals }
        }],
      )
    }
  }

  # ---- Listeners ----------------------------------------------------------
  # Port 80 carries a redirect and nothing else when a certificate exists. It
  # only serves application traffic on an HTTP-only internal load balancer,
  # which is the single case where that is defensible.
  #
  # Three states, not two:
  #   certificate + redirect    -> 301 to 443, no application traffic on 80
  #   certificate, no redirect  -> no port 80 listener at all
  #   no certificate            -> port 80 forwards to the default target group
  #
  # Assembled by merge() from one base object rather than by a conditional
  # between two shapes. A ternary has to unify the types of its branches, and
  # "a listener that redirects" and "a listener that forwards" differ by exactly
  # the attribute that makes them different — so a ternary between them is
  # rejected outright, whichever way round it is written. Merging an empty map
  # in is fine, because an empty object converts to anything.
  http_redirects = local.https_enabled && var.enable_http_redirect

  http_listener = local.https_enabled && !var.enable_http_redirect ? {} : {
    http = merge(
      {
        port     = 80
        protocol = "HTTP"
      },
      local.http_redirects ? {
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      } : {},
      local.http_redirects ? {} : {
        forward = { target_group_key = local.default_tg_key }
      },
      # Rules belong on the listener that actually serves the application. On a
      # redirecting port 80 they would be evaluated before the 301 and quietly
      # bypass HTTPS for whatever they matched.
      local.http_redirects || length(local.listener_rules) == 0 ? {} : {
        rules = local.listener_rules
      },
    )
  }

  https_listener = local.https_enabled ? {
    https = merge(
      {
        port            = 443
        protocol        = "HTTPS"
        certificate_arn = var.certificate_arn
        ssl_policy      = var.ssl_policy
        forward         = { target_group_key = local.default_tg_key }
      },
      length(var.additional_certificate_arns) > 0 ? { additional_certificate_arns = var.additional_certificate_arns } : {},
      length(local.listener_rules) > 0 ? { rules = local.listener_rules } : {},
    )
  } : {}

  listeners = merge(local.http_listener, local.https_listener)
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.17.0"

  name = var.name

  load_balancer_type = "application"
  internal           = var.internal

  vpc_id  = var.vpc_id
  subnets = var.subnet_ids

  # The security group is owned by the security-groups module, which is where
  # the whole tier-to-tier rule set lives. Letting this module create its own
  # would split that boundary across two places.
  create_security_group = false
  security_groups       = var.security_group_ids

  enable_deletion_protection       = var.enable_deletion_protection
  idle_timeout                     = var.idle_timeout
  enable_http2                     = var.enable_http2
  drop_invalid_header_fields       = var.drop_invalid_header_fields
  desync_mitigation_mode           = var.desync_mitigation_mode
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  access_logs = var.enable_access_logs ? {
    bucket  = local.logs_bucket_name
    prefix  = var.access_logs_prefix
    enabled = true
  } : {}

  target_groups = local.target_groups

  # Rules are nested inside each listener in v9, not a top-level argument.
  listeners = local.listeners

  tags = var.tags

  depends_on = [aws_s3_bucket_policy.logs]
}
