# Backend blocks can't reference variables, so these values are hardcoded.
# They must match the outputs of infrastructure/bootstrap/ (applied once,
# by hand, before anyone runs `terraform init` here). See bootstrap/README.md.
#
# Uses S3-native locking (use_lockfile, Terraform >= 1.10) instead of the
# deprecated dynamodb_table parameter. The bootstrap lock table is no
# longer needed by this config as a result.
terraform {
  backend "s3" {
    bucket       = "cobble-tfstate-669591255093"
    key          = "poc/terraform.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
    encrypt      = true
  }
}
