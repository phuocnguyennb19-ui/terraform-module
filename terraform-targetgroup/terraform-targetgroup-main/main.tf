provider "aws" {
  region = "ap-southeast-1"
}

module "example_lb_target_group" {
  source = "/home/phuocnguyen.nguyen/lb_v1/module"

  name                          = "example-tg"
  port                          = 80
  protocol                      = "HTTP"
  vpc_id                        = "vpc-12345678"
  target_type                   = "instance"
  health_check_path             = "/health"
  health_check_protocol         = "HTTP"
  connection_termination        = true
}