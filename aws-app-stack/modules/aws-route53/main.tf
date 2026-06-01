locals {
  # Khi create_zone = true  → dùng zone_id vừa tạo
  # Khi create_zone = false → dùng zone_id truyền từ ngoài (dependency route53.zone_id)
  resolved_zone_id = var.create_zone ? module.zones[0].route53_zone_zone_id[var.zone_name] : var.zone_id
}

module "zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 3.0"

  count = var.create_zone ? 1 : 0   # skip khi chỉ add records vào zone có sẵn

  zones = {
    "${var.zone_name}" = {
      comment       = "Managed by Terragrunt"
      force_destroy = false
    }
  }

  tags = var.tags
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  create  = length(var.records) > 0
  zone_id = local.resolved_zone_id

  records = [
    for name, r in var.records : {
      name    = name
      type    = r.type
      ttl     = try(r.ttl, null)
      records = try(r.records, null)
      alias   = try(r.alias, null)
    }
  ]
}
