# Fix 6: removed remote state and the hardcoded "prod" from elasticache/data.tf
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
