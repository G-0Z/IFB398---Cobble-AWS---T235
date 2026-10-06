# Step 3 runs from the management account and works inside the Shared
# Services account through OrganizationAccountAccessRole.
provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.shared_services_account_id]

  assume_role {
    role_arn = "arn:aws:iam::${var.shared_services_account_id}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = {
      Application = "Cobbled"
      Environment = "shared"
      ManagedBy   = "IaC"
      Owner       = "Cyber Security Centre"
      CostCentre  = "Cobble"
      DataClass   = "Internal"
      Criticality = "Medium"
    }
  }
}
