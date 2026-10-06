provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.account_id]

  default_tags {
    tags = {
      Application = "Cobbled"
      ManagedBy   = "IaC"
      Component   = "tfstate-bootstrap"
      Owner       = "IFB398-T235"
      CostCentre  = "IFB398-capstone"
      DataClass   = "Internal"
      Criticality = "Low"
    }
  }
}
