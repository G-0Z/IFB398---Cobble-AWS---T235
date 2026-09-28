output "state_bucket_name" {
  description = "S3 bucket holding Terraform state. Reference this in infrastructure/backend.tf."
  value       = aws_s3_bucket.tfstate.bucket
}
