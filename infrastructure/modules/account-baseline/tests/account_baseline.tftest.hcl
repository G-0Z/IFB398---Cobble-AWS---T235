# Mock-based tests: no AWS credentials or real resources needed.

mock_provider "aws" {
  override_data {
    target = data.aws_caller_identity.current
    values = { account_id = "123456789012" }
  }

  override_resource {
    target = aws_iam_role.config
    values = { arn = "arn:aws:iam::123456789012:role/test-config-recorder" }
  }
}

variables {
  name               = "test"
  config_bucket_name = "cobble-config-999999999999"
  config_kms_key_arn = "arn:aws:kms:ap-southeast-2:999999999999:key/mock-key-id"
}

run "no_bucket_can_be_public" {
  command = apply

  assert {
    condition = (
      aws_s3_account_public_access_block.this.block_public_acls &&
      aws_s3_account_public_access_block.this.block_public_policy &&
      aws_s3_account_public_access_block.this.ignore_public_acls &&
      aws_s3_account_public_access_block.this.restrict_public_buckets
    )
    error_message = "All four account-level public access block settings must be on"
  }
}

run "new_disks_are_encrypted" {
  command = apply

  assert {
    condition     = aws_ebs_encryption_by_default.this.enabled
    error_message = "EBS encryption by default must be on"
  }
}

run "config_records_everything_and_is_switched_on" {
  command = apply

  assert {
    condition     = one(aws_config_configuration_recorder.this.recording_group).all_supported
    error_message = "Config should record every supported resource type"
  }

  assert {
    condition     = aws_config_configuration_recorder_status.this.is_enabled
    error_message = "The Config recorder must be switched on"
  }
}

run "config_writes_only_to_this_accounts_folder" {
  command = apply

  assert {
    condition     = jsondecode(aws_iam_role_policy.config_delivery.policy).Statement[1].Resource == "arn:aws:s3:::cobble-config-999999999999/AWSLogs/123456789012/Config/*"
    error_message = "The recorder should only be able to write to its own account's folder"
  }
}
