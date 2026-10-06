output "bucket_name" {
  description = "Bucket name."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "Bucket ARN, for use in policies."
  value       = aws_s3_bucket.this.arn
}
