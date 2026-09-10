locals {
  containers = {
    for name, c in var.containers : name => {
      for k, v in {
        name               = name
        image              = c.image
        essential          = c.essential
        cpu                = c.cpu
        memory             = c.memory
        memory_reservation = c.memory_reservation

        command           = length(coalesce(c.command, [])) > 0 ? c.command : null
        entrypoint        = length(coalesce(c.entrypoint, [])) > 0 ? c.entrypoint : null
        working_directory = c.working_dir

        port_mappings = c.port_mappings
        environment   = c.environment
        secrets       = length(c.secrets) > 0 ? c.secrets : null

        health_check = c.health_check != null ? {
          command     = c.health_check.command
          interval    = c.health_check.interval
          timeout     = c.health_check.timeout
          retries     = c.health_check.retries
          startPeriod = c.health_check.startPeriod
        } : null

        mount_points = length(c.mount_points) > 0 ? c.mount_points : null
        dependencies = length(c.depends_on) > 0 ? c.depends_on : null
        ulimits      = length(c.ulimits) > 0 ? c.ulimits : null

        readonly_root_filesystem = c.readonly_root_filesystem
        user                     = c.user
        stop_timeout             = c.stop_timeout
      } : k => v if v != null
    }
  }

  target_tracking = {
    cpu    = { metric = "ECSServiceAverageCPUUtilization", target = var.autoscaling_cpu_target }
    memory = { metric = "ECSServiceAverageMemoryUtilization", target = var.autoscaling_memory_target }
  }

  default_autoscaling_policies = {
    for k, p in local.target_tracking : k => {
      policy_type = "TargetTrackingScaling"

      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = p.metric
        }
        target_value       = p.target
        scale_in_cooldown  = var.autoscaling_scale_in_cooldown
        scale_out_cooldown = var.autoscaling_scale_out_cooldown
      }
    } if p.target != null
  }

  autoscaling_policies = merge(local.default_autoscaling_policies, var.autoscaling_policies_extra)

  load_balancer = var.target_group_arn != null ? {
    default = {
      target_group_arn = var.target_group_arn
      container_name   = var.load_balancer_container_name
      container_port   = var.load_balancer_container_port
    }
  } : {}
}

resource "terraform_data" "load_balancer_wiring" {
  count = var.target_group_arn != null ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.load_balancer_container_name != null && var.load_balancer_container_port != null
      error_message = "target_group_arn is set, so load_balancer_container_name and load_balancer_container_port are both required."
    }

    precondition {
      condition     = contains(keys(var.containers), coalesce(var.load_balancer_container_name, ""))
      error_message = "load_balancer_container_name must be one of the keys in containers."
    }

    precondition {
      condition = anytrue([
        for m in var.containers[coalesce(var.load_balancer_container_name, keys(var.containers)[0])].port_mappings :
        m.containerPort == var.load_balancer_container_port
      ])
      error_message = "load_balancer_container_port must appear in that container's port_mappings, or the target group has nothing to register."
    }
  }
}

resource "terraform_data" "autoscaling_floor" {
  count = var.enable_autoscaling ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.autoscaling_max_capacity >= var.autoscaling_min_capacity
      error_message = "autoscaling_max_capacity must be greater than or equal to autoscaling_min_capacity."
    }
  }
}

module "service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.11.4"

  name        = var.name
  cluster_arn = var.cluster_arn

  create_task_definition   = true
  family                   = var.name
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  runtime_platform = {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  ephemeral_storage = var.ephemeral_storage_gb != null ? { size_in_gib = var.ephemeral_storage_gb } : {}

  container_definitions = local.containers

  container_definition_defaults = {
    enable_cloudwatch_logging              = true
    create_cloudwatch_log_group            = true
    cloudwatch_log_group_retention_in_days = var.log_retention_days
    cloudwatch_log_group_kms_key_id        = var.log_kms_key_arn

    readonly_root_filesystem = true

    enable_execute_command = var.enable_execute_command
  }

  volume = var.volumes

  launch_type      = length(var.capacity_provider_strategy) > 0 ? null : "FARGATE"
  platform_version = var.platform_version

  capacity_provider_strategy = var.capacity_provider_strategy

  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  assign_public_ip = false

  create_security_group = false

  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  deployment_circuit_breaker = var.enable_circuit_breaker ? {
    enable   = true
    rollback = true
  } : {}

  wait_for_steady_state   = var.wait_for_steady_state
  enable_execute_command  = var.enable_execute_command
  enable_ecs_managed_tags = true
  propagate_tags          = var.propagate_tags

  load_balancer                     = local.load_balancer
  health_check_grace_period_seconds = var.target_group_arn != null ? var.health_check_grace_period_seconds : null

  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity
  autoscaling_policies     = local.autoscaling_policies

  create_task_exec_iam_role               = var.task_exec_iam_role_arn == null
  create_task_exec_policy                 = var.task_exec_iam_role_arn == null
  task_exec_iam_role_arn                  = var.task_exec_iam_role_arn
  task_exec_iam_role_name                 = "${var.name}-task-exec"
  task_exec_iam_role_use_name_prefix      = false
  task_exec_iam_role_permissions_boundary = var.permissions_boundary_arn
  task_exec_secret_arns                   = var.task_exec_secret_arns
  task_exec_ssm_param_arns                = var.task_exec_ssm_param_arns

  create_tasks_iam_role               = var.tasks_iam_role_arn == null
  tasks_iam_role_arn                  = var.tasks_iam_role_arn
  tasks_iam_role_name                 = "${var.name}-task"
  tasks_iam_role_use_name_prefix      = false
  tasks_iam_role_permissions_boundary = var.permissions_boundary_arn
  tasks_iam_role_policies             = var.tasks_iam_role_policies
  tasks_iam_role_statements           = var.tasks_iam_role_statements

  tags = var.tags
}
