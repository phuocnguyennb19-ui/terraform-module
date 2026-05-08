# ==========================================
# VPC OUTPUTS
# ==========================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

# ==========================================
# SUBNETS OUTPUTS
# ==========================================

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = module.vpc.private_subnet_arns
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = module.vpc.public_subnet_arns
}

# ==========================================
# NAT GATEWAY & ROUTING
# ==========================================

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway(s). Useful for whitelisting IPs in external firewalls."
  value       = module.vpc.nat_public_ips
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = module.vpc.public_route_table_ids
}

# ==========================================
# SECURITY
# ==========================================

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = module.vpc.default_security_group_id
}

# ==========================================
# DATABASE SUBNETS
# ==========================================

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "database_subnet_group_name" {
  description = "Name of the RDS subnet group (empty when not created)"
  value       = try(module.vpc.database_subnet_group_name, null)
}

# ==========================================
# INTRA SUBNETS
# ==========================================

output "intra_subnets" {
  description = "List of IDs of intra subnets (no internet access)"
  value       = module.vpc.intra_subnets
}

# ==========================================
# FLOW LOGS
# ==========================================

output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log (null when flow log disabled)"
  value       = try(module.vpc.vpc_flow_log_id, null)
}

output "vpc_flow_log_cloudwatch_iam_role_arn" {
  description = "ARN of the CloudWatch IAM role for VPC Flow Logs"
  value       = try(module.vpc.vpc_flow_log_cloudwatch_iam_role_arn, null)
}

# ==========================================
# AZS
# ==========================================

output "azs" {
  description = "List of Availability Zones used"
  value       = local.vpc_config.azs
}