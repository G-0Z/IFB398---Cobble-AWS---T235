provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Application = "Cobble"
      Environment = "poc"
      ManagedBy   = "Terraform"
    }
  }
}
