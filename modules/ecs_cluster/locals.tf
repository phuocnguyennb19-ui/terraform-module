locals {

  # 2. Local Module Config (Support dynamic config file name)
  config_local = merge(
    try(yamldecode(file("${path.cwd}/${var.config_file}")), {}),
    var.manual_config
  )

  # 3. Context & Naming (Strict mapping from config.yml)
  env          = lookup(var.global_config, "environment", "dev")
  region       = lookup(var.global_config, "region", "ap-southeast-1")
  project      = lookup(var.global_config, "project", "core")
  app_name     = lookup(local.config_local, "app_name", null)
  service_type = lookup(local.config_local, "service_type", "infra")
  name_prefix  = join("-", compact([local.env, local.app_name == "base" ? null : local.app_name, local.service_type]))

  # 4. Smart Mapping for ecs/ecs_cluster
  raw_ecs_config = merge(
    try(local.config_local.ecs, {}),
    try(local.config_local.ecs_cluster, {})
  )

  ecs_defaults = {
    cluster_name              = "${local.name_prefix}-cluster"
    container_insights        = lookup(local.raw_ecs_config, "container_insights", true)
    kms_key_id                = lookup(local.raw_ecs_config, "kms_key_id", null)
    fargate_weight            = lookup(local.raw_ecs_config, "fargate_weight", 100)
    fargate_base              = lookup(local.raw_ecs_config, "fargate_base", 0)
    fargate_spot_weight       = lookup(local.raw_ecs_config, "fargate_spot_weight", 0)
    create_task_exec_iam_role = lookup(local.raw_ecs_config, "create_task_exec_iam_role", true)
    create_task_exec_policy   = lookup(local.raw_ecs_config, "create_task_exec_policy", true)
    task_exec_ssm_param_arns  = lookup(local.raw_ecs_config, "task_exec_ssm_param_arns", ["arn:aws:ssm:*:*:parameter/*"])
    task_exec_secret_arns     = lookup(local.raw_ecs_config, "task_exec_secret_arns", ["arn:aws:secretsmanager:*:*:secret:*"])

    # full upstream surface
    # Remaining upstream arguments with a simple literal default, mapped with
    # that same default as the fallback: omitting a key behaves as before.
    autoscaling_capacity_providers          = try(local.raw_ecs_config.autoscaling_capacity_providers, {})
    cloudwatch_log_group_kms_key_id         = try(local.raw_ecs_config.cloudwatch_log_group_kms_key_id, null)
    cloudwatch_log_group_name               = try(local.raw_ecs_config.cloudwatch_log_group_name, null)
    cloudwatch_log_group_retention_in_days  = try(local.raw_ecs_config.cloudwatch_log_group_retention_in_days, 90)
    cloudwatch_log_group_tags               = try(local.raw_ecs_config.cloudwatch_log_group_tags, {})
    cluster_service_connect_defaults        = try(local.raw_ecs_config.cluster_service_connect_defaults, {})
    cluster_tags                            = try(local.raw_ecs_config.cluster_tags, {})
    create                                  = try(local.raw_ecs_config.create, true)
    create_cloudwatch_log_group             = try(local.raw_ecs_config.create_cloudwatch_log_group, true)
    create_task_exec_iam_role               = try(local.raw_ecs_config.create_task_exec_iam_role, false)
    create_task_exec_policy                 = try(local.raw_ecs_config.create_task_exec_policy, true)
    services                                = try(local.raw_ecs_config.services, {})
    task_exec_iam_role_description          = try(local.raw_ecs_config.task_exec_iam_role_description, null)
    task_exec_iam_role_name                 = try(local.raw_ecs_config.task_exec_iam_role_name, null)
    task_exec_iam_role_path                 = try(local.raw_ecs_config.task_exec_iam_role_path, null)
    task_exec_iam_role_permissions_boundary = try(local.raw_ecs_config.task_exec_iam_role_permissions_boundary, null)
    task_exec_iam_role_policies             = try(local.raw_ecs_config.task_exec_iam_role_policies, {})
    task_exec_iam_role_tags                 = try(local.raw_ecs_config.task_exec_iam_role_tags, {})
    task_exec_iam_role_use_name_prefix      = try(local.raw_ecs_config.task_exec_iam_role_use_name_prefix, true)
    task_exec_iam_statements                = try(local.raw_ecs_config.task_exec_iam_statements, {})
  }
  ecs_config = merge(local.ecs_defaults, local.raw_ecs_config)

  # 5. Global Alias & Tags
  config = local.config_local
  tags = merge(
    {
      Environment = local.env,
      Project     = local.project,
      ManagedBy   = lookup(var.global_config, "managed_by", "DylanDevOps"),
      CostCenter  = lookup(var.global_config, "cost_center", "shared-services"),
      Terraform   = "true"
    },
    var.tags, try(var.global_config.tags, {})
  )
}
