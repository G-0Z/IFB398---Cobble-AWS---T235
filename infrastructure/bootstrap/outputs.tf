output "state_bucket_name" {
  description = "S3 bucket holding Terraform state. Reference this in infrastructure/backend.tf."
  value       = aws_s3_bucket.tfstate.bucket
}

output "lock_table_name" {
  description = "DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.tfstate_lock.name
}
