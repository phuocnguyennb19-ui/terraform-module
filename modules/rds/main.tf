
# Security Group cho RDS
resource "aws_security_group" "rds" {
  name_prefix = "${local.name_prefix}-rds-"
  description = "Security group for RDS ${local.name_prefix}"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inbound traffic from VPC"
    from_port   = local.rds_config.port
    to_port     = local.rds_config.port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-rds-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

module "db" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-rds.git?ref=v6.7.0"

  identifier = local.rds_config.identifier

  engine               = local.rds_config.engine
  engine_version       = local.rds_config.engine_version
  family               = local.rds_config.family
  major_engine_version = local.rds_config.major_engine_version
  instance_class       = local.rds_config.instance_class

  allocated_storage     = local.rds_config.allocated_storage
  max_allocated_storage = try(local.rds_config.max_allocated_storage, 100)

  db_name  = replace(local.name_prefix, "-", "")
  username = local.rds_config.username
  port     = local.rds_config.port

  manage_master_user_password = true

  # Network
  db_subnet_group_name   = "${local.name_prefix}-sng"
  create_db_subnet_group = true
  subnet_ids             = var.private_subnets
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Backup & Maintenance
  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = try(local.rds_config.backup_retention_period, 7)
  skip_final_snapshot     = try(local.rds_config.skip_final_snapshot, true)

  # Multi-AZ
  multi_az = try(local.rds_config.multi_az, local.env == "prod" ? true : false)

  tags = local.tags
}
