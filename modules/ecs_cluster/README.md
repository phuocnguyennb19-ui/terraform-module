# ecs_cluster

ECS cluster with Fargate capacity providers.

Wraps `terraform-aws-ecs` (v5.11.4). Configuration comes from the `ecs:` block of a YAML file (legacy key `ecs_cluster:` is still merged).

## Usage

```hcl
module "ecs_cluster" {
  source = "../../modules/ecs_cluster"

  config_file = "config.yml"

  global_config = {
    environment = "dev"
    region      = "ap-southeast-1"
    project     = "SM-Platform"
  }

  vpc_id = module.vpc.vpc_id
}
```

```yaml
# config.yml
app_name: "base"
service_type: "infra"

ecs:                                             # legacy key: ecs_cluster
  enabled: false
  container_insights: true
  kms_key_id: null                               # encrypts ECS Exec sessions
  fargate_weight: 100                            # prod: all on-demand
  fargate_base: 0
  fargate_spot_weight: 0                         # dev: 0 / 100 for all-spot
  create_task_exec_iam_role: true
  create_task_exec_policy: true
  task_exec_secret_arns:    ["arn:aws:secretsmanager:ap-southeast-1:111122223333:secret:*"]
  task_exec_ssm_param_arns: []

# 18 further upstream arguments are listed, grouped and commented out,
# in examples/module-config/ecs_cluster.yml
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0, < 6.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0, < 6.0 |

Configured by the caller. This module declares no `provider` and no `backend`.

## Modules

| Name | Source | Version |
|------|--------|---------|
| `terraform-aws-ecs` | `terraform-aws-ecs` | `v5.11.4` |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `vpc_id` | VPC ID for security group orchestration | `string` | `null` | no |
| `global_config` | Environment context shared by every module: environment, region and project, plus optional managed_by, cost_center and tags. `environment` is validated against dev, test, staging, preprod, prod. | `object` | n/a | **yes** |
| `config_file` | Path to the YAML config, resolved against `path.cwd` — the directory Terraform is run from, not the module directory. | `string` | `"config.yml"` | no |
| `manual_config` | Configuration merged over the decoded YAML at the top level. The root composition uses this to pass a layered config; leave unset when calling the module directly. | `any` | `{}` | no |
| `tags` | Extra tags, merged over the ones derived from `global_config`. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | ID of the ECS cluster |
| `cluster_arn` | ARN of the ECS cluster |
| `cluster_name` | Name of the ECS cluster |
| `task_exec_iam_role_arn` | ARN of the default task execution IAM role |
| `task_exec_iam_role_name` | Name of the default task execution IAM role |
