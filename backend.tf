# Partial configuration: bucket, key, region and lock come from backend.hcl at init.
terraform {
  backend "s3" {}
}
