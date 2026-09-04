# ==========================================
# CLUSTER
# ==========================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint of the Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version running on the control plane"
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA certificate for the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

# ==========================================
# IDENTITY — IRSA
# ==========================================

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider, for IRSA role trust policies"
  value       = try(module.eks.oidc_provider_arn, null)
}

output "oidc_provider_url" {
  description = "URL of the cluster's OIDC issuer"
  value       = try(module.eks.cluster_oidc_issuer_url, null)
}

# ==========================================
# SECURITY
# ==========================================

output "cluster_security_group_id" {
  description = "Security group ID attached to the control plane"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID shared by the managed node groups"
  value       = try(module.eks.node_security_group_id, null)
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for envelope encryption of secrets"
  value       = try(module.eks.kms_key_arn, null)
}

# ==========================================
# NODE GROUPS
# ==========================================

output "eks_managed_node_groups" {
  description = "Attributes of each managed node group"
  value       = try(module.eks.eks_managed_node_groups, {})
}

output "node_group_iam_role_arns" {
  description = "IAM role ARN of each managed node group"
  value       = try({ for k, v in module.eks.eks_managed_node_groups : k => v.iam_role_arn }, {})
}

output "fargate_profiles" {
  description = "Attributes of each Fargate profile"
  value       = try(module.eks.fargate_profiles, {})
}

# ==========================================
# KUBECONFIG
# ==========================================

output "kubeconfig_command" {
  description = "Command that writes a kubeconfig entry for this cluster"
  value       = "aws eks update-kubeconfig --region ${local.region} --name ${module.eks.cluster_name}"
}
