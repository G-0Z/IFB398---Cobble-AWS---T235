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
  value       = aws_s3_bucket.trail.bucket
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID."
  value       = aws_guardduty_detector.this.id
}
