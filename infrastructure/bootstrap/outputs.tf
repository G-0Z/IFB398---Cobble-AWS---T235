output "state_bucket_name" {
  description = "S3 bucket holding Terraform state. Reference this in infrastructure/envs/poc/backend.tf."
  value       = aws_s3_bucket.tfstate.bucket
}
