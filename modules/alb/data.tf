# Fix 1 & 6: Xóa Remote State, fix hardcoded "prod" → dùng local.env
# ALB chỉ cần caller identity và region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
