locals {

  # 2. Local Module Config (Support dynamic config file name)
  config_local = merge(
    try(yamldecode(file("${path.cwd}/${var.config_file}")), {}),
    var.manual_config
  )

  # 3. Context & Naming (Strict mapping from config.yml)
  env          = lookup(var.global_config, "environment", "dev")
  region       = lookup(var.global_config, "region", "ap-southeast-1")
  project      = lookup(var.global_config, "project", "core")
  app_name     = lookup(local.config_local, "app_name", null)
  service_type = lookup(local.config_local, "service_type", "infra")
  name_prefix  = join("-", compact([local.env, local.app_name == "base" ? null : local.app_name, local.service_type]))

  # 4. Smart Mapping for service
  raw_service_cfg = merge(
    try(local.config_local.service, {}),
    try(local.config_local.ecs_service, {})
  )

  # 4. Task Definition Mapping.
  #
  # NOTE the precedence: merge() lets the SECOND argument win, so a root-level
  # `task_definition:` OVERRIDES `service.task_definition`. That is the opposite
  # of container_definitions and volumes below, which prefer the nested copy.
  # The behaviour is left as-is because changing it would silently move config
  # for anyone relying on it; the inconsistency is documented instead.
  raw_task_cfg = merge(
    try(local.raw_service_cfg.task_definition, {}),
    try(local.config_local.task_definition, {})
  )
  task_cfg = {
    family                   = try(local.raw_task_cfg.family, "${local.name_prefix}-task")
    network_mode             = try(local.raw_task_cfg.network_mode, "awsvpc")
    requires_compatibilities = try(local.raw_task_cfg.requires_compatibilities, ["FARGATE"])
    cpu                      = try(local.raw_task_cfg.cpu, try(local.raw_service_cfg.cpu, 256))
    memory                   = try(local.raw_task_cfg.memory, try(local.raw_service_cfg.memory, 512))
    execution_role_arn       = try(local.raw_task_cfg.execution_role_arn, null)
    task_role_arn            = try(local.raw_task_cfg.task_role_arn, null)
    volumes                  = try(local.raw_service_cfg.volumes, try(local.config_local.volumes, []))
  }

  # 5. Container Definitions Mapping (Prefer nested, fallback to root)
  containers_raw = lookup(local.raw_service_cfg, "container_definitions", lookup(local.config_local, "container_definitions", [
    {
      name      = "app"
      image     = lookup(local.raw_service_cfg, "image", lookup(local.config_local, "image", null))
      essential = true
      port_mappings = [
        {
          container_port = lookup(local.raw_service_cfg, "port", lookup(local.config_local, "port", null))
          host_port      = lookup(local.raw_service_cfg, "port", lookup(local.config_local, "port", null))
          protocol       = "tcp"
        }
      ]
    }
  ]))

  # Normalize container definitions for the module
  containers = {
    for c in local.containers_raw : c.name => {
      image     = c.image
      essential = try(c.essential, true)
      cpu       = try(c.cpu, null)
      memory    = try(c.memory, null)
      command   = try(c.command, [])

      port_mappings = [
        for p in try(c.port_mappings, []) : {
          containerPort = p.container_port
          hostPort      = lookup(p, "host_port", p.container_port)
          protocol      = lookup(p, "protocol", "tcp")
        }
      ]

      environment = [
        for k, v in try(c.environment, {}) : {
          name  = k
          value = tostring(v)
        }
      ]

      secrets = [
        for k, v in try(c.secrets, {}) : {
          name      = k
          valueFrom = v
        }
      ]

      log_configuration = lookup(c, "log_configuration", {
        log_driver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${local.name_prefix}"
          awslogs-region        = local.region
          awslogs-stream-prefix = c.name
        }
      })

      mount_points = lookup(c, "mount_points", [])
      depends_on   = lookup(c, "depends_on", [])
    }
  }

  # 6. Service Configuration Mapping
  service_cfg = {
    desired_count                      = try(local.raw_service_cfg.desired_count, 1)
    deployment_maximum_percent         = try(local.raw_service_cfg.deployment_maximum_percent, 200)
    deployment_minimum_healthy_percent = try(local.raw_service_cfg.deployment_minimum_healthy_percent, 100)

    # LB Mapping
    load_balancer = try(local.raw_service_cfg.load_balancer, {
      container_name = "app"
      container_port = try(local.raw_service_cfg.port, try(local.config_local.port, null))
    })

    # Health check
    health_check_path    = try(local.raw_service_cfg.health_check_path, "/")
    health_check_matcher = try(local.raw_service_cfg.health_check_matcher, "200")

    # Listener Rule
    priority    = try(local.raw_service_cfg.priority, null)
    host_header = try(local.raw_service_cfg.host_header, null)

    # Deployment & Runtime
    health_check_grace_period  = try(local.raw_service_cfg.health_check_grace_period, 30)
    enable_execute_command     = try(local.raw_service_cfg.enable_execute_command, false)
    force_new_deployment       = try(local.raw_service_cfg.force_new_deployment, false)
    deployment_controller_type = try(local.raw_service_cfg.deployment_controller_type, "ECS")
    propagate_tags             = try(local.raw_service_cfg.propagate_tags, "SERVICE")
    platform_version           = try(local.raw_service_cfg.platform_version, "LATEST")
    scheduling_strategy        = try(local.raw_service_cfg.scheduling_strategy, "REPLICA")
    wait_for_steady_state      = try(local.raw_service_cfg.wait_for_steady_state, false)
    assign_public_ip           = try(local.raw_service_cfg.assign_public_ip, false)

    # Capacity provider (optional — override default FARGATE strategy)
    capacity_provider_strategy = try(local.raw_service_cfg.capacity_provider_strategy, [])

    # Network
    subnet_ids         = lookup(lookup(try(local.raw_service_cfg.network_configuration.awsvpc_configuration, {}), "subnets", {}), "subnets", null)
    security_group_ids = lookup(lookup(try(local.raw_service_cfg.network_configuration.awsvpc_configuration, {}), "security_groups", {}), "security_groups", null)
  }

  # 7. AutoScaling Mapping
  raw_autoscaling_cfg = try(local.config_local.autoscaling, {})
  autoscaling_cfg = {
    enabled                   = lookup(local.raw_autoscaling_cfg, "enabled", false)
    min_capacity              = lookup(local.raw_autoscaling_cfg, "min_capacity", 1)
    max_capacity              = lookup(local.raw_autoscaling_cfg, "max_capacity", 3)
    target_cpu_utilization    = lookup(local.raw_autoscaling_cfg, "target_cpu_utilization", 0)
    target_memory_utilization = lookup(local.raw_autoscaling_cfg, "target_memory_utilization", 0)
  }

  autoscaling_policies = merge(
    local.autoscaling_cfg.target_cpu_utilization > 0 ? {
      cpu = {
        policy_type = "TargetTrackingScaling"
        target_tracking_scaling_policy_configuration = {
          predefined_metric_specification = {
            predefined_metric_type = "ECSServiceAverageCPUUtilization"
          }
          target_value = local.autoscaling_cfg.target_cpu_utilization
        }
      }
    } : {},
    local.autoscaling_cfg.target_memory_utilization > 0 ? {
      memory = {
        policy_type = "TargetTrackingScaling"
        target_tracking_scaling_policy_configuration = {
          predefined_metric_specification = {
            predefined_metric_type = "ECSServiceAverageMemoryUtilization"
          }
          target_value = local.autoscaling_cfg.target_memory_utilization
        }
      }
    } : {}
  )

  # 8. Security Group Rules — egress restricted to VPC CIDR only
  ecs_sg_rules = {
    for k, v in {
      alb_ingress = {
        type        = "ingress"
        from_port   = lookup(local.service_cfg.load_balancer, "container_port", 80)
        to_port     = lookup(local.service_cfg.load_balancer, "container_port", 80)
        protocol    = "tcp"
        description = "Allow inbound traffic from ALB within VPC"
        cidr_blocks = [var.vpc_cidr_block]
      }
      egress_vpc = {
        type        = "egress"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        description = "Allow all egress within VPC"
        cidr_blocks = [var.vpc_cidr_block]
      }
      egress_https = {
        type        = "egress"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        description = "Allow HTTPS to internet (AWS APIs, ECR, Secrets Manager)"
        cidr_blocks = ["0.0.0.0/0"]
      }
    } : k => v if local.service_cfg.security_group_ids == null
  }

  # 9. Global Alias & Tags
  config = local.config_local
  tags = merge(
    {
      Environment = local.env,
      Project     = local.project,
      ManagedBy   = lookup(var.global_config, "managed_by", "DylanDevOps"),
      CostCenter  = lookup(var.global_config, "cost_center", "shared-services"),
      Terraform   = "true"
    },
    var.tags,
    try(var.global_config.tags, {})
  )
}
