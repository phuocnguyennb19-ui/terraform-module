# ECS SERVICE — TASK DEFINITION, SERVICE, AUTOSCALING
#
# Consumes the foundation. subnet_ids, security_group_ids, cluster_arn and
# target_group_arn are inputs; this module has no aws_vpc, no aws_security_group,
# no aws_ecs_cluster and no aws_lb_target_group in it. That separation is what
# lets one ALB and one cluster carry many services instead of each service
# growing its own edge.
#
# Upstream: terraform-aws-modules/ecs/aws v5.11.4, service submodule. It creates
# the task definition, the service, the two IAM roles and the Application Auto
# Scaling target and policies as one unit, because splitting them means hand-
# maintaining the ARN references between them.

locals {
  # ---- Container definitions ---------------------------------------------
  #
  # Nulls are STRIPPED rather than passed through. Upstream resolves each field
  # with try(each.value.<k>, defaults.<k>, <fallback>), and try() catches errors,
  # not nulls — so a key present with a null value overrides the default with
  # null instead of falling through to it. An absent key is what actually
  # inherits container_definition_defaults below.
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

  # ---- Autoscaling policies ----------------------------------------------
  #
  # Built with for-expressions filtered by `if`, not a conditional. Terraform
  # requires both branches of a ternary to unify to one type, and "the default
  # policy map" and "the caller's policy map" never will once they differ in
  # shape by a single attribute.
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

  # ---- Load balancer ------------------------------------------------------
  # An empty map means "no load balancer", which is the correct shape for a
  # worker or a scheduled task.
  load_balancer = var.target_group_arn != null ? {
    default = {
      target_group_arn = var.target_group_arn
      container_name   = var.load_balancer_container_name
      container_port   = var.load_balancer_container_port
    }
  } : {}
}

# ---------------------------------------------------------------------------
# Guards that AWS would otherwise report several minutes into an apply
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# The service
# ---------------------------------------------------------------------------

module "service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.11.4"

  name        = var.name
  cluster_arn = var.cluster_arn

  # ---- Task definition ----------------------------------------------------
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

  # Applied to every container unless that container overrides the key. The two
  # security defaults are here rather than per-container so that turning either
  # off is a visible, per-container decision in the config.
  container_definition_defaults = {
    enable_cloudwatch_logging              = true
    create_cloudwatch_log_group            = true
    cloudwatch_log_group_retention_in_days = var.log_retention_days
    cloudwatch_log_group_kms_key_id        = var.log_kms_key_arn

    # A read-only root filesystem turns "the attacker wrote a binary into the
    # container" into "the attacker could not". A process that needs scratch
    # space gets a mount point, not a writable /.
    readonly_root_filesystem = true

    # Required for `aws ecs execute-command`: without an init process, the
    # session leaves zombie processes behind in the task.
    enable_execute_command = var.enable_execute_command
  }

  volume = var.volumes

  # ---- Placement ----------------------------------------------------------
  launch_type      = length(var.capacity_provider_strategy) > 0 ? null : "FARGATE"
  platform_version = var.platform_version

  capacity_provider_strategy = var.capacity_provider_strategy

  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  # No input for this on purpose. A public IP on a task ENI puts the workload
  # directly on the internet with only the security group between them; egress
  # belongs to the NAT gateway or the VPC endpoints the vpc module creates.
  assign_public_ip = false

  # This module takes its security group from the foundation, so upstream must
  # not create a second one — the created group would carry its own rules,
  # invisible to the tier-to-tier map in modules/security-groups.
  create_security_group = false

  # ---- Rollout ------------------------------------------------------------
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  # Roll back automatically when a deployment cannot reach steady state.
  # Without it, a bad image leaves the service starting and killing tasks
  # indefinitely while the old ones drain.
  deployment_circuit_breaker = var.enable_circuit_breaker ? {
    enable   = true
    rollback = true
  } : {}

  wait_for_steady_state   = var.wait_for_steady_state
  enable_execute_command  = var.enable_execute_command
  enable_ecs_managed_tags = true
  propagate_tags          = var.propagate_tags

  # ---- Load balancer ------------------------------------------------------
  load_balancer                     = local.load_balancer
  health_check_grace_period_seconds = var.target_group_arn != null ? var.health_check_grace_period_seconds : null

  # ---- Autoscaling --------------------------------------------------------
  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity
  autoscaling_policies     = local.autoscaling_policies

  # ---- IAM ----------------------------------------------------------------
  # Execution role: pulls the image, fetches the secrets, writes the logs.
  create_task_exec_iam_role               = var.task_exec_iam_role_arn == null
  create_task_exec_policy                 = var.task_exec_iam_role_arn == null
  task_exec_iam_role_arn                  = var.task_exec_iam_role_arn
  task_exec_iam_role_name                 = "${var.name}-task-exec"
  task_exec_iam_role_use_name_prefix      = false
  task_exec_iam_role_permissions_boundary = var.permissions_boundary_arn
  task_exec_secret_arns                   = var.task_exec_secret_arns
  task_exec_ssm_param_arns                = var.task_exec_ssm_param_arns

  # Task role: the application's own AWS permissions. Empty by default — a
  # workload that needs nothing from AWS should be granted nothing.
  create_tasks_iam_role               = var.tasks_iam_role_arn == null
  tasks_iam_role_arn                  = var.tasks_iam_role_arn
  tasks_iam_role_name                 = "${var.name}-task"
  tasks_iam_role_use_name_prefix      = false
  tasks_iam_role_permissions_boundary = var.permissions_boundary_arn
  tasks_iam_role_policies             = var.tasks_iam_role_policies
  tasks_iam_role_statements           = var.tasks_iam_role_statements

  tags = var.tags
}
