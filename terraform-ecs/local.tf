locals {
  # Srum Team
  scrum = "CORE"
  # ECS Cluster ARNs
  cluster_arn = {
    for name in ["test", "bmk", "api", "external", "internal", "worker"] :
    name => "arn:aws:ecs:${local.aws.region}:${local.aws.account_id}:cluster/${
      name == "test" ? upper("DEV-EC2-cluster") :
      name == "bmk" ? upper("BMK-FARGATE-cluster") :
      upper("${var.env}-${name}-cluster")
    }"
  }

  # AWS
  aws = {
    region = "ap-southeast-1"
    account_id = ""
  }
  # Service
  service = {
    api       = "api"
    ws        = "ws"
    internal  = "internal"
    exec      = "exec"
    worker    = "worker"
    schedule  = "schedule"    
  }
  # Command
  command = {
    otel      = []
    exec      = []
    worker    = ["php", "artisan", "queue:work"]
    schedule  = ["php", "artisan", "schedule:work"]
  }
  # Capacity provider strategy
  capacity_provider_strategy = {
    test      = { capacity_provider = "DEV-EC2-ARM64-CLUSTER-01", weight = 1, base = 1 }
    worker   = { capacity_provider = "STG-WORKER-ARM64-CLUSTER", weight = 1, base = 0 }
    internal = { capacity_provider = "STG-INTERNAL-ARM64-CLUSTER", weight = 1, base = 0 }
    bmk      = { capacity_provider = "BMK-FARGATE-ARM64-CLUSTER-01", weight = 1, base = 0 }
    fargate  = { capacity_provider = "FARGATE_SPOT", weight = 1, base = 0 }
  }

  # Requires_compatibilities
  requires_compatibilities = contains(["test"], var.env) ? "EC2" : (contains(["stg", "bmk"], var.env) && contains(["worker", "schedule", "queue"], var.service) ? "EC2" : "FARGATE")

  # Deployment configurations
  deployment_settings = {
    maximum_percent         = 200
    minimum_healthy_percent = 200
    circuit_breaker         = { enable = false, rollback = false }
    wait_for_steady_state   = false
  }

  # Runtime platform
  runtime_platform = {
    cpu_architecture       = "X86_64"
    operating_system_family = "LINUX"
  }

  # Placement strategy
  ordered_placement_strategy = [
    { type = "spread", field = "attribute:ecs.availability-zone" }
  ]

  # Task configuration
  task_config = {
    cpu    = var.task_cpu
    memory = var.task_memory
  }

  # Users
  users = {
    php    = "www-data"
    nginx  = "nginx"
    fluent = 0
    otel   = 0
  }

  # Mount points
  shared_mount_points = var.enable_logging ? [
    { sourceVolume = "Log_DockerVolume", containerPath = "/var/www/html/storage/logs" }
  ] : []

  # Container dependencies
  container_config = {
    volumes_from = [{ sourceContainer = "php" }]
    dependencies = var.enable_fluent_bit ? [{ containerName = "fluent-bit", condition = "START" }] : []
  }

  # Logging and Fluent Bit configuration
  logging_config = {
    os_host                        = "vpc-os-ecs-zupft3thp2xqs675gox6jlhjvy.ap-southeast-1.es.amazonaws.com"
    fluentbit_index_date_format    = "%Y.%m"
    config_file_value              = "parsers_template_json.conf"
    fluentbit_version              = var.fluentbit_version
  }

  # Target Group configuration
  target_group = {
    port        = 80
    protocol    = "HTTPS"       
    health_check_path = "/health"    
    health_check_protocol = "HTTPS"
  }
  # Load Balancer configuration
  listener_arns = {
    "test"        = var.listener_arn_test
    "stg"         = var.listener_arn_stg
    "stg-private" = var.listener_arn_stg_private
    "bmk"         = var.listener_arn_bmk
  }
  selected_listener_arns = lookup(local.listener_arns[var.env], local.target_group.port, "arn-not-found")
  load_balancer = [
    {
      target_group_arn = try(aws_lb_target_group.this.arn, "")
      container_name   = "nginx"
      container_port   = 80
    }
  ]

  # Network configurations
  vpc_id = ["vpc-064120207d0518f99", "vpc-0d16a9790955b4915"]

  subnet_ids = {
    api      = ["subnet-03c147ae66746c4ee", "subnet-0b29ae68e22813608"]
    external = ["subnet-0c3c4ef97eff2d3ff", "subnet-016fa1fbb1acfe3db"]
    internal = ["subnet-0ae3a70f8ef9dfec7", "subnet-0f50868e7abacc3a6"]
    worker   = ["subnet-03fced6b7b161524e", "subnet-05772289001e2189c"]
    data     = ["subnet-0e596d75992149592", "subnet-0d3af45e4acb6d99e"]
    public   = ["subnet-0595b416662a0b537", "subnet-0f2af7e7b2a8f4a1e"]
    private  = ["subnet-08160702b7c02b30d", "subnet-0d444a6d5cdf6ca96"]
    dev      = []
  }

  selected_subnets = (
    contains(["stg", "bmk"], var.env) && contains(["api", "worker", "internal", "external"], var.service)
    ? lookup(local.subnet_ids, var.service, ["subnet-08160702b7c02b30d", "subnet-0d444a6d5cdf6ca96"])
    : ["subnet-08160702b7c02b30d", "subnet-0d444a6d5cdf6ca96"]
  )

  security_group_ids = ["sg-12345678"]

  # IAM Role policies
  iam_role_config = {
    create_task_exec_iam_role = false
    task_exec_iam_role_policies = {
      EC2 = "arn:aws:iam::${local.aws.account_id}:policy/example"
    }
  }

  # Common tags applied to all resources
  tags = merge({
    ENV                           = var.env
    "${upper(local.scrum)}"        = "true"
    COST_CENTER                   = "gotit"
    "${upper(var.source_code)}_SOURCE" = "true"
  }, var.additional_tags)

  # Fluent Bit configuration
  fluentbit_version = "7.1"
  config_file_value = "fluent-bit.conf"
  os_host           = "search-host.amazonaws.com"
  fb_mount_points   = []
  volumes_from      = []
  fb_user           = 0

  # Port Mapping
  nginx = {
    containerPort = try(length(var.containerPort) > 0 ? var.containerPort[0] : 443, 443)
    hostPort      = contains(var.requires_compatibilities, "EC2") ? 0 : var.hostPort
    protocol      = try(var.protocol, "tcp")
  }
}