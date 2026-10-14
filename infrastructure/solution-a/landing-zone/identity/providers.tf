# Runs in whichever account administers IAM Identity Center: the
# organisation's management account, or a member account it has made the
# delegated administrator for Identity Center.
provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.identity_center_account_id]

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
