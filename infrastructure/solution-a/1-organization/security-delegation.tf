# Hands day-to-day running of the organisation's security services to the
# Security account (a "delegated administrator"), so nobody needs to work in
# the management account for routine security tasks. Step 2 then switches
# the services on for every account.

locals {
  security_account_id = aws_organizations_account.this["security"].id
}

# GuardDuty also runs in the management account itself.
resource "aws_guardduty_detector" "management" {
  enable = true
}

resource "aws_guardduty_organization_admin_account" "this" {
  admin_account_id = local.security_account_id

  depends_on = [aws_organizations_organization.this]
}

# Security Hub must be on in the management account before it can delegate.
resource "aws_securityhub_account" "management" {
  enable_default_standards = false
}

resource "aws_securityhub_organization_admin_account" "this" {
  admin_account_id = local.security_account_id

  depends_on = [aws_organizations_organization.this, aws_securityhub_account.management]
}

resource "aws_organizations_delegated_administrator" "config" {
  account_id        = local.security_account_id
  service_principal = "config.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "access_analyzer" {
  account_id        = local.security_account_id
  service_principal = "access-analyzer.amazonaws.com"
}
