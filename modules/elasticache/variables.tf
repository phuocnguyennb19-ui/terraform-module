variable "vpc_id" {
  description = "VPC ID for orchestration"
  type        = string
  default     = null
}

variable "private_subnets" {
  description = "Private Subnets for orchestration"
  type        = list(string)
  default     = null
}
