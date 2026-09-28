# Backend blocks can't reference variables, so these values are hardcoded.
# They must match the outputs of infrastructure/bootstrap/ (applied once,
# by hand, before anyone runs `terraform init` here). See bootstrap/README.md.
terraform {
  backend "s3" {
    bucket         = "cobble-tfstate-669591255093"
    key            = "poc/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "cobble-tfstate-lock"
    encrypt        = true
  }
}
