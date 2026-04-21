variable "vpc_id" {
  description = "VPC ID for same-stack orchestration"
  type        = string
  default     = null
}

variable "private_subnets" {
  description = "Subnet IDs for same-stack orchestration"
  type        = list(string)
  default     = null
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for security group ingress rules"
  type        = string
  default     = "10.0.0.0/16"
}
