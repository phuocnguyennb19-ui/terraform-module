# ==============================================================================
# STATE BACKEND — localstack
# ==============================================================================
#   terraform init -reconfigure -backend-config=environments/localstack/backend.hcl
#
# The bucket has to exist first; LocalStack does not create it for you:
#
#   AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=ap-southeast-1 \
#   aws --endpoint-url=http://localhost:4566 s3api create-bucket \
#       --bucket terraform-state \
#       --create-bucket-configuration LocationConstraint=ap-southeast-1
#
# `endpoint` and `force_path_style` are the pre-1.6 spellings, which is correct
# for the 1.5.7 this repository pins in .terraform-version. On 1.6+ they are
# replaced by endpoints = { s3 = ... } and use_path_style — and if they are left
# as-is there, the backend's STS call goes to real AWS instead.
# ==============================================================================

bucket = "terraform-state"
key    = "localstack/platform/terraform.tfstate"
region = "ap-southeast-1"

endpoint   = "http://localhost:4566"
access_key = "test"
secret_key = "test"

encrypt                     = false
skip_credentials_validation = true
skip_metadata_api_check     = true
skip_region_validation      = true
force_path_style            = true
