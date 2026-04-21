module "ecs" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ecs.git?ref=v5.11.2"

  # Fix 3: Dùng local.ecs_config thay vì local.config.ecs (sai key)
  cluster_name = local.ecs_config.cluster_name

  cluster_settings = [
    {
      name  = "containerInsights"
      value = try(local.ecs_config.container_insights, true) ? "enabled" : "disabled"
    }
  ]

  cluster_configuration = {
    execute_command_configuration = {
      kms_key_id = try(local.ecs_config.kms_key_id, null)
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
        # Fix 3: Đọc từ local.ecs_config thay vì local.config.ecs
        weight = try(local.ecs_config.fargate_weight, 100)
        base   = try(local.ecs_config.fargate_base, 0)
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = try(local.ecs_config.fargate_spot_weight, 0)
      }
    }
  }

  tags = local.tags
}
