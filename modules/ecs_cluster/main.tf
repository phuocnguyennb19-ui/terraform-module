module "ecs" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ecs.git?ref=v5.11.4"

  cluster_name = local.ecs_config.cluster_name

  cluster_settings = [
    {
      name  = "containerInsights"
      value = local.ecs_config.container_insights ? "enabled" : "disabled"
    }
  ]

  cluster_configuration = {
    execute_command_configuration = {
      kms_key_id = local.ecs_config.kms_key_id
      logging    = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/${local.ecs_config.cluster_name}/execute-command"
      }
    }
  }

  default_capacity_provider_use_fargate = true

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = local.ecs_config.fargate_weight
        base   = local.ecs_config.fargate_base
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = local.ecs_config.fargate_spot_weight
      }
    }
  }

  tags = local.tags

  # full upstream surface
  autoscaling_capacity_providers          = local.ecs_config.autoscaling_capacity_providers
  cloudwatch_log_group_kms_key_id         = local.ecs_config.cloudwatch_log_group_kms_key_id
  cloudwatch_log_group_name               = local.ecs_config.cloudwatch_log_group_name
  cloudwatch_log_group_retention_in_days  = local.ecs_config.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_tags               = local.ecs_config.cloudwatch_log_group_tags
  cluster_service_connect_defaults        = local.ecs_config.cluster_service_connect_defaults
  cluster_tags                            = local.ecs_config.cluster_tags
  create                                  = local.ecs_config.create
  create_cloudwatch_log_group             = local.ecs_config.create_cloudwatch_log_group
  create_task_exec_iam_role               = local.ecs_config.create_task_exec_iam_role
  create_task_exec_policy                 = local.ecs_config.create_task_exec_policy
  services                                = local.ecs_config.services
  task_exec_iam_role_description          = local.ecs_config.task_exec_iam_role_description
  task_exec_iam_role_name                 = local.ecs_config.task_exec_iam_role_name
  task_exec_iam_role_path                 = local.ecs_config.task_exec_iam_role_path
  task_exec_iam_role_permissions_boundary = local.ecs_config.task_exec_iam_role_permissions_boundary
  task_exec_iam_role_policies             = local.ecs_config.task_exec_iam_role_policies
  task_exec_iam_role_tags                 = local.ecs_config.task_exec_iam_role_tags
  task_exec_iam_role_use_name_prefix      = local.ecs_config.task_exec_iam_role_use_name_prefix
  task_exec_iam_statements                = local.ecs_config.task_exec_iam_statements
}
