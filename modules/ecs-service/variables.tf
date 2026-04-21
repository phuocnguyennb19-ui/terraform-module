variable "vpc_id" {
  description = "VPC ID passed from the Master Orchestrator"
  type        = string
  default     = null
}

variable "private_subnets" {
  description = "Private Subnet IDs passed from the Master Orchestrator"
  type        = list(string)
  default     = []
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for security group rules"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_arn" {
  description = "ECS Cluster ARN passed from the Master Orchestrator"
  type        = string
  default     = null
}

variable "listener_arn" {
  description = "ALB HTTP Listener ARN for auto-attachment"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "ECS Cluster Name (legacy, prefer cluster_arn)"
  type        = string
  default     = null
}

variable "target_group_arn" {
  description = "ALB Target Group ARN (optional override)"
  type        = string
  default     = null
}
