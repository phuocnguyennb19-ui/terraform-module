# =============================================================================
# ECS SERVICE MODULE — ORCHESTRATION MODE
# Nhận toàn bộ thông tin từ Master Engine qua variables.
# Không phụ thuộc vào Remote State.
# =============================================================================

# --- Target Group ---
resource "aws_lb_target_group" "this" {
  count = try(local.service_config.lb_type, "") != "none" && try(local.service_config.lb_type, "") != "" ? 1 : 0

  name        = "${local.name_prefix}-tg"
  port        = try(local.service_config.port, 80)
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = try(local.service_config.health_check_path, "/")
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = local.tags
}

# --- Listener Rule (Auto-attachment to ALB) ---
resource "aws_lb_listener_rule" "this" {
  count = try(local.service_config.lb_type, "") == "alb" ? 1 : 0

  listener_arn = var.listener_arn
  priority     = try(local.service_config.priority, 100)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  condition {
    host_header {
      values = [try(local.service_config.host_header, "${local.app_name}.${local.env}.internal")]
    }
  }
}

# --- ECS Service ---
module "service" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ecs.git//modules/service?ref=v5.11.2"

  name        = local.name_prefix
  cluster_arn = var.cluster_arn

  cpu    = try(local.service_config.cpu, 256)
  memory = try(local.service_config.memory, 512)

  desired_count                      = try(local.service_config.desired_count, 1)
  deployment_maximum_percent         = try(local.service_config.deployment_maximum_percent, 200)
  deployment_minimum_healthy_percent = try(local.service_config.deployment_minimum_healthy_percent, 100)

  container_definitions = {
    app = {
      image     = try(local.service_config.image, "nginx:latest")
      essential = true
      port_mappings = [
        {
          containerPort = try(local.service_config.port, 80)
          hostPort      = try(local.service_config.port, 80)
          protocol      = "tcp"
        }
      ]
    }
  }

  # Network — nhận từ orchestrator
  subnet_ids = var.private_subnets

  security_group_rules = {
    alb_ingress = {
      type        = "ingress"
      from_port   = try(local.service_config.port, 80)
      to_port     = try(local.service_config.port, 80)
      protocol    = "tcp"
      description = "Allow traffic from ALB"
      cidr_blocks = [try(var.vpc_cidr_block, "10.0.0.0/16")]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Load Balancer Attachment
  load_balancer = length(aws_lb_target_group.this) > 0 ? {
    service = {
      target_group_arn = aws_lb_target_group.this[0].arn
      container_name   = "app"
      container_port   = try(local.service_config.port, 80)
    }
  } : {}

  tags = local.tags
}
