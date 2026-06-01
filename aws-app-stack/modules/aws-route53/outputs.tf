# zone_id trả về bất kể tạo mới hay dùng có sẵn
output "zone_id"   { value = local.resolved_zone_id }
output "zone_name" { value = var.zone_name }
output "zone_arn" {
  value = var.create_zone ? module.zones[0].route53_zone_zone_arn[var.zone_name] : ""
}
