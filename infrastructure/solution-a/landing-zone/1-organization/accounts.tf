# The five member accounts. Separate accounts are the strongest isolation AWS
# offers: a mistake or breach in dev can't reach prod's data, and each
# account's bill is separate.
#
# Simplification: the AWS Security Reference Architecture uses two security
# accounts (Log Archive and Security Tooling). We combine them into one to
# halve the fixed cost; splitting them later is a Phase 2 option.

locals {
  # An account whose email is left out (null) isn't created.
  accounts = { for k, a in local.all_accounts : k => a if a.email != null }

  all_accounts = {
    security = {
      name  = "cobble-security"
      email = var.account_emails.security
      ou_id = aws_organizations_organizational_unit.security.id
    }
    shared_services = {
      name  = "cobble-shared-services"
      email = var.account_emails.shared_services
      ou_id = aws_organizations_organizational_unit.infrastructure.id
    }
    dev = {
      name  = "cobble-dev"
      email = var.account_emails.dev
      ou_id = aws_organizations_organizational_unit.non_production.id
    }
    staging = {
      name  = "cobble-staging"
      email = var.account_emails.staging
      ou_id = aws_organizations_organizational_unit.non_production.id
    }
    prod = {
      name  = "cobble-prod"
      email = var.account_emails.prod
      ou_id = aws_organizations_organizational_unit.production.id
    }
  }
}

resource "aws_organizations_account" "this" {
  for_each = local.accounts

  name      = each.value.name
  email     = each.value.email
  parent_id = each.value.ou_id

  # The role the management account uses to administer the new account.
  # Steps 2 to 4 sign in through it.
  role_name = "OrganizationAccountAccessRole"

  # Leaving the organisation is a deliberate, manual act; never a side
  # effect of `terraform destroy`.
  close_on_deletion = false

  lifecycle {
    prevent_destroy = true

    # AWS doesn't report these back after creation, so Terraform would
    # otherwise think they keep changing.
    ignore_changes = [role_name, iam_user_access_to_billing]
  }
}
