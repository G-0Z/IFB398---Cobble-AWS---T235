# People and groups in IAM Identity Center. Nothing here creates or changes
# AWS accounts or the organisation: this is only the directory of who people
# are. What they may do, and in which account, is step 1
# (1-organization/identity-center.tf), which looks these groups up by name.
#
# Before the first apply, in the AWS console (there is no API for these):
#   1. Enable IAM Identity Center (an organisation instance).
#   2. Settings > Authentication: require MFA every time users sign in.
#   3. Settings > Authentication > Standard authentication: turn on
#      "Send email OTP". Users created by Terraform have no password; with
#      this on, they get a one-time code by email the first time they sign
#      in and set their own password. Without it, an admin has to send each
#      person a one-time password by hand.

data "aws_ssoadmin_instances" "this" {}

locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  # --- Groups: who people are ----------------------------------------------
  groups = {
    platform-admins = "Run the platform: full access to every account"
    developers      = "Build Cobble modules: change dev, look at staging and prod"
    auditors        = "Review security and cost: read-only everywhere"
  }

  # --- People: one row each in users.csv -----------------------------------
  # users.csv holds names and emails, so it's kept out of Git: copy
  # users.csv.example to users.csv. With no users.csv, only the groups are
  # created. groups is a ;-separated list of the group names above.
  users_file = "${path.module}/users.csv"
  users = {
    for u in(fileexists(local.users_file) ? csvdecode(file(local.users_file)) : []) :
    u.user_name => u
  }

  memberships = merge([
    for name, u in local.users : {
      for g in split(";", u.groups) : "${name}/${trimspace(g)}" => { user = name, group = trimspace(g) }
    }
  ]...)
}

resource "aws_identitystore_group" "this" {
  for_each = local.groups

  identity_store_id = local.identity_store_id
  display_name      = "cobble-${each.key}"
  description       = each.value
}

resource "aws_identitystore_user" "this" {
  for_each = local.users

  identity_store_id = local.identity_store_id
  user_name         = each.key
  display_name      = "${each.value.given_name} ${each.value.family_name}"

  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }

  emails {
    value   = each.value.email
    primary = true
  }

  lifecycle {
    precondition {
      condition     = alltrue([for g in split(";", each.value.groups) : contains(keys(local.groups), trimspace(g))])
      error_message = "users.csv: ${each.key} has an unknown group in \"${each.value.groups}\". Use: ${join(", ", keys(local.groups))}."
    }
  }
}

resource "aws_identitystore_group_membership" "this" {
  for_each = local.memberships

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.this[each.value.group].group_id
  member_id         = aws_identitystore_user.this[each.value.user].user_id
}
