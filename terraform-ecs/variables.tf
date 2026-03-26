# General Configuration
variable "env" {
  description = "Deployment environment"
  type        = string
}

variable "service" {
  description = "Service name"
  type        = string
}

variable "source_code" {
  description = "Source code repository name"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
}

# ECS Task Configuration
variable "task_cpu" {
  description = "CPU allocation for tasks per environment"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory allocation for tasks per environment"
  type        = number
  default     = 512
}

# Logging Configuration
variable "enable_logging" {
  description = "Enable logging configuration"
  type        = bool
  default     = true
}

variable "enable_fluent_bit" {
  description = "Enable Fluent Bit logging"
  type        = bool
  default     = true
}

variable "fluentbit_version" {
  description = "Fluent Bit version per environment"
  type        = string
  default = "7.1"
}
# Otel

variable "aws-otel-collector" {
  description = "Version Image for the AWS OpenTelemetry Collector container."
  type        = string
  default     = "aws-otel-collector"
}

variable "otel_version" {
  description = "Version Image for the AWS OpenTelemetry Collector container."
  type        = string
  default     = "v0.41.2"
}

variable "otel_cpu" {
  description = "CPU units to allocate to the AWS OpenTelemetry Collector container."
  type        = number
  default     = null
}

variable "otel_memory" {
  description = "Memory (in MiB) to allocate to the AWS OpenTelemetry Collector container."
  type        = number
  default     = 40
}

variable "otel_user" {
  description = "User ID to run the AWS OpenTelemetry Collector container as."
  type        = string
  default     = null
}

variable "otel_command" {
  description = "Command to execute in the AWS OpenTelemetry Collector container."
  type        = list(string)
  default     = []
}

variable "php_links" {
  description = "The links parameter allows containers to communicate without port mappings, only supported in `bridge` network mode."
  type        = list(string)
  default     = ["aws-otel-collector"]
}

variable "otel_mount_points" {
  description = "List of mount points for volumes attached to the AWS OpenTelemetry Collector container."
  type        = list(object({
    sourceVolume  = string
    containerPath = string
    readOnly      = bool
  }))
  default     = []
}

variable "otel_env_public" {
  description = "List of public environment variables for the AWS OpenTelemetry Collector container."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "otel_env_secret" {
  description = "List of secret environment variables for the AWS OpenTelemetry Collector container."
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = [
    {
      name      = "AOT_CONFIG_CONTENT"
      valueFrom = "arn:aws:ssm:ap-southeast-1:account_id:parameter/otel-collector-config-default"
    }
  ]
}

variable "health_check" {
  description = "The container health check command and associated configuration parameters."
  type        = any
  default     = {
    command     = ["/healthcheck"]
    interval    = 5
    timeout     = 6
    retries     = 5
    startPeriod = 1
  }
}

# IAM Policies
variable "iam_policies" {
  description = "List of IAM policies to attach"
  type        = list(string)
  default     = ["AmazonECSTask_GeneralPolicy", "s3_gotit-general-cdn-dev_rwObject"]
}

# Networking Configuration
variable "enable_load_balancer" {
  description = "Enable load balancer integration"
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
  default     = ["sg-xyz789"]
}

# Port Configuration
variable "containerPort" {
  description = "List of container ports to expose"
  type        = list(number)
  default     = [443]
}

variable "hostPort" {
  description = "Host port to bind the container port"
  type        = number
  default     = 443
}

variable "protocol" {
  description = "Protocol to use for the port mapping"
  type        = string
  default     = "tcp"
}

# ECS Service Configuration
variable "requires_compatibilities" {
  description = "ECS launch type"
  type        = list(string)
  default     = ["FARGATE"]
}

variable "create_service" {
  description = "Flag to create ECS service"
  type        = bool
  default     = true
}

variable "enable_autoscaling" {
  description = "Enable autoscaling for the ECS service"
  type        = bool
  default     = false
}

# Environment Variables
variable "env_public" {
  description = "Environment variables for containers in JSON format"
  type        = string
  default     = ""
}

variable "env_secret" {
  description = "Path to JSON file containing secret environment variables"
  type        = string
  default     = ""
}

variable "environment_nginx" {
  description = "Environment variables for Nginx container"
  type        = map(string)
  default     = {}
}

variable "env_nginx_secret" {
  description = "Secret environment variables for Nginx container"
  type        = map(string)
  default     = {}
}

# Tags Configuration
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

#  Listener ARN
variable "listener_arn_test" {
  type = map(string)
  default = {
    8989 = "listener_id"
    9090 = "listener_id"
    443 = "listener_id"
    9898 = "listener_id"
    9000 = "listener_id"
    4318 = "listener_id"
    80 = "listener_id"
  }
}

variable "listener_arn_stg" {
  type = map(string)
  default = {
    8069 = "listener_id"
    9090 = "listener_id"
    443 = "listener_id"
    9898 = "listener_id"
    9000 = "listener_id"
    8989 = "listener_id"
    80 = "listener_id"
  }
}

variable "listener_arn_stg_private" {
  type = map(string)
  default = {
    5000 = "listener_id"
    8001 = "listener_id"
    5001 = "listener_id"
    80 = "listener_id"
    9090 = "listener_id"
    443 = "listener_id"
  }
}

variable "listener_arn_bmk" {
  type = map(string)
  default = {
    5001 = "listener_id"
    9000 = "listener_id"
    9090 = "listener_id"
    9898 = "listener_id"
    5000 = "listener_id"
    80 = "listener_id"
    443 = "listener_id"
    8989 = "listener_id"
  }
}