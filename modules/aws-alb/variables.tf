# ── Required ──────────────────────────────────────────────────────────────────
variable "name"        { type = string }
variable "environment" { type = string }
variable "vpc_id"      { type = string }
variable "subnet_ids"  { type = list(string) }  # public = internet-facing, private = internal
variable "vpc_cidr_block" { type = string }

# ── Create toggles ────────────────────────────────────────────────────────────
variable "create"                { type = bool; default = true }
variable "create_security_group" { type = bool; default = true }

# ── ALB type ──────────────────────────────────────────────────────────────────
variable "internal" {
  description = "false = internet-facing (public ALB) | true = internal (private microservice)"
  type        = bool
  default     = false
}

variable "ip_address_type"            { type = string; default = "ipv4" }
variable "enable_deletion_protection" { type = bool;   default = true }
variable "idle_timeout"               { type = number; default = 60 }

# ── HTTPS cert (required khi internal = false) ────────────────────────────────
variable "acm_certificate_arn" { type = string; default = "" }

# ── Target groups — support nhiều service với path routing ────────────────────
# Mỗi target group = 1 backend service
# Ví dụ: { api = { port=8080, path="/api/*" }, admin = { port=9090, path="/admin/*" } }
variable "target_groups" {
  type = map(object({
    port              = number
    health_check_path = optional(string, "/health")
    priority          = optional(number, null)   # null = default route
    path_patterns     = optional(list(string), [])  # [] = default route
    host_headers      = optional(list(string), [])
    health_check = optional(object({
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 3)
      interval            = optional(number, 30)
      timeout             = optional(number, 10)
      matcher             = optional(string, "200-299")
    }), {})
  }))
  default = {
    default = { port = 8080 }
  }
}

# ── Access Logs ───────────────────────────────────────────────────────────────
variable "access_logs" {
  type = object({
    enabled = optional(bool, false)
    bucket  = optional(string, "")
    prefix  = optional(string, "")
  })
  default = {}
}

variable "tags" { type = map(string); default = {} }
