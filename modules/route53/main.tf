# ROUTE53 — the entry point of the shared-services layer
#
# The zone is either created here or looked up, and records point at whatever
# the environment stands up. The ALB alias record is the usual reason this
# module exists; ACM also consumes the zone ID to write its validation records,
# which is why route53 has to be composed before acm in the environment root.

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0

  name          = var.zone_name
  comment       = "Managed by Terraform — ${var.zone_name}"
  force_destroy = var.force_destroy

  dynamic "vpc" {
    for_each = var.private_zone ? var.vpc_ids : []

    content {
      vpc_id = vpc.value
    }
  }

  tags = merge(var.tags, { Name = var.zone_name })
}

data "aws_route53_zone" "this" {
  count = var.create_zone ? 0 : 1

  name         = var.zone_name
  private_zone = var.private_zone
}

locals {
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : data.aws_route53_zone.this[0].zone_id
}

resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = local.zone_id
  name    = each.value.name
  type    = each.value.type

  # TTL and records are mutually exclusive with an alias block — an alias has no
  # TTL of its own, it inherits the target's.
  ttl     = each.value.alias == null ? each.value.ttl : null
  records = each.value.records

  set_identifier  = each.value.set_identifier
  health_check_id = each.value.health_check_id
  allow_overwrite = each.value.allow_overwrite

  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []

    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  dynamic "weighted_routing_policy" {
    for_each = each.value.weighted_routing_weight != null ? [1] : []

    content {
      weight = each.value.weighted_routing_weight
    }
  }
}
