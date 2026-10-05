# Plan/mock-based tests: no AWS credentials or real resources needed.
# See infrastructure/modules/security-baseline/README.md for what this module does.

mock_provider "aws" {
  override_data {
    target = data.aws_caller_identity.current
    values = {
      account_id = "123456789012"
    }
  }

  # aws_iam_policy_document is a local computation, not an AWS API call, but
  # mock_provider mocks it anyway (fabricating a non-JSON placeholder). The
  # resources consuming its .json validate that input as real JSON, so it
  # needs a valid stand-in — this doesn't test the policy's actual content,
  # see the module README for a note on testing that separately.
  override_data {
    target = data.aws_iam_policy_document.kms_key
    values = {
      json = jsonencode({ Version = "2012-10-17", Statement = [] })
    }
  }

  override_data {
    target = data.aws_iam_policy_document.trail_bucket
    values = {
      json = jsonencode({ Version = "2012-10-17", Statement = [] })
    }
  }

  override_data {
    target = data.aws_iam_policy_document.trail_to_cloudwatch_assume
    values = {
      json = jsonencode({ Version = "2012-10-17", Statement = [] })
    }
  }

  override_data {
    target = data.aws_iam_policy_document.trail_to_cloudwatch_permissions
    values = {
      json = jsonencode({ Version = "2012-10-17", Statement = [] })
    }
  }

  override_data {
    target = data.aws_iam_policy_document.access_logs_bucket
    values = {
      json = jsonencode({ Version = "2012-10-17", Statement = [] })
    }
  }

  # aws_cloudtrail validates kms_key_id/cloud_watch_logs_group_arn look like
  # real ARNs at plan time; the mock's fabricated arns for brand-new
  # resources don't pass that check.
  override_resource {
    target = aws_kms_key.logs
    values = {
      arn = "arn:aws:kms:ap-southeast-2:123456789012:key/12345678-1234-1234-1234-123456789012"
    }
  }

  override_resource {
    target = aws_cloudwatch_log_group.trail
    values = {
      arn = "arn:aws:logs:ap-southeast-2:123456789012:log-group:/cobble/test/cloudtrail"
    }
  }

  override_resource {
    target = aws_iam_role.trail_to_cloudwatch
    values = {
      arn = "arn:aws:iam::123456789012:role/test-trail-to-cloudwatch"
    }
  }
}

variables {
  project_name = "test"
}

run "trail_bucket_named_with_project_and_account" {
  command = apply

  assert {
    condition     = aws_s3_bucket.trail.bucket == "test-cloudtrail-123456789012"
    error_message = "Trail bucket name should be <project_name>-cloudtrail-<account_id>"
  }
}

run "cloudtrail_is_multi_region_with_validation" {
  command = apply

  assert {
    condition     = aws_cloudtrail.this.is_multi_region_trail == true
    error_message = "CloudTrail should be multi-region"
  }

  assert {
    condition     = aws_cloudtrail.this.enable_log_file_validation == true
    error_message = "CloudTrail log file integrity validation should be enabled"
  }

  assert {
    condition     = aws_cloudtrail.this.include_global_service_events == true
    error_message = "CloudTrail should include global service events"
  }
}

run "kms_key_rotation_enabled" {
  command = apply

  assert {
    condition     = aws_kms_key.logs.enable_key_rotation == true
    error_message = "The shared logging/data KMS key must have rotation enabled"
  }
}

run "guardduty_detector_enabled" {
  command = apply

  assert {
    condition     = aws_guardduty_detector.this.enable == true
    error_message = "GuardDuty detector must be enabled"
  }
}

run "trail_bucket_blocks_public_access" {
  command = apply

  assert {
    condition = (
      aws_s3_bucket_public_access_block.trail.block_public_acls &&
      aws_s3_bucket_public_access_block.trail.restrict_public_buckets
    )
    error_message = "CloudTrail bucket must block all public access"
  }
}

run "trail_bucket_has_force_destroy_enabled" {
  command = apply

  assert {
    condition     = aws_s3_bucket.trail.force_destroy == true
    error_message = "PoC trail bucket should allow force_destroy so terraform destroy doesn't get blocked by BucketNotEmpty"
  }
}

run "cloudtrail_streams_to_cloudwatch" {
  command = apply

  assert {
    condition     = aws_cloudtrail.this.cloud_watch_logs_role_arn == aws_iam_role.trail_to_cloudwatch.arn
    error_message = "CloudTrail should stream to CloudWatch Logs via the trail_to_cloudwatch role"
  }
}

run "access_log_bucket_blocks_public_access_and_is_versioned" {
  command = apply

  assert {
    condition = (
      aws_s3_bucket_public_access_block.access_logs.block_public_acls &&
      aws_s3_bucket_public_access_block.access_logs.restrict_public_buckets
    )
    error_message = "Access-log bucket must block all public access"
  }

  assert {
    condition     = one(aws_s3_bucket_versioning.access_logs.versioning_configuration).status == "Enabled"
    error_message = "Access-log bucket must have versioning enabled"
  }
}

run "trail_bucket_logs_to_the_access_log_bucket" {
  command = apply

  assert {
    condition     = aws_s3_bucket_logging.trail.target_bucket == aws_s3_bucket.access_logs.id
    error_message = "Trail bucket's access logs should go to the shared access-log bucket"
  }
}
