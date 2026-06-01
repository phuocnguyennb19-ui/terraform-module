data "aws_region" "current" {}

locals {
  cluster_capacity_providers = {
    FARGATE      = ["FARGATE"]
    FARGATE_SPOT = ["FARGATE_SPOT"]
    MIXED        = ["FARGATE", "FARGATE_SPOT"]
    EC2          = keys(var.asg_capacity_providers)
  }

  default_capacity_provider_strategy = {
    FARGATE = {
      FARGATE = { weight = 100, base = 1 }
    }
    FARGATE_SPOT = {
      FARGATE_SPOT = { weight = 100, base = 0 }
    }
    MIXED = {
      FARGATE      = { weight = 30, base = 1 }
      FARGATE_SPOT = { weight = 70, base = 0 }
    }
    EC2 = {}
  }

  service_capacity_provider_strategy = {
    for name, cfg in var.asg_capacity_providers :
    name => { weight = cfg.weight, base = cfg.base }
  }
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"

  create       = var.create
  cluster_name = "${var.app_name}-${var.environment}"

  # FIX: cluster_setting (singular) = list(object), NOT map(string)
  cluster_setting = [{ name = "containerInsights", value = var.container_insights ? "enabled" : "disabled" }]

  # Cluster-level create_*
  create_cloudwatch_log_group          = var.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = var.log_retention_days
  create_task_exec_iam_role            = false  # managed per-service, not cluster-wide
  create_task_exec_policy              = false

  # Capacity providers
  cluster_capacity_providers         = local.cluster_capacity_providers[var.capacity_type]
  default_capacity_provider_strategy = local.default_capacity_provider_strategy[var.capacity_type]

  capacity_providers = var.capacity_type == "EC2" ? {
    for name, cfg in var.asg_capacity_providers : name => {
      auto_scaling_group_provider = {
        auto_scaling_group_arn         = cfg.asg_arn
        managed_draining               = "ENABLED"
        managed_termination_protection = "ENABLED"
        managed_scaling = {
          status                    = "ENABLED"
          target_capacity           = cfg.target_capacity
          minimum_scaling_step_size = 1
          maximum_scaling_step_size = 5
        }
      }
    }
  } : {}

  services = {
    "${var.app_name}" = {
      # Service-level create_*
      create                 = var.create_service
      create_iam_role        = var.create_iam_role
      create_task_definition = var.create_task_definition
      create_tasks_iam_role  = var.create_tasks_iam_role
      create_security_group  = var.create_security_group

      # Service-level task exec IAM (default true — each service manages own role)
      create_task_exec_iam_role = var.create_task_exec_iam_role
      create_task_exec_policy   = var.create_task_exec_policy

      cpu    = var.cpu
      memory = var.memory

      # Capacity — null launch_type khi dùng capacity providers
      launch_type = null
      capacity_provider_strategy = var.capacity_type == "EC2" ? local.service_capacity_provider_strategy : null

      container_definitions = {
        "${var.app_name}" = {
          image     = var.container_image
          cpu       = var.cpu
          memory    = var.memory
          essential = true

          readonly_root_filesystem = var.readonly_root_filesystem

          port_mappings = [{
            name          = var.app_name
            containerPort = var.container_port
            protocol      = "tcp"
          }]

          environment = [for k, v in var.environment_vars : { name = k, value = v }]

          secrets = [for k, v in var.secrets_vars : { name = k, valueFrom = v }]

          log_configuration = {
            logDriver = "awslogs"
            options = {
              "awslogs-group"         = "/ecs/${var.app_name}-${var.environment}"
              "awslogs-region"        = data.aws_region.current.name
              "awslogs-stream-prefix" = "ecs"
              "awslogs-create-group"  = "true"
            }
          }
        }
      }

      load_balancer = {
        service = {
          target_group_arn = var.alb_target_group_arn
          container_name   = var.app_name
          container_port   = var.container_port
        }
      }

      vpc_id           = var.vpc_id
      subnet_ids       = var.private_subnets
      assign_public_ip = false

      security_group_ingress_rules = {
        alb_ingress = {
          description                  = "Allow traffic from ALB"
          from_port                    = var.container_port
          to_port                      = var.container_port
          ip_protocol                  = "tcp"
          referenced_security_group_id = var.alb_security_group_id
        }
      }

      security_group_egress_rules = {
        all = { ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
      }

      desired_count        = var.desired_count
      force_new_deployment = var.force_new_deployment

      deployment_circuit_breaker = {
        enable   = true
        rollback = true
      }

      deployment_maximum_percent         = var.deployment_maximum_percent
      deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
      health_check_grace_period_seconds  = var.health_check_grace_period_seconds
      enable_execute_command             = var.enable_execute_command

      autoscaling_min_capacity = var.autoscaling_min_capacity
      autoscaling_max_capacity = var.autoscaling_max_capacity

      autoscaling_policies = {
        cpu = {
          policy_type = "TargetTrackingScaling"
          target_tracking_scaling_policy_configuration = {
            predefined_metric_specification = { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
            target_value       = var.autoscaling_cpu_target
            scale_in_cooldown  = var.scale_in_cooldown
            scale_out_cooldown = var.scale_out_cooldown
          }
        }
        memory = {
          policy_type = "TargetTrackingScaling"
          target_tracking_scaling_policy_configuration = {
            predefined_metric_specification = { predefined_metric_type = "ECSServiceAverageMemoryUtilization" }
            target_value       = var.autoscaling_memory_target
            scale_in_cooldown  = var.scale_in_cooldown
            scale_out_cooldown = var.scale_out_cooldown
          }
        }
      }

      tags = var.tags
    }
  }

  tags = var.tags
}
