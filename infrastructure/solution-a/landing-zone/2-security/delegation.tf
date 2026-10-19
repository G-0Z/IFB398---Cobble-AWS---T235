# Hands day-to-day running of the organisation's security services to this
# account (a "delegated administrator"), so nobody needs to work in the
# management account for routine security tasks.
#
# These live here, not in step 1, so one dependency graph orders them:
#   apply:   service on here -> delegate -> organisation-wide settings
#   destroy: organisation-wide settings -> undelegate -> service off here
# AWS refuses to switch a service off in its delegated administrator, so a
# separate step 1 resource made `terraform destroy` of this step impossible.

# GuardDuty also runs in the management account itself, unless something
# else there already owns its one detector (Solution B, in the PoC account).
resource "aws_guardduty_detector" "management" {
  count    = var.enable_management_guardduty ? 1 : 0
  provider = aws.management

  enable = true
}

resource "aws_guardduty_organization_admin_account" "this" {
  provider = aws.management

  admin_account_id = local.security_account_id

  depends_on = [aws_guardduty_detector.this, aws_guardduty_detector.management]
}

# Security Hub must be on in the management account before it can delegate.
resource "aws_securityhub_account" "management" {
  provider = aws.management

  enable_default_standards = false
}

resource "aws_securityhub_organization_admin_account" "this" {
  provider = aws.management

  admin_account_id = local.security_account_id

  depends_on = [aws_securityhub_account.this, aws_securityhub_account.management]
}

resource "aws_organizations_delegated_administrator" "config" {
  provider = aws.management

  account_id        = local.security_account_id
  service_principal = "config.amazonaws.com"
}

# Needs the Access Analyzer service-linked role step 1 creates.
resource "aws_organizations_delegated_administrator" "access_analyzer" {
  provider = aws.management

  account_id        = local.security_account_id
  service_principal = "access-analyzer.amazonaws.com"
}
