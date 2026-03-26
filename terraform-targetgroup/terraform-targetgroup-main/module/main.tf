resource "aws_lb_target_group" "this" {
  name     = var.name
  port     = var.port
  protocol = var.protocol
  vpc_id   = var.vpc_id
  target_type = var.target_type

  health_check {
    interval            = var.health_check_interval
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

#  stickiness {
#    type            = var.stickiness_type
#    cookie_duration = var.stickiness_cookie_duration
#  }

#   matcher {
#     http_code = var.matcher_http_code
#   }

  deregistration_delay   = var.deregistration_delay
  slow_start             = var.slow_start
  connection_termination = var.connection_termination

  tags = var.tags
}

