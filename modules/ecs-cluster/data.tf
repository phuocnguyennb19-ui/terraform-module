# Fix 6: Xóa Remote State, dùng local.env thay vì hardcode "prod"
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
