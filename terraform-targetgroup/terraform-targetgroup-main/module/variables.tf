variable "name" {
  description = "The name of the target group"
  type        = string

}

variable "port" {
  description = "The port on which targets receive traffic"
  type        = number
}

variable "protocol" {
  description = "The protocol to use for routing traffic to the targets"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "target_type" {
  description = "The type of target that you must specify when registering targets with this target group"
  type        = string
  default     = "instance"
}

variable "health_check_interval" {
  description = "The interval between health checks"
  type        = number
  default     = 30
}

variable "health_check_path" {
  description = "The destination for the health check request"
  type        = string
  default     = "/"
}

variable "health_check_port" {
  description = "The port for health check"
  type        = string
  default     = "traffic-port"
}

variable "health_check_protocol" {
  description = "The protocol for health check"
  type        = string
  default     = "HTTP"
}

variable "health_check_timeout" {
  description = "The timeout for health check"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "The number of healthy health checks before considering the target healthy"
  type        = number
  default     = 5
}

variable "health_check_unhealthy_threshold" {
  description = "The number of unhealthy health checks before considering the target unhealthy"
  type        = number
  default     = 2
}

#variable "stickiness_type" {
#  description = "The type of stickiness"
#  type        = string
#  default     = "lb_cookie"
#}
#
#variable "stickiness_cookie_duration" {
#  description = "The duration of the cookie for stickiness"
#  type        = number
#  default     = 86400
#}

variable "matcher_http_code" {
  description = "The HTTP codes to use when checking for a successful response from a target"
  type        = string
  default     = "200,202"
}

variable "deregistration_delay" {
  description = "The amount of time for Elastic Load Balancing to wait before changing the state of a deregistering target"
  type        = number
  default     = 300
}

variable "slow_start" {
  description = "The time period during which the load balancer sends a newly registered target a linearly increasing share of the traffic"
  type        = number
  default     = 0
}

variable "connection_termination" {
  description = "Indicates whether the load balancer terminates connections at the end of the deregistration delay timeout"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}