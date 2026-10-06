# Copy config_bucket_name and config_kms_key_arn into the settings for
# steps 3 and 4.

output "config_bucket_name" {
  description = "Central AWS Config bucket."
  value       = module.config_bucket.bucket_name
}

output "config_kms_key_arn" {
  description = "Key for the central Config bucket."
  value       = aws_kms_key.security.arn
}

output "audit_log_bucket_name" {
  description = "Locked bucket holding every account's CloudTrail logs."
  value       = module.trail_bucket.bucket_name
}

output "organization_trail_arn" {
  description = "The organisation-wide CloudTrail trail."
  value       = aws_cloudtrail.organization.arn
}

output "security_alerts_topic_arn" {
  description = "SNS topic for high and critical security findings."
  value       = aws_sns_topic.security_alerts.arn
}
