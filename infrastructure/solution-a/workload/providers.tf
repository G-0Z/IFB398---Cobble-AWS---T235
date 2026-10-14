# Run in the demo, or by GitHub Actions: already inside account_id, so no
# assume_role. Run by a person from the management account: add
# -var assume_role_name=OrganizationAccountAccessRole.
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
      Environment = var.environment
      ManagedBy   = "IaC"
      Owner       = "Cyber Security Centre"
      CostCentre  = "Cobble"
      DataClass   = "Internal"
      Criticality = var.criticality
    }
  }
}
