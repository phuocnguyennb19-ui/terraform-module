output "route53_zone_zone_ids" {
  description = "Map of Zone IDs"
  value       = module.zones.route53_zone_zone_id
}

output "route53_zone_names" {
  description = "Map of Zone Names"
  value       = module.zones.route53_zone_name
}

output "route53_zone_name_servers" {
  description = "Map of zone name servers"
  value       = module.zones.route53_zone_name_servers
}

output "route53_record_names" {
  description = "Map of zone → record names created"
  value       = { for k, v in module.records : k => v.route53_record_name }
}
