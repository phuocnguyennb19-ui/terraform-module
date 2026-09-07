# elasticache

ElastiCache replication group or cluster.

Wraps `terraform-aws-elasticache` (v1.1.0). Configuration comes from the `elasticache:` block of a YAML file.

## Usage

```hcl
module "elasticache" {
  source = "../../modules/elasticache"

  config_file = "config.yml"

  global_config = {
    environment = "dev"
    region      = "ap-southeast-1"
    project     = "SM-Platform"
  }

  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}
```

```yaml
# config.yml
app_name: "base"
service_type: "infra"

elasticache:
  enabled: false
  engine: "redis"
  engine_version: "7.1"
  node_type: "cache.t4g.micro"
  num_cache_nodes: 1
  num_node_groups: 1                             # shards, for cluster mode
  replicas_per_node_group: 2                     # prod
  port: 6379
  parameter_group_name: "default.redis7"
  automatic_failover_enabled: true               # requires at least one replica
  multi_az_enabled: true
  snapshot_retention_limit: 7                    # 0 disables snapshots
  snapshot_window: "03:00-05:00"
  maintenance_window: "sun:05:00-sun:07:00"
  apply_immediately: false
  auto_minor_version_upgrade: true
  kms_key_arn: null
  security_group_ids: []                         # empty = the module creates one

# 41 further upstream arguments are listed, grouped and commented out,
# in examples/module-config/elasticache.yml
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
| `terraform-aws-elasticache` | `terraform-aws-elasticache` | `v1.1.0` |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `vpc_id` | VPC ID for orchestration | `string` | `null` | no |
| `private_subnets` | Private Subnets for orchestration | `list(string)` | `null` | no |
| `global_config` | Environment context shared by every module: environment, region and project, plus optional managed_by, cost_center and tags. `environment` is validated against dev, test, staging, preprod, prod. | `object` | n/a | **yes** |
| `config_file` | Path to the YAML config, resolved against `path.cwd` — the directory Terraform is run from, not the module directory. | `string` | `"config.yml"` | no |
| `manual_config` | Configuration merged over the decoded YAML at the top level. The root composition uses this to pass a layered config; leave unset when calling the module directly. | `any` | `{}` | no |
| `tags` | Extra tags, merged over the ones derived from `global_config`. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | ID of the ElastiCache cluster |
| `cluster_arn` | ARN of the ElastiCache cluster |
| `primary_endpoint_address` | Primary endpoint address (Redis replication group) |
| `reader_endpoint_address` | Reader endpoint address (Redis replication group) |
| `cluster_endpoint` | Cluster endpoint (Memcached / Redis Cluster Mode) |
| `port` | Port of the ElastiCache cluster |
