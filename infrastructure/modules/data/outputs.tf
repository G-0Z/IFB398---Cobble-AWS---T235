output "bucket_name" {
  description = "Name of the encrypted platform data bucket."
  value       = aws_s3_bucket.platform_data.bucket
}

output "bucket_arn" {
  description = "ARN of the encrypted platform data bucket."
  value       = aws_s3_bucket.platform_data.arn
}
