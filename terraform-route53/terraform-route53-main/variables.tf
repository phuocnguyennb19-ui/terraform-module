variable "zone_id" {
  description = "The ID of the hosted zone"
  type        = string
}

variable "name" {
  description = "The name of the DNS record"
  type        = string
}

variable "type" {
  description = "The type of the DNS record (e.g., A, AAAA, CNAME, etc.)"
  type        = string
}

variable "alias_name" {
  description = "The DNS name of the target resource"
  type        = string
}

variable "alias_zone_id" {
  description = "The ID of the hosted zone of the target resource"
  type        = string
}

variable "evaluate_target_health" {
  description = "Whether to evaluate the health of the alias target"
  type        = bool
  default     = true
}
