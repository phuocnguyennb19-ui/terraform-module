# ROOT OUTPUTS
# Every output is try()-wrapped because every module is count-gated: a disabled
# module has no instance, and indexing it would be an error rather than a null.

# context

output "environment" {
  description = "Environment this state manages."
  value       = local.global.environment
}

output "region" {
  description = "AWS region."
  value       = local.global.region
}

output "account_id" {
  description = "AWS account this ran against."
  value       = data.aws_caller_identity.current.account_id
}

output "enabled_modules" {
  description = "Which modules this environment's config.yml switched on."
  value       = [for k, v in local.enabled : k if v]
}

# networking

output "vpc_id" {
  description = "VPC ID."
  value       = try(module.vpc[0].vpc_id, null)
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = try(module.vpc[0].vpc_cidr_block, null)
}

output "public_subnets" {
  description = "Public subnet IDs."
  value       = try(module.vpc[0].public_subnets, [])
}

output "private_subnets" {
  description = "Private subnet IDs."
  value       = try(module.vpc[0].private_subnets, [])
}

output "database_subnets" {
  description = "Database subnet IDs."
  value       = try(module.vpc[0].database_subnets, [])
}

output "nat_public_ips" {
  description = "NAT gateway public IPs — the addresses to whitelist downstream."
  value       = try(module.vpc[0].nat_public_ips, [])
}

# security

output "kms_key_arn" {
  description = "KMS key ARN for encryption at rest."
  value       = try(module.kms[0].key_arn, null)
}

output "security_group_id" {
  description = "Shared application security group ID."
  value       = try(module.security_group[0].security_group_id, null)
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN."
  value       = try(module.acm[0].acm_certificate_arn, null)
}

output "web_acl_arn" {
  description = "WAF web ACL ARN."
  value       = try(module.waf[0].web_acl_arn, null)
}

output "iam_role_arns" {
  description = "All IAM role ARNs created by the iam module."
  value       = try(module.iam[0].all_role_arns, {})
}

output "secret_arns" {
  description = "Secrets Manager secret ARNs."
  value       = try(module.secrets_manager[0].secret_arns, {})
  sensitive   = true
}

# edge

output "alb_dns_name" {
  description = "ALB DNS name."
  value       = try(module.alb[0].lb_dns_name, null)
}

output "alb_zone_id" {
  description = "ALB hosted zone ID — for a Route53 alias record."
  value       = try(module.alb[0].lb_zone_id, null)
}

output "alb_listener_arns" {
  description = "ALB listener ARNs."
  value       = try(module.alb[0].http_tcp_listener_arns, [])
}

output "route53_zone_ids" {
  description = "Route53 hosted zone IDs."
  value       = try(module.dns[0].route53_zone_zone_ids, {})
}

# data

output "rds_endpoint" {
  description = "RDS instance endpoint."
  value       = try(module.rds[0].db_instance_endpoint, null)
}

output "rds_master_user_secret_arn" {
  description = "ARN of the AWS-managed master user secret."
  value       = try(module.rds[0].db_master_user_secret_arn, null)
}

output "elasticache_primary_endpoint" {
  description = "ElastiCache primary endpoint."
  value       = try(module.elasticache[0].primary_endpoint_address, null)
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN."
  value       = try(module.s3[0].s3_bucket_arn, null)
}

output "dynamodb_table_arns" {
  description = "DynamoDB table ARNs."
  value       = try(module.dynamodb[0].dynamodb_table_arns, {})
}

# compute

output "ecr_repository_urls" {
  description = "ECR repository URLs."
  value       = try(module.ecr[0].repository_urls, {})
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN."
  value       = try(module.ecs_cluster[0].cluster_arn, null)
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = try(module.ecs_service[0].name, null)
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN."
  value       = try(module.ecs_service[0].task_definition_arn, null)
}

# kubernetes

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = try(module.eks[0].cluster_name, null)
}

output "eks_cluster_endpoint" {
  description = "EKS Kubernetes API endpoint."
  value       = try(module.eks[0].cluster_endpoint, null)
}

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN — the trust anchor for IRSA roles."
  value       = try(module.eks[0].oidc_provider_arn, null)
}

output "eks_node_security_group_id" {
  description = "Security group shared by the EKS managed node groups."
  value       = try(module.eks[0].node_security_group_id, null)
}

output "eks_kubeconfig_command" {
  description = "Command that writes a kubeconfig entry for the cluster."
  value       = try(module.eks[0].kubeconfig_command, null)
}

# messaging & observability

output "sqs_queue_urls" {
  description = "SQS queue URLs."
  value       = try(module.sqs[0].sqs_queue_urls, {})
}

output "sns_topic_arns" {
  description = "SNS topic ARNs — paste into cloudwatch alarm_actions in config.yml."
  value       = try(module.sns[0].sns_topic_arns, {})
}

output "log_group_names" {
  description = "CloudWatch log group names."
  value       = try(module.cloudwatch[0].log_group_names, {})
}
