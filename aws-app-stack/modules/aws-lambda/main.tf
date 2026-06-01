module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  create          = var.create
  create_package  = var.source_path != null ? var.create_package : false
  create_function = var.create
  create_role     = var.create_role
  publish         = var.publish

  function_name = "${var.name}-${var.environment}"
  description   = var.description != "" ? var.description : "${var.name} (${var.environment})"
  handler       = var.handler
  runtime       = var.runtime
  memory_size   = var.memory_size
  timeout       = var.timeout
  layers        = var.layers

  reserved_concurrent_executions = var.reserved_concurrent_executions

  # Source: local path hoặc S3 package
  source_path          = var.source_path
  s3_existing_package  = var.s3_existing_package

  environment_variables = var.environment_variables

  # VPC — optional: chỉ set khi cần access RDS / ElastiCache trong VPC
  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids

  # Lambda Function URL (không cần API GW)
  create_lambda_function_url = var.create_lambda_function_url

  # IAM policies đính kèm
  attach_policies    = length(var.attach_policy_arns) > 0
  policies           = var.attach_policy_arns
  number_of_policies = length(var.attach_policy_arns)

  tags = var.tags
}
