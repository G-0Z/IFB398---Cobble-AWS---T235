# Sign-in for people: IAM Identity Center (single sign-on). Everyone signs in
# once at the AWS access portal and picks an account and a role. There are no
# IAM users and no long-lived access keys (Implementation Guide section 3.2).
#
# The people and groups themselves are created by ../identity (apply it
# first). This file decides what each group may do, in which account.

data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn  = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  # --- Groups: who people are (created by ../identity) ---------------------
  groups = ["platform-admins", "developers", "auditors"]

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

  # Keys come from local.accounts (static), not the account resources, so
  # for_each below is known at plan and import time.
  account_names = concat(["management"], keys(local.accounts))

  assignments = concat(
    [for acct in local.account_names : { group = "platform-admins", permission_set = "PlatformAdmin", account = acct }],
    [for acct in local.account_names : { group = "auditors", permission_set = "ReadOnly", account = acct }],
    [
      { group = "developers", permission_set = "Developer", account = "dev" },
      { group = "developers", permission_set = "ReadOnly", account = "staging" },
      { group = "developers", permission_set = "ReadOnly", account = "prod" },
    ],
  )
}

data "aws_identitystore_group" "this" {
  for_each = toset(local.groups)

  identity_store_id = local.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = "cobble-${each.key}"
    }
  }
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
  principal_id       = data.aws_identitystore_group.this[each.value.group].group_id
  target_type        = "AWS_ACCOUNT"
  target_id          = local.account_ids[each.value.account]

  depends_on = [aws_ssoadmin_managed_policy_attachment.this]
}
