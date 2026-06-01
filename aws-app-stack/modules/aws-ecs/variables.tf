# ── Required ──────────────────────────────────────────────────────────────────
variable "app_name"    { type = string }
variable "environment" { type = string }
variable "vpc_id"      { type = string }
variable "private_subnets"       { type = list(string) }
variable "alb_target_group_arn"  { type = string }
variable "alb_security_group_id" { type = string }
variable "container_image"       { type = string }

# ── Capacity ──────────────────────────────────────────────────────────────────
variable "capacity_type" {
  type    = string
  default = "FARGATE"
  validation {
    condition     = contains(["FARGATE", "FARGATE_SPOT", "MIXED", "EC2"], var.capacity_type)
    error_message = "Must be FARGATE, FARGATE_SPOT, MIXED, or EC2."
  }
}

variable "asg_capacity_providers" {
  type = map(object({
    asg_arn         = string
    weight          = number
    base            = number
    target_capacity = number
  }))
  default = {}
}

# ── Cluster create_* ──────────────────────────────────────────────────────────
variable "create"                      { type = bool; default = true }
variable "create_cloudwatch_log_group" { type = bool; default = true }
variable "log_retention_days"          { type = number; default = 90 }
variable "container_insights"          { type = bool; default = true }

# ── Service create_* ──────────────────────────────────────────────────────────
variable "create_service"         { type = bool; default = true }
variable "create_task_definition" { type = bool; default = true }
variable "create_iam_role"        { type = bool; default = true }
variable "create_tasks_iam_role"  { type = bool; default = true }
variable "create_security_group"  { type = bool; default = true }
variable "create_task_exec_iam_role" { type = bool; default = true }
variable "create_task_exec_policy"   { type = bool; default = true }

# ── Container ─────────────────────────────────────────────────────────────────
variable "container_port"           { type = number; default = 8080 }
variable "cpu"                      { type = number; default = 256 }
variable "memory"                   { type = number; default = 512 }
variable "desired_count"            { type = number; default = 2 }
variable "readonly_root_filesystem" { type = bool;   default = false }

variable "environment_vars" {
  type    = map(string)
  default = {}
}

variable "secrets_vars" {
  description = "Map of env var name → SSM/Secrets Manager ARN"
  type        = map(string)
  default     = {}
}

# ── Deployment ────────────────────────────────────────────────────────────────
variable "force_new_deployment"              { type = bool;   default = true }
variable "health_check_grace_period_seconds" { type = number; default = 60 }
variable "enable_execute_command"            { type = bool;   default = false }
variable "deployment_maximum_percent"        { type = number; default = 200 }
variable "deployment_minimum_healthy_percent"{ type = number; default = 66 }

# ── Autoscaling ───────────────────────────────────────────────────────────────
variable "autoscaling_min_capacity"  { type = number; default = 1 }
variable "autoscaling_max_capacity"  { type = number; default = 10 }
variable "autoscaling_cpu_target"    { type = number; default = 70 }
variable "autoscaling_memory_target" { type = number; default = 80 }
variable "scale_in_cooldown"         { type = number; default = 300 }
variable "scale_out_cooldown"        { type = number; default = 60 }

variable "tags" { type = map(string); default = {} }
