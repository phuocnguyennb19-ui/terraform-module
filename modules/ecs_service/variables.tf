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
  description = "Environment context shared by every module: environment, region and project, plus optional managed_by, cost_center and tags. `environment` is validated against dev, test, staging, preprod, prod."
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
    error_message = "environment must be one of: dev, test, staging, preprod, prod."
  }
}

variable "config_file" {
  description = "Path to the YAML config, resolved against `path.cwd` — the directory Terraform is run from, not the module directory."
  type        = string
  default     = "config.yml"
}

variable "manual_config" {
  description = "Configuration merged over the decoded YAML at the top level. The root composition uses this to pass a layered config; leave unset when calling the module directly."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Extra tags, merged over the ones derived from `global_config`."
  type        = map(string)
  default     = {}
}
