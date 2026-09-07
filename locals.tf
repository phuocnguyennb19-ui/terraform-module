# ROOT LOCALS — decode once, here
# path.cwd, not path.module: the modules resolve the same file the same way, so
# the root and the modules must agree on what the working directory is.

locals {
  # config loading
  # Two modes. Single file (config_file) or a directory of per-module overlays
  # (config_dir). See variables.tf for the precedence order.
  use_dir = var.config_dir != null

  # Terraform builds the interpolated path even on the branch it will not take, and
  # a null in a string template is a hard error. Give it something harmless when
  # config_dir is unset; use_dir still gates whether the path is ever read.
  dir = coalesce(var.config_dir, ".")

  # In directory mode common.yml is REQUIRED: file() errors loudly if it is
  # absent, because a silently missing base config is how an environment gets
  # built entirely from defaults. Read as a string, then decode once — same
  # reason as overlay_raw below.
  base_raw = local.use_dir ? file("${path.cwd}/${local.dir}/common.yml") : file("${path.cwd}/${var.config_file}")
  base     = yamldecode(local.base_raw)

  # Per-module overlays are OPTIONAL: a module with no file just uses common.yml.
  module_names = ["vpc", "kms", "iam", "security_group", "acm", "dns", "waf", "alb", "ecr", "s3", "secrets_manager", "dynamodb", "sqs", "sns", "cloudwatch", "rds", "elasticache", "ecs_cluster", "ecs_service", "eks"]

  # Read as a STRING first, then decode: a conditional whose branches are a
  # decoded object and {} fails type unification the moment two overlay files
  # differ in shape. Not try(yamldecode(...), {}) — that would swallow a
  # malformed YAML file and present it as "no overlay".
  overlay_raw = {
    for m in local.module_names : m => (
      local.use_dir && fileexists("${path.cwd}/${local.dir}/${m}.yml")
      ? file("${path.cwd}/${local.dir}/${m}.yml")
      : "{}"
    )
  }

  overlay = { for m, doc in local.overlay_raw : m => yamldecode(doc) }

  # Two-level merge. merge() is SHALLOW, so `merge(common, overlay)` would replace
  # a whole block and silently drop the defaults common.yml set inside it. The
  # third argument re-merges every map-valued block one level down. Lists are
  # replaced wholesale, which is the behaviour you want for a list.
  cfg = {
    for m in local.module_names : m => merge(
      local.base,
      local.overlay[m],
      { for k, v in local.overlay[m] : k => merge(try(local.base[k], {}), v) if can(keys(v)) },
    )
  }

  # What each module receives as manual_config. No mode conditional: in
  # single-file mode overlay[m] is {}, so cfg[m] == base and merging is a no-op.
  # Keeping the map a single type removes a whole class of unification error.
  manual = local.cfg

  # The path handed to every module. In directory mode it points at common.yml so
  # the module's own read still yields the globals; manual_config then overrides.
  config_path = local.use_dir ? "${local.dir}/common.yml" : var.config_file

  # Everything below reads the base document for globals, and cfg[<module>] for
  # anything module-specific.
  config = local.base

  # global context
  # Shape is fixed by every module's global_config variable. environment is
  # validated module-side against dev|test|staging|preprod|prod.
  global = {
    environment = local.config.global.environment
    region      = local.config.global.region
    project     = local.config.global.project
    managed_by  = try(local.config.global.managed_by, "DylanDevOps")
    cost_center = try(local.config.global.cost_center, "shared-services")
    tags        = try(local.config.global.tags, {})
  }

  aws_profile = try(local.config.global.aws_profile, null)

  # feature gates
  # No module has an internal `enabled` flag; the caller gates with count.
  # Default false: a module is built only when its block explicitly asks for it.
  enabled = {
    vpc             = try(local.cfg["vpc"].vpc.enabled, false)
    kms             = try(local.cfg["kms"].kms.enabled, false)
    iam             = try(local.cfg["iam"].iam.enabled, false)
    security_group  = try(local.cfg["security_group"].security_group.enabled, false)
    acm             = try(local.cfg["acm"].acm.enabled, false)
    waf             = try(local.cfg["waf"].waf.enabled, false)
    ecr             = try(local.cfg["ecr"].ecr.enabled, false)
    secrets_manager = try(local.cfg["secrets_manager"].secrets_manager.enabled, false)
    s3              = try(local.cfg["s3"].s3.enabled, false)
    dynamodb        = try(local.cfg["dynamodb"].dynamodb.enabled, false)
    sqs             = try(local.cfg["sqs"].sqs.enabled, false)
    sns             = try(local.cfg["sns"].sns.enabled, false)
    cloudwatch      = try(local.cfg["cloudwatch"].cloudwatch.enabled, false)
    alb             = try(local.cfg["alb"].alb.enabled, false)
    rds             = try(local.cfg["rds"].rds.enabled, false)
    elasticache     = try(local.cfg["elasticache"].elasticache.enabled, false)
    dns             = try(coalesce(try(local.cfg["dns"].dns.enabled, null), try(local.cfg["dns"].route53.enabled, null)), false)
    ecs_cluster     = try(coalesce(try(local.cfg["ecs_cluster"].ecs.enabled, null), try(local.cfg["ecs_cluster"].ecs_cluster.enabled, null)), false)
    ecs_service     = try(coalesce(try(local.cfg["ecs_service"].service.enabled, null), try(local.cfg["ecs_service"].ecs_service.enabled, null)), false)
    eks             = try(local.cfg["eks"].eks.enabled, false)
  }

  # pre-existing infrastructure
  # `existing:` names things this stack must use but does not own. A lookup runs
  # only when the module that would otherwise create the thing is disabled AND
  # the config names it, so an environment that builds everything pays nothing.
  existing = try(local.config.existing, {})

  lookup = {
    vpc             = !local.enabled.vpc && (try(local.existing.vpc.id, null) != null || try(local.existing.vpc.name_tag, null) != null)
    private_subnets = !local.enabled.vpc && try(local.existing.private_subnets.tag, null) != null
    public_subnets  = !local.enabled.vpc && try(local.existing.public_subnets.tag, null) != null
    alb             = !local.enabled.alb && try(local.existing.alb.name, null) != null
    ecs_cluster     = !local.enabled.ecs_cluster && try(local.existing.ecs_cluster.name, null) != null
  }

  # A data source with count = 0 is still checked against the provider schema,
  # so every value below falls back to something the schema accepts. None of it
  # is read when the matching lookup is off.
  ex = {
    vpc_id                   = try(local.existing.vpc.id, null)
    vpc_name_tag             = try(local.existing.vpc.name_tag, "unused")
    private_subnet_tag_key   = try(local.existing.private_subnets.tag.key, "unused")
    private_subnet_tag_value = try(local.existing.private_subnets.tag.value, "unused")
    public_subnet_tag_key    = try(local.existing.public_subnets.tag.key, "unused")
    public_subnet_tag_value  = try(local.existing.public_subnets.tag.value, "unused")
    alb_name                 = try(local.existing.alb.name, "unused")
    alb_listener_port        = try(local.existing.alb.listener_port, 443)
    ecs_cluster_name         = try(local.existing.ecs_cluster.name, "unused")
  }

  # Subnet ids can also be listed outright, which skips the lookup entirely.
  ex_private_subnet_ids = try(local.existing.private_subnets.ids, null)
  ex_public_subnet_ids  = try(local.existing.public_subnets.ids, null)

  # wiring
  # Built here, looked up, or null — in that order. `null` still means "nothing
  # provides this", which is what a module receiving it should fail on.
  vpc_id = try(module.vpc[0].vpc_id, try(data.aws_vpc.existing[0].id, null))

  vpc_cidr_block = try(module.vpc[0].vpc_cidr_block, try(data.aws_vpc.existing[0].cidr_block, null))

  public_subnets = coalesce(
    try(module.vpc[0].public_subnets, null),
    local.ex_public_subnet_ids,
    try(data.aws_subnets.existing_public[0].ids, null),
    [],
  )

  private_subnets = coalesce(
    try(module.vpc[0].private_subnets, null),
    local.ex_private_subnet_ids,
    try(data.aws_subnets.existing_private[0].ids, null),
    [],
  )

  # Databases prefer dedicated database subnets and fall back to private ones.
  database_subnets = length(try(module.vpc[0].database_subnets, [])) > 0 ? module.vpc[0].database_subnets : local.private_subnets

  # ALB emits a list; ecs_service wants one listener ARN.
  listener_arn = try(module.alb[0].http_tcp_listener_arns[0], try(data.aws_lb_listener.existing[0].arn, null))

  cluster_arn = try(module.ecs_cluster[0].cluster_arn, try(data.aws_ecs_cluster.existing[0].arn, null))

  # Route53 alias targets — outputs, so they cannot come from YAML.
  alb_dns_name = try(module.alb[0].lb_dns_name, try(data.aws_lb.existing[0].dns_name, null))
  alb_zone_id  = try(module.alb[0].lb_zone_id, try(data.aws_lb.existing[0].zone_id, null))

  # tags
  # Same shape the modules build internally, so root-created and module-created
  # resources carry identical tags.
  tags = merge(
    {
      Environment = local.global.environment
      Project     = local.global.project
      ManagedBy   = local.global.managed_by
      CostCenter  = local.global.cost_center
      Terraform   = "true"
    },
    local.global.tags,
    var.tags,
  )
}
