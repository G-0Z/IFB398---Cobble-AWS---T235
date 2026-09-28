provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Application = "Cobble"
      ManagedBy   = "Terraform"
      Component   = "tfstate-bootstrap"
    }
  }
}
