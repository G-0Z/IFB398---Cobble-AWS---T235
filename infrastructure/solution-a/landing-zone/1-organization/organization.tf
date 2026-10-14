# The AWS Organization and its folders (organisational units, OUs).
#
# The OU layout follows the AWS Security Reference Architecture:
#
#   Root
#   ├── Security        security account (log archive and security tooling)
#   ├── Infrastructure  shared services account (container images)
#   └── Workloads
#       ├── NonProduction   dev, staging
#       └── Production      prod
#
# If the organisation already exists (it does in the PoC account), bring it
# under Terraform's control once, before the first apply:
#   terraform import aws_organizations_organization.this <organization-id>

resource "aws_organizations_organization" "this" {
  feature_set          = "ALL"
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]

  # AWS services allowed to work across every account in the organisation.
  aws_service_access_principals = [
    "access-analyzer.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
  ]
}

locals {
  root_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "non_production" {
  name      = "NonProduction"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_organizational_unit" "production" {
  name      = "Production"
  parent_id = aws_organizations_organizational_unit.workloads.id
}
