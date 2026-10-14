output "kms_key_arn" {
  description = "ARN of the shared logging/data KMS key."
  value       = aws_kms_key.logs.arn
}

output "trail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = aws_cloudtrail.this.arn
}

output "trail_bucket_name" {
  description = "S3 bucket holding CloudTrail logs."
  value       = module.trail_bucket.bucket_name
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID, or null when enable_guardduty is false."
  value       = one(aws_guardduty_detector.this[*].id)
}

output "access_log_bucket_id" {
  description = "Shared S3 access-log destination bucket, for other buckets' server access logging."
  value       = aws_s3_bucket.access_logs.id
}
