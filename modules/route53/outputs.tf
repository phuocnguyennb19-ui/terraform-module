output "route53_zone_zone_ids" { 
  description = "Map of Zone IDs"
  value       = module.zones.route53_zone_zone_id 
}

output "route53_zone_names" { 
  description = "Map of Zone Names"
  value       = module.zones.route53_zone_name 
}
