# Run by a person (from the management account): set assume_role_name to
# "OrganizationAccountAccessRole" in settings.auto.tfvars.
# Run by GitHub Actions (already inside this account through the apply
# role): leave assume_role_name unset.
provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.account_id]

  dynamic "assume_role" {
    for_each = var.assume_role_name == null ? [] : [var.assume_role_name]

    content {
      role_arn = "arn:aws:iam::${var.account_id}:role/${assume_role.value}"
    }
  }

  default_tags {
    tags = {
      Application = "Cobbled"
      Environment = "staging"
      ManagedBy   = "IaC"
      Owner       = "Cyber Security Centre"
      CostCentre  = "Cobble"
      DataClass   = "Internal"
      Criticality = "Low"
    }
  }
}
