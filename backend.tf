# Deliberately empty: bucket, key, endpoint and locking are per environment and
# supplied at init time. Never hardcode one here — a committed bucket/key pair is
# how a dev apply ends up writing prod state.
#
#   terraform init -reconfigure -backend-config=environments/dev/backend.hcl
#   terraform init -reconfigure -backend-config=environments/localstack/backend.hcl

terraform {
  backend "s3" {}
}
