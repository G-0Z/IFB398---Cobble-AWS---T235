# Mock-based tests: no AWS credentials or real resources needed.

mock_provider "aws" {}

variables {
  bucket_name          = "test-bucket-123456789012"
  kms_key_arn          = "arn:aws:kms:ap-southeast-2:123456789012:key/mock-key-id"
  access_log_bucket_id = "test-access-logs-123456789012"
  access_log_prefix    = "test-bucket/"
  force_destroy        = true
}

run "bucket_uses_the_supplied_name" {
  command = apply

  assert {
    condition     = aws_s3_bucket.this.bucket == var.bucket_name
    error_message = "Bucket should be named bucket_name"
  }
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

run "encrypts_with_the_supplied_kms_key" {
  command = apply

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms"
    error_message = "Bucket must use SSE-KMS"
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).kms_master_key_id == var.kms_key_arn
    error_message = "Bucket must be encrypted with kms_key_arn"
  }
}

run "versioning_enabled" {
  command = apply

  assert {
    condition     = one(aws_s3_bucket_versioning.this.versioning_configuration).status == "Enabled"
    error_message = "Bucket must have versioning enabled"
  }
}

run "access_logs_go_to_the_supplied_bucket_and_prefix" {
  command = apply

  assert {
    condition     = aws_s3_bucket_logging.this.target_bucket == var.access_log_bucket_id
    error_message = "Access logs should go to access_log_bucket_id"
  }

  assert {
    condition     = aws_s3_bucket_logging.this.target_prefix == var.access_log_prefix
    error_message = "Access logs should use access_log_prefix"
  }
}

run "force_destroy_follows_the_input" {
  command = apply

  assert {
    condition     = aws_s3_bucket.this.force_destroy == true
    error_message = "force_destroy should follow the input"
  }
}

run "no_bucket_policy_unless_supplied" {
  command = apply

  assert {
    condition     = length(aws_s3_bucket_policy.this) == 0
    error_message = "No bucket policy should be created when bucket_policy_json is null"
  }
}

run "bucket_policy_attached_when_supplied" {
  command = apply

  variables {
    bucket_policy_json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }

  assert {
    condition     = aws_s3_bucket_policy.this[0].policy == var.bucket_policy_json
    error_message = "Bucket policy should be attached when bucket_policy_json is set"
  }
}

# --- Optional extras used by Solution A --------------------------------------

run "defaults_add_no_object_lock_or_lifecycle" {
  command = apply

  assert {
    condition     = length(aws_s3_bucket_object_lock_configuration.this) == 0 && length(aws_s3_bucket_lifecycle_configuration.this) == 0
    error_message = "With default inputs the module must not add Object Lock or lifecycle rules (Solution B's buckets depend on this)"
  }
}

run "object_lock_keeps_objects_for_the_retention_period" {
  command = apply

  variables {
    object_lock_retention_days = 365
  }

  assert {
    condition     = aws_s3_bucket.this.object_lock_enabled == true
    error_message = "Object Lock must be enabled on the bucket"
  }

  assert {
    condition     = one(one(aws_s3_bucket_object_lock_configuration.this[0].rule).default_retention).days == 365
    error_message = "Objects must be locked for object_lock_retention_days"
  }
}

run "lifecycle_expires_old_versions_and_archives" {
  command = apply

  variables {
    noncurrent_version_expiration_days = 90
    archive_after_days                 = 30
  }

  assert {
    condition     = one(one(aws_s3_bucket_lifecycle_configuration.this[0].rule).noncurrent_version_expiration).noncurrent_days == 90
    error_message = "Old versions should expire after noncurrent_version_expiration_days"
  }

  assert {
    condition     = one(one(aws_s3_bucket_lifecycle_configuration.this[0].rule).transition).storage_class == "GLACIER_IR"
    error_message = "Objects should move to Glacier Instant Retrieval"
  }
}
