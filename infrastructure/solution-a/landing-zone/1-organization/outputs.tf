# Copy these into the settings.auto.tfvars files for steps 2 to 4.

output "organization_id" {
  description = "Organisation ID (o-...)."
  value       = aws_organizations_organization.this.id
}

output "account_ids" {
  description = "ID of each member account."
  value       = { for k, a in aws_organizations_account.this : k => a.id }
}

output "guardrails" {
  description = "Service Control Policies attached to the organisation root."
  value       = keys(local.guardrails)
}
