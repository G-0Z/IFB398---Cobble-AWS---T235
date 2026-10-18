# Guardrails: Service Control Policies (SCPs). An SCP sets the maximum any
# user or role in a member account can do, even an administrator. They never
# grant permissions, only take them away. They don't apply to the management
# account.
#
# Each policy is a readable JSON file in policies/. All four are attached to
# the organisation root, so they cover every member account.

locals {
  # Role the management account (and Terraform) uses to administer member
  # accounts. Exempt from the security-services guardrail so the platform
  # team can still manage those services through Terraform.
  admin_role_arn_pattern = "arn:aws:iam::*:role/OrganizationAccountAccessRole"

  guardrails = {
    deny-leave-organization = {
      description = "Accounts cannot leave the organisation or close themselves"
      content     = file("${path.module}/policies/deny-leave-organization.json")
    }
    protect-security-services = {
      # Blocks quiet bypasses too: emptying the Config recorder, auto-archiving
      # GuardDuty findings, suppressing Security Hub findings, deleting flow logs.
      description = "CloudTrail, GuardDuty, Config, Security Hub and Access Analyzer cannot be turned off"
      content = templatefile("${path.module}/policies/protect-security-services.json.tftpl", {
        admin_role_arn_pattern = local.admin_role_arn_pattern
      })
    }
    restrict-regions = {
      description = "Resources can only be created in the allowed regions"
      content = templatefile("${path.module}/policies/restrict-regions.json.tftpl", {
        allowed_regions = jsonencode(var.allowed_regions)
      })
    }
    deny-root-user = {
      description = "The root user of member accounts cannot be used"
      content     = file("${path.module}/policies/deny-root-user.json")
    }
  }
}

resource "aws_organizations_policy" "guardrail" {
  for_each = local.guardrails

  name        = each.key
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = each.value.content
}

resource "aws_organizations_policy_attachment" "guardrail" {
  for_each = local.guardrails

  policy_id = aws_organizations_policy.guardrail[each.key].id
  target_id = local.root_id
}
