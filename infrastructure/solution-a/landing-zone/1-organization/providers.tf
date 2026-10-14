# Step 1 runs in the management account (the account that owns the
# organisation), signed in as a platform administrator.
provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.management_account_id]

  default_tags {
    tags = {
      Application = "Cobbled"
      Environment = "organization"
      ManagedBy   = "IaC"
      Owner       = "Cyber Security Centre"
      CostCentre  = "Cobble"
      DataClass   = "Internal"
      Criticality = "High"
    }
  }
}
