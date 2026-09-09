# ECS CLUSTER
#
# Consumes nothing from the network. A Fargate cluster is a scheduling and
# capacity boundary, not a network one: the ENI is created per task by the
# service, in the subnets and security groups the ecs-service module is given.
# That is why there is no vpc_id or subnet_ids input here — putting one in would
# imply this module places tasks, and it does not.
#
# Upstream: terraform-aws-modules/ecs/aws v5.11.4, cluster submodule only. The
# root module of that package also creates services, which would collapse the
# cluster/service split this platform depends on — one cluster per environment,
# N services against it, each with its own state footprint and its own lifecycle.

locals {
  # Execute-command session output goes here. Named explicitly rather than left
  # to the module default so the cluster_configuration block below can reference
  # it without a cycle through the module's own output.
  log_group_name = "/aws/ecs/${var.cluster_name}"

  # A capacity provider with weight 0 is not "off" — it is "eligible but never
  # chosen while another provider has weight". Dropping it from the map entirely
  # is what actually keeps Spot out of the cluster.
  fargate_capacity_providers = merge(
    {
      FARGATE = {
        default_capacity_provider_strategy = {
          weight = var.fargate_weight
          base   = var.fargate_base
        }
      }
    },
    var.fargate_spot_weight > 0 ? {
      FARGATE_SPOT = {
        default_capacity_provider_strategy = {
          weight = var.fargate_spot_weight
        }
      }
    } : {},
  )
}

module "cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.11.4"

  cluster_name = var.cluster_name

  cluster_settings = [
    {
      name  = "containerInsights"
      value = var.container_insights ? "enabled" : "disabled"
    }
  ]

  # ---- Execute command ----------------------------------------------------
  # `aws ecs execute-command` is the Fargate equivalent of kubectl exec. It is
  # left enabled because the alternative — an SSH path into a task — is worse in
  # every way, but it is only defensible with the session logged: logging
  # "OVERRIDE" forces every session transcript into the log group below, where
  # it is retained and encrypted rather than existing solely in the operator's
  # terminal. A session that leaves no trace is an unaudited shell in production.
  cluster_configuration = {
    execute_command_configuration = {
      kms_key_id = var.execute_command_kms_key_arn
      logging    = "OVERRIDE"

      log_configuration = {
        cloud_watch_encryption_enabled = var.log_kms_key_arn != null
        cloud_watch_log_group_name     = local.log_group_name
      }
    }
  }

  create_cloudwatch_log_group            = true
  cloudwatch_log_group_name              = local.log_group_name
  cloudwatch_log_group_retention_in_days = var.log_retention_days
  cloudwatch_log_group_kms_key_id        = var.log_kms_key_arn

  # ---- Capacity -----------------------------------------------------------
  default_capacity_provider_use_fargate = true
  fargate_capacity_providers            = local.fargate_capacity_providers

  # No autoscaling_capacity_providers: that input takes EC2 autoscaling groups,
  # and this cluster is Fargate only. See the note in variables.tf.
  autoscaling_capacity_providers = {}

  # ---- Service Connect ----------------------------------------------------
  cluster_service_connect_defaults = var.service_connect_namespace != null ? {
    namespace = var.service_connect_namespace
  } : {}

  # ---- Shared execution role ---------------------------------------------
  create_task_exec_iam_role               = var.create_task_exec_iam_role
  create_task_exec_policy                 = var.create_task_exec_iam_role
  task_exec_iam_role_name                 = "${var.cluster_name}-task-exec"
  task_exec_iam_role_use_name_prefix      = false
  task_exec_iam_role_permissions_boundary = var.task_exec_iam_role_permissions_boundary
  task_exec_secret_arns                   = var.task_exec_secret_arns
  task_exec_ssm_param_arns                = var.task_exec_ssm_param_arns

  tags = var.tags
}
