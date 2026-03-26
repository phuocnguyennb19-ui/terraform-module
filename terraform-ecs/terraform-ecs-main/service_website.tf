module "website" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  # Service settings
  create_service     = try(var.create_service, false)
  enable_autoscaling = try(var.enable_autoscaling, false)
  name              = "${var.env}_${var.source_code}_${local.service.internal}"

  # Cluster configuration
  cluster_arn = lookup(local.cluster_arn, var.env, "fargate")

  # Network settings
  network_mode = local.requires_compatibilities == "EC2" ? "bridge" : "awsvpc"
  cpu          = local.requires_compatibilities == "EC2" ? null : local.task_config.cpu
  memory       = local.requires_compatibilities == "EC2" ? null : local.task_config.memory

  # Task Definition
  requires_compatibilities = try([local.requires_compatibilities], ["FARGATE"])

  # Capacity provider strategy
  capacity_provider_strategy = [
    lookup(local.capacity_provider_strategy, 
      var.env == "test" ? "test" :
      var.env == "stg" && contains([local.service.internal], "worker") ? "worker" :
      var.env == "stg" && contains([local.service.internal], "internal") ? "internal" :
      var.env == "bmk" ? "bmk" :
      "fargate",  # Default if no condition matches
      "fargate"   # Default value if lookup fails
    )
  ]

  # Deployment settings
  deployment_maximum_percent         = can(regex("schedule", local.service.internal)) ? 100 : local.deployment_settings.maximum_percent
  deployment_minimum_healthy_percent = can(regex("schedule", local.service.internal)) ? 0 : local.deployment_settings.minimum_healthy_percent
  deployment_circuit_breaker         = local.deployment_settings.circuit_breaker
  wait_for_steady_state              = local.deployment_settings.wait_for_steady_state

  # Runtime platform
  runtime_platform = local.runtime_platform

  # Task placement
  ordered_placement_strategy = local.ordered_placement_strategy

  # Container definitions
  container_definitions = {
    php = {
      enable_cloudwatch_logging   = false
      create_cloudwatch_log_group = false
      readonly_root_filesystem    = false
      name                 = "php"
      image                = "${local.aws.account_id}.dkr.ecr.${local.aws.region}.amazonaws.com/${var.env}_php_${var.source_code}:${var.image_tag}"
      cpu                  = 0
      user                 = local.users.php
      memory_reservation   = 310
      essential            = true
      environment          = try([
        for k, v in jsondecode(replace(file("${path.module}/${var.env}_env_public.json"), "/${var.source_code}_service/", "${var.source_code}_${local.service.internal}")) :
        { name = k, value = v }
      ], [])
      mount_points         = local.requires_compatibilities == "EC2" ? local.shared_mount_points : []
      secrets              = try([
        for k, v in jsondecode(file("${path.module}/${var.env}_env_secret.json")) :
        { name = k, valueFrom = v }
      ], [])
    }

    nginx = {
      enable_cloudwatch_logging   = false
      create_cloudwatch_log_group = false
      readonly_root_filesystem    = false      
      name                 = "nginx"
      image                = "${local.aws.account_id}.dkr.ecr.${local.aws.region}.amazonaws.com/${var.env}_nginx_${var.source_code}:${var.image_tag}"
      cpu                  = 0
      memory_reservation   = 6
      port_mappings        = [
        {
          containerPort = try(length(local.nginx.containerPort) > 0 ? local.nginx.containerPort[0] : 443, 443)
          hostPort      = local.requires_compatibilities == "EC2" ? 0 : local.nginx.hostPort
          protocol      = try(local.nginx.protocol, "tcp")
        }
      ]
      essential            = true
      environment          = []
      secrets              = []
      user                 = local.users.nginx
      dependencies         = local.container_config.dependencies
      log_configuration    = {
        logDriver = "awsfirelens"
        options = {
          AWS_Region          = local.aws.region
          Host                = local.logging_config.os_host
          Logstash_DateFormat = local.logging_config.fluentbit_index_date_format
          Logstash_Format     = "On"
          Logstash_Prefix     = "${var.env}_nginx_${var.source_code}_${local.service.internal}"
          Name                = "opensearch"
          Port                = "443"
        }
      }
    }

    otel = {
      enable_cloudwatch_logging   = false
      create_cloudwatch_log_group = false
      readonly_root_filesystem    = false      
      name                 = "otel"
      image                = "${local.aws.account_id}.dkr.ecr.${local.aws.region}.amazonaws.com/${var.aws-otel-collector}:${var.otel_version}"
      cpu                  = 0
      memory_reservation   = 6
      user                 = local.users.otel
      command              = local.command.otel
      port_mappings        = []
      essential            = true
      environment          = []
      mount_points         = []
      secrets              = try(var.otel_env_secret, [])
      health_check         = try(var.health_check, [])
      log_configuration    = {
        logDriver = "awsfirelens"
        options = {
          AWS_Region          = local.aws.region
          Host                = local.logging_config.os_host
          Logstash_DateFormat = local.logging_config.fluentbit_index_date_format
          Logstash_Format     = "On"
          Logstash_Prefix     = "${var.env}_otel_${var.source_code}_${local.service.internal}"
          Name                = "opensearch"
          Port                = "443"
        }
      }
    }

    fluent-bit = {
      enable_cloudwatch_logging   = false
      create_cloudwatch_log_group = false
      readonly_root_filesystem    = false
      name      = "fluent-bit"
      image     = "${local.aws.account_id}.dkr.ecr.${local.aws.region}.amazonaws.com/based-gotit-fluent-bit:${local.fluentbit_version}"
      cpu       = 0
      memory_reservation    = 6
      port_mappings = []
      essential             = true
      environment = [
        { "name": "multiline-regex", "value": "multiline-regex" },
        { "name": "index_time", "value": "%m.%Y" },
        { "name": "index", "value": "${var.env}_php_${var.source_code}_${local.service.internal}" },
        { "name": "nginx_log_match", "value": "nginx-firelens" },
        { "name": "source", "value": "${var.source_code}" },
        { "name": "os_host", "value": "${local.os_host}" }
      ]
      mount_points = try(local.fb_mount_points, [])
      volumes_from = try(local.volumes_from, [])
      user         = try(local.fb_user, 0)
      firelens_configuration = {
        type = "fluentbit"
        options = {
          "config-file-type"  = "file"
          "config-file-value" = "/mnt/${local.config_file_value}"
        }
      }
    }    
  } 

  # IAM Roles
  create_security_group               = false
  create_iam_role                     = false
  create_tasks_iam_role               = false
  create_task_exec_policy             = false
  task_exec_iam_role_use_name_prefix  = false  
  create_task_exec_iam_role = local.iam_role_config.create_task_exec_iam_role
  task_exec_iam_role_policies = local.iam_role_config.task_exec_iam_role_policies
  task_exec_iam_role_name = "${var.env}_${var.source_code}_service"      
  iam_role_arn            = "arn:aws:iam::${local.aws.account_id}:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"
  tasks_iam_role_arn      = "arn:aws:iam::${local.aws.account_id}:role/${var.env}_${var.source_code}_service"
  task_exec_iam_role_arn  = "arn:aws:iam::${local.aws.account_id}:role/${var.env}_${var.source_code}_service"

  # Network settings
  subnet_ids = local.selected_subnets
  security_group_ids = local.security_group_ids

  load_balancer = local.load_balancer

  # Tags
  service_tags = local.tags
  tags         = local.tags
}