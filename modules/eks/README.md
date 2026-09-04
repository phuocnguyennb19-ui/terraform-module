# eks

EKS cluster with managed node groups, addons and access entries.

Wraps `terraform-aws-eks` (v20.31.6). Configuration comes from the `eks:` block of a YAML file.

## Usage

```hcl
module "eks" {
  source = "../../modules/eks"

  config_file = "config.yml"

  global_config = {
    environment = "dev"
    region      = "ap-southeast-1"
    project     = "SM-Platform"
  }

  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets = module.vpc.public_subnets
}
```

```yaml
# config.yml
app_name: "base"
service_type: "infra"

eks:
  enabled: false
  cluster_name: "dev-infra-eks"
  cluster_version: "1.31"

  # Private by default. A public API server open to 0.0.0.0/0 is the single most
  # common EKS misconfiguration; if you must open it, list office CIDRs here.
  endpoint_private_access: true
  endpoint_public_access: false
  public_access_cidrs: []

  enabled_log_types: ["api", "audit"]          # prod: all five
  authentication_mode: "API"                   # access entries, not aws-auth
  enable_cluster_creator_admin_permissions: true
  enable_irsa: true                            # OIDC provider, for pod IAM roles

  create_kms_key: true                         # envelope-encrypts Kubernetes secrets
  kms_key_arn: null                            # set to reuse an existing key
  cluster_encryption_config: { resources: ["secrets"] }

  create_cloudwatch_log_group: true
  cloudwatch_log_group_retention_in_days: 30

  subnet_ids: []                               # empty = the private_subnets wired in

  access_entries:
  # … full list in examples/modules/eks.yml
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | >= 5.0, < 6.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0, < 6.0 |

Configured by the caller. This module declares no `provider` and no `backend`.

## Modules

| Name | Source | Version |
|------|--------|---------|
| `terraform-aws-eks` | `terraform-aws-eks` | `v20.31.6` |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `global_config` | Environment context shared by every module: environment, region and project, plus optional managed_by, cost_center and tags. `environment` is validated against dev, test, staging, preprod, prod. | `object` | n/a | **yes** |
| `config_file` | Path to the YAML config, resolved against `path.cwd` — the directory Terraform is run from, not the module directory. | `string` | `"config.yml"` | no |
| `manual_config` | Configuration merged over the decoded YAML at the top level. The root composition uses this to pass a layered config; leave unset when calling the module directly. | `any` | `{}` | no |
| `tags` | Extra tags, merged over the ones derived from `global_config`. | `map(string)` | `{}` | no |
| `vpc_id` | VPC the cluster and its node groups are placed in. | `string` | `null` | no |
| `private_subnets` | Subnets for the control plane ENIs and the node groups. | `list(string)` | `[]` | no |
| `public_subnets` | Only used when a node group is explicitly placed in public subnets. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_name` | Name of the EKS cluster |
| `cluster_arn` | ARN of the EKS cluster |
| `cluster_endpoint` | Endpoint of the Kubernetes API server |
| `cluster_version` | Kubernetes version running on the control plane |
| `cluster_certificate_authority_data` | Base64-encoded CA certificate for the cluster |
| `oidc_provider_arn` | ARN of the IAM OIDC provider, for IRSA role trust policies |
| `oidc_provider_url` | URL of the cluster's OIDC issuer |
| `cluster_security_group_id` | Security group ID attached to the control plane |
| `node_security_group_id` | Security group ID shared by the managed node groups |
| `kms_key_arn` | ARN of the KMS key used for envelope encryption of secrets |
| `eks_managed_node_groups` | Attributes of each managed node group |
| `node_group_iam_role_arns` | IAM role ARN of each managed node group |
| `fargate_profiles` | Attributes of each Fargate profile |
| `kubeconfig_command` | Command that writes a kubeconfig entry for this cluster |
