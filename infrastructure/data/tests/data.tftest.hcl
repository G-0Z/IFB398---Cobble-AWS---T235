# Plan/mock-based tests: no AWS credentials or real resources needed.
# See infrastructure/data/README.md for what this module is supposed to do.

mock_provider "aws" {
  override_data {
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }
}

variables {
  project_name         = "test"
  kms_key_arn          = "arn:aws:kms:ap-southeast-2:123456789012:key/mock-key-id"
  access_log_bucket_id = "test-access-logs-123456789012"
}

run "bucket_name_includes_project_and_account" {
  command = apply

  assert {
    condition     = aws_s3_bucket.platform_data.bucket == "test-platform-data-123456789012"
    error_message = "Bucket name should be <project_name>-platform-data-<account_id>"
  }
}

run "bucket_blocks_all_public_access" {
  command = apply

  assert {
    condition = (
      aws_s3_bucket_public_access_block.platform_data.block_public_acls &&
      aws_s3_bucket_public_access_block.platform_data.block_public_policy &&
      aws_s3_bucket_public_access_block.platform_data.ignore_public_acls &&
      aws_s3_bucket_public_access_block.platform_data.restrict_public_buckets
    )
    error_message = "Platform data bucket must block all public access"
  }
}

run "bucket_uses_kms_encryption_with_supplied_key" {
  command = apply

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.platform_data.rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms"
    error_message = "Platform data bucket must use SSE-KMS"
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.platform_data.rule).apply_server_side_encryption_by_default).kms_master_key_id == var.kms_key_arn
    error_message = "Platform data bucket must be encrypted with the supplied kms_key_arn"
  }
}

run "bucket_versioning_enabled" {
  command = apply

  assert {
    condition     = one(aws_s3_bucket_versioning.platform_data.versioning_configuration).status == "Enabled"
    error_message = "Platform data bucket must have versioning enabled"
  }
}

run "bucket_has_force_destroy_enabled" {
  command = apply

  assert {
    condition     = aws_s3_bucket.platform_data.force_destroy == true
    error_message = "PoC bucket should allow force_destroy so terraform destroy doesn't get blocked by BucketNotEmpty"
  }
}

run "bucket_access_logs_go_to_the_shared_bucket" {
  command = apply

  assert {
    condition     = aws_s3_bucket_logging.platform_data.target_bucket == var.access_log_bucket_id
    error_message = "Platform data bucket's access logs should go to the supplied access_log_bucket_id"
  }
}
