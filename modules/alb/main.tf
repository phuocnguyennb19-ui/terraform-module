# Fix 8: Tạo Security Group riêng cho ALB thay vì dùng []
resource "aws_security_group" "alb" {
  name_prefix = "${local.alb_config.name}-"
  description = "Security group for ALB ${local.alb_config.name}"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.alb_config.name}-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

module "alb" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-alb.git?ref=v8.7.0"

  name               = local.alb_config.name
  load_balancer_type = "application"
  internal           = try(local.alb_config.internal, false)
  idle_timeout       = try(local.alb_config.idle_timeout, 60)

  # Fix 1: Chỉ dùng variables, không fallback Remote State
  vpc_id  = var.vpc_id
  subnets = var.public_subnets

  # Fix 8: Dùng security group thật thay vì []
  security_groups = [aws_security_group.alb.id]

  enable_deletion_protection = try(local.alb_config.enable_deletion_protection, false)

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      action_type        = "forward"
      target_group_index = 0
    }
  ]

  target_groups = [
    {
      name_prefix      = "h"
      backend_protocol = "HTTP"
      backend_port     = try(local.alb_config.backend_port, 80)
      target_type      = "ip"
      health_check = {
        enabled             = true
        path                = try(local.alb_config.health_check_path, "/")
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 5
        interval            = 30
        matcher             = "200"
      }
    }
  ]

  tags = local.tags
}
