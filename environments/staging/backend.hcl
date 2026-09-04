# ==============================================================================
# STATE BACKEND — staging
# ==============================================================================
#   terraform init -reconfigure -backend-config=environments/staging/backend.hcl
#
# Locking: Terraform here is 1.5.7, which predates S3-native locking. Uncomment
# dynamodb_table (the table must exist, with a "LockID" string hash key), or move
# to use_lockfile = true once the CLI floor is >= 1.10 and drop the table.
# Running without either means concurrent applies can corrupt this state.
# ==============================================================================

bucket  = "sm-terraform-statefile-staging"
key     = "staging/platform/terraform.tfstate"
region  = "ap-southeast-1"
encrypt = true

# kms_key_id     = "arn:aws:kms:ap-southeast-1:<account>:key/<id>"
# dynamodb_table = "sm-terraform-locks-staging"     # TF < 1.10
# use_lockfile   = true                        # TF >= 1.10 (preferred)
