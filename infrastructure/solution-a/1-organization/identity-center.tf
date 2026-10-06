# Sign-in for people: IAM Identity Center (single sign-on). Everyone signs in
# once at the AWS access portal and picks an account and a role. There are no
# IAM users and no long-lived access keys (Implementation Guide section 3.2).
#
# Before the first apply, in the AWS console (there is no API for these):
#   1. Enable IAM Identity Center for the organisation.
#   2. Settings > Authentication: require MFA every time users sign in.
# After apply: create users in Identity Center and add them to the groups.

data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn  = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  # --- Groups: who people are ----------------------------------------------
  groups = {
    platform-admins = "Run the platform: full access to every account"
    developers      = "Build Cobble modules: change dev, look at staging and prod"
    auditors        = "Review security and cost: read-only everywhere"
  }

  # --- Permission sets: what a role can do ---------------------------------
  # session_duration is how long a sign-in lasts (ISO 8601). Admin sessions
  # are kept short.
  permission_sets = {
    PlatformAdmin = {
      description      = "Full administrator"
      policy_arn       = "arn:aws:iam::aws:policy/AdministratorAccess"
      session_duration = "PT4H"
    }
    Developer = {
      description      = "Everything except managing users and permissions"
      policy_arn       = "arn:aws:iam::aws:policy/PowerUserAccess"
      session_duration = "PT8H"
    }
    ReadOnly = {
      description      = "Look, don't touch"
      policy_arn       = "arn:aws:iam::aws:policy/ReadOnlyAccess"
      session_duration = "PT8H"
    }
  }

  # --- Assignments: which group gets which role in which account -----------
  account_ids = merge(
    { management = var.management_account_id },
    { for k, a in aws_organizations_account.this : k => a.id },
  )

  assignments = concat(
    [for acct in keys(local.account_ids) : { group = "platform-admins", permission_set = "PlatformAdmin", account = acct }],
    [for acct in keys(local.account_ids) : { group = "auditors", permission_set = "ReadOnly", account = acct }],
    [
      { group = "developers", permission_set = "Developer", account = "dev" },
      { group = "developers", permission_set = "ReadOnly", account = "staging" },
      { group = "developers", permission_set = "ReadOnly", account = "prod" },
    ],
  )
}

resource "aws_identitystore_group" "this" {
  for_each = local.groups

  identity_store_id = local.identity_store_id
  display_name      = "cobble-${each.key}"
  description       = each.value
}

resource "aws_ssoadmin_permission_set" "this" {
  for_each = local.permission_sets

  instance_arn     = local.sso_instance_arn
  name             = "Cobble${each.key}"
  description      = each.value.description
  session_duration = each.value.session_duration
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = local.permission_sets

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
  managed_policy_arn = each.value.policy_arn
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = { for a in local.assignments : "${a.group}/${a.permission_set}/${a.account}" => a }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn
  principal_type     = "GROUP"
  principal_id       = aws_identitystore_group.this[each.value.group].group_id
  target_type        = "AWS_ACCOUNT"
  target_id          = local.account_ids[each.value.account]

  depends_on = [aws_ssoadmin_managed_policy_attachment.this]
}
