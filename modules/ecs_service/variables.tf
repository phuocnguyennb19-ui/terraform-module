variable "cluster_arn" {
  description = "ARN of the ECS cluster to deploy the service into"
  type        = string
}

variable "listener_arn" {
  description = "ARN of the ALB listener to attach listener rules to (optional)"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID — required for creating the target group"
  type        = string
  default     = null
}

variable "private_subnets" {
  description = "List of private subnet IDs for the ECS service network configuration"
  type        = list(string)
  default     = null
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block — used to restrict ingress security group rules"
  type        = string
  default     = "10.0.0.0/16"
}

variable "global_config" {
  type = object({
    environment = string
    region      = string
    project     = string
    managed_by  = optional(string, "DylanDevOps")
    cost_center = optional(string, "shared-services")
    tags        = optional(map(string), {})
  })

  validation {
    condition     = contains(["dev", "test", "staging", "preprod", "prod"], var.global_config.environment)
    error_message = "Biến environment phải là một trong các giá trị: dev, test, staging, preprod, prod."
  }
}

variable "config_file" {
  type    = string
  default = "config.yml"
}

variable "manual_config" {
  type    = any
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
