# Fix 6: removed remote state from rds/data.tf
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
