# Target Group (native resource — avoids ALB module version dependency)
resource "aws_lb_target_group" "app" {
  count = lookup(local.service_cfg.load_balancer, "container_name", "") != "" ? 1 : 0

  name_prefix = "h-"
  protocol    = "HTTP"
  port        = lookup(local.service_cfg.load_balancer, "container_port", 80)
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = local.service_cfg.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = local.service_cfg.health_check_matcher
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

# Listener Rule on existing ALB listener
resource "aws_lb_listener_rule" "app" {
  count = lookup(local.service_cfg.load_balancer, "container_name", "") != "" && var.listener_arn != null ? 1 : 0

  listener_arn = var.listener_arn
  priority     = local.service_cfg.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }

  condition {
    host_header {
      values = [local.service_cfg.host_header != null ? local.service_cfg.host_header : "${local.app_name}.${local.env}.internal"]
    }
  }

  tags = local.tags
}

# --- ECS Service ---
module "ecs_service" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ecs.git//modules/service?ref=v5.11.4"

  name        = local.name_prefix
  cluster_arn = var.cluster_arn

  # Task Level Configuration
  cpu                      = local.task_cfg.cpu
  memory                   = local.task_cfg.memory
  network_mode             = local.task_cfg.network_mode
  requires_compatibilities = local.task_cfg.requires_compatibilities

  task_exec_iam_role_arn = local.task_cfg.execution_role_arn
  tasks_iam_role_arn     = local.task_cfg.task_role_arn

  # Container Definitions
  container_definitions = local.containers

  # Volumes
  volume = local.task_cfg.volumes

  # Service Level Configuration
  desired_count                      = local.service_cfg.desired_count
  deployment_maximum_percent         = local.service_cfg.deployment_maximum_percent
  deployment_minimum_healthy_percent = local.service_cfg.deployment_minimum_healthy_percent

  # Network
  subnet_ids         = local.service_cfg.subnet_ids != null ? local.service_cfg.subnet_ids : var.private_subnets
  security_group_ids = local.service_cfg.security_group_ids != null ? local.service_cfg.security_group_ids : null

  # Create security-group rules automatically when security_group_ids is not supplied
  create_security_group = local.service_cfg.security_group_ids == null
  security_group_rules  = local.ecs_sg_rules

  # Load Balancer Attachment
  load_balancer = lookup(local.service_cfg.load_balancer, "container_name", "") != "" && length(aws_lb_target_group.app) > 0 ? {
    service = {
      target_group_arn = aws_lb_target_group.app[0].arn
      container_name   = local.service_cfg.load_balancer.container_name
      container_port   = local.service_cfg.load_balancer.container_port
    }
  } : {}

  # Runtime & Deployment Configuration
  health_check_grace_period_seconds = local.service_cfg.health_check_grace_period
  enable_execute_command            = local.service_cfg.enable_execute_command
  force_new_deployment              = local.service_cfg.force_new_deployment

  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }

  propagate_tags = local.service_cfg.propagate_tags

  # Integrated autoscaling
  enable_autoscaling       = local.autoscaling_cfg.enabled
  autoscaling_min_capacity = local.autoscaling_cfg.min_capacity
  autoscaling_max_capacity = local.autoscaling_cfg.max_capacity
  autoscaling_policies     = local.autoscaling_policies

  tags = local.tags
}
