output "deploy_role_arn" {
  description = "ARN GitHub Actions assumes to deploy this config."
  value       = module.oidc_deploy_role.role_arn
}

output "cloudtrail_arn" {
  description = "CloudTrail trail ARN."
  value       = module.security_baseline.trail_arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID."
  value       = module.security_baseline.guardduty_detector_id
}

output "budget_name" {
  description = "AWS Budgets budget name."
  value       = module.budget.budget_name
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.network.private_subnet_ids
}

output "platform_data_bucket" {
  description = "Encrypted platform data bucket name."
  value       = module.data.bucket_name
}
