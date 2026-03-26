output "record_name" {
  description = "The name of the record"
  value       = aws_route53_record.this.name
}

output "record_type" {
  description = "The type of the record"
  value       = aws_route53_record.this.type
}

output "record_zone_id" {
  description = "The zone ID of the record"
  value       = aws_route53_record.this.zone_id
}

output "alias_name" {
  description = "The alias name of the record"
  value       = aws_route53_record.this.alias.0.name
}
