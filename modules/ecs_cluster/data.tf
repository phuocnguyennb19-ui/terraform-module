# Fix 6: removed remote state; use local.env instead of a hardcoded "prod"
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
