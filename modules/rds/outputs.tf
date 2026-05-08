output "db_instance_address" {
  description = "Hostname of the RDS instance"
  value       = module.db.db_instance_address
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = module.db.db_instance_arn
}

output "db_instance_endpoint" {
  description = "Connection endpoint (host:port)"
  value       = module.db.db_instance_endpoint
}

output "db_instance_id" {
  description = "Identifier of the RDS instance"
  value       = module.db.db_instance_identifier
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = module.db.db_instance_port
}

output "db_instance_name" {
  description = "Database name"
  value       = module.db.db_instance_name
}

output "db_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master user credentials"
  value       = try(module.db.db_instance_master_user_secret_arn, null)
}

output "db_security_group_id" {
  description = "ID of the RDS security group"
  value       = module.rds_sg.security_group_id
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = module.db.db_subnet_group_name
}
