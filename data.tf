# Only what is actually referenced. aws_region and aws_availability_zones were
# declared here and never read: region comes from global_config in config.yml,
# and the AZ list is named explicitly in the vpc block. Every data source costs
# an API call on every plan and an IAM permission to allow it.

data "aws_caller_identity" "current" {}
