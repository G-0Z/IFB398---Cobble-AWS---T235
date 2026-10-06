output "bucket_id" {
  description = "Bucket name, for other buckets' access_log_bucket_id and load balancer access logs."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "Bucket ARN."
  value       = aws_s3_bucket.this.arn
}
