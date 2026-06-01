# ── Required ──────────────────────────────────────────────────────────────────
variable "name"        { type = string }
variable "environment" { type = string }
variable "vpc_id"      { type = string }
variable "subnet_ids"  { type = list(string) }
variable "allowed_security_group_ids" {
  description = "SG IDs được phép kết nối (ECS, Lambda, v.v.)"
  type        = list(string)
}

# ── Engine ────────────────────────────────────────────────────────────────────
variable "engine" {
  type    = string
  default = "redis"
  validation {
    condition     = contains(["redis", "memcached"], var.engine)
    error_message = "engine phải là redis hoặc memcached."
  }
}

variable "engine_version" { type = string; default = "7.1" }
variable "node_type"      { type = string; default = "cache.t4g.micro" }
variable "port"           { type = number; default = 6379 }

# ── Cluster mode (Redis only) ─────────────────────────────────────────────────
variable "cluster_mode" {
  type = object({
    enabled               = optional(bool, false)
    num_node_groups       = optional(number, 1)   # số shard
    replicas_per_node_group = optional(number, 1) # replica mỗi shard
  })
  default = {}
}

# Standalone mode (không dùng cluster)
variable "num_cache_nodes" { type = number; default = 1 }  # memcached hoặc redis single

# ── HA ────────────────────────────────────────────────────────────────────────
variable "automatic_failover_enabled" { type = bool; default = true }
variable "multi_az_enabled"           { type = bool; default = true }

# ── Security ──────────────────────────────────────────────────────────────────
variable "at_rest_encryption_enabled"  { type = bool; default = true }
variable "transit_encryption_enabled"  { type = bool; default = true }

variable "parameter_group_name" { type = string; default = null }

variable "tags" { type = map(string); default = {} }
