variable "vpc_id" {
  description = "The VPC ID where the security group will be created"
  type        = string
  default     = null
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
