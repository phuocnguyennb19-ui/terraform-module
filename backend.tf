# ==============================================================================
# STATE BACKEND — PARTIAL CONFIGURATION
# ==============================================================================
# Deliberately empty. The bucket, key, endpoint and locking settings are per
# environment and are supplied at init time:
#
#   terraform init -reconfigure -backend-config=environments/dev/backend.hcl
#   terraform init -reconfigure -backend-config=environments/localstack/backend.hcl
#
# Never hardcode an environment here — a committed bucket/key pair is how a dev
# apply ends up writing prod state. This block used to carry
# bucket = "terraform-state" plus a LocalStack endpoint and access_key = "test",
# which contradicted both this comment and every environments/*/backend.hcl.
# ==============================================================================

terraform {
  backend "s3" {}
}
