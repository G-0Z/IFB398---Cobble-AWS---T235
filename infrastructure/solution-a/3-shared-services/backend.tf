# State is kept in the bucket created by infrastructure/bootstrap. The
# bucket name differs per organisation, so it's supplied at init time:
#   terraform init -backend-config=backend.hcl
# Copy backend.hcl.example to backend.hcl and fill it in first.
terraform {
  backend "s3" {}
}
