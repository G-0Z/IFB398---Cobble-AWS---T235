# Mock-based tests: no AWS credentials or real resources needed.

mock_provider "aws" {
  override_data {
    target = data.aws_caller_identity.current
    values = { account_id = "123456789012" }
  }

  override_data {
    target = data.aws_elb_service_account.current
    values = { arn = "arn:aws:iam::783225319266:root" }
  }
}

variables {
  bucket_name   = "test-access-logs-123456789012"
  force_destroy = true
}

run "blocks_all_public_access" {
  command = apply

  assert {
    condition = (
      aws_s3_bucket_public_access_block.this.block_public_acls &&
      aws_s3_bucket_public_access_block.this.block_public_policy &&
      aws_s3_bucket_public_access_block.this.ignore_public_acls &&
      aws_s3_bucket_public_access_block.this.restrict_public_buckets
    )
    error_message = "All four public access block settings must be on"
  }
}

run "only_s3_logging_can_write_by_default" {
  command = apply

  assert {
    condition     = length([for s in jsondecode(aws_s3_bucket_policy.this.policy).Statement : s if s.Effect == "Allow"]) == 1
    error_message = "By default only the S3 logging service should be allowed to write"
  }

  assert {
    condition     = anytrue([for s in jsondecode(aws_s3_bucket_policy.this.policy).Statement : s.Sid == "DenyInsecureTransport" && s.Effect == "Deny"])
    error_message = "The bucket policy must refuse non-HTTPS requests"
  }
}

run "load_balancer_logs_can_be_allowed" {
  command = apply

  variables {
    allow_load_balancer_logs = true
  }

  assert {
    condition     = anytrue([for s in jsondecode(aws_s3_bucket_policy.this.policy).Statement : s.Sid == "LoadBalancerAccessLogs"])
    error_message = "allow_load_balancer_logs should add a statement for the load balancer service account"
  }
}

run "old_logs_expire" {
  command = apply

  assert {
    condition     = one(one(aws_s3_bucket_lifecycle_configuration.this.rule).expiration).days == 365
    error_message = "Logs should expire after log_retention_days"
  }
}
