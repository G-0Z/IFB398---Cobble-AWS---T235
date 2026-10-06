# Mock-based tests: no AWS credentials or real resources needed. The IAM
# policies are built with jsonencode, so these assertions check their real
# content, not a mocked stand-in.

mock_provider "aws" {
  override_resource {
    target = aws_cloudwatch_log_group.this
    values = {
      arn = "arn:aws:logs:ap-southeast-2:123456789012:log-group:/test/logs"
    }
  }
}

variables {
  log_group_name    = "/test/logs"
  retention_in_days = 30
  kms_key_arn       = "arn:aws:kms:ap-southeast-2:123456789012:key/mock-key-id"
  role_name         = "test-log-delivery"
  service_principal = "vpc-flow-logs.amazonaws.com"
}

run "log_group_is_encrypted_with_retention" {
  command = apply

  assert {
    condition     = aws_cloudwatch_log_group.this.kms_key_id == var.kms_key_arn
    error_message = "Log group must be encrypted with kms_key_arn"
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.retention_in_days == var.retention_in_days
    error_message = "Log group retention should follow retention_in_days"
  }
}

run "only_the_named_service_can_assume_the_role" {
  command = apply

  assert {
    condition     = jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Principal.Service == var.service_principal
    error_message = "Role must trust only service_principal"
  }

  assert {
    condition     = length(jsondecode(aws_iam_role.this.assume_role_policy).Statement) == 1
    error_message = "Trust policy should have exactly one statement"
  }
}

run "role_can_write_only_to_this_log_group" {
  command = apply

  assert {
    condition     = jsondecode(aws_iam_role_policy.this.policy).Statement[0].Resource == "arn:aws:logs:ap-southeast-2:123456789012:log-group:/test/logs:*"
    error_message = "Write permission must be scoped to this log group's streams"
  }

  assert {
    condition     = toset(jsondecode(aws_iam_role_policy.this.policy).Statement[0].Action) == toset(["logs:CreateLogStream", "logs:PutLogEvents"])
    error_message = "Role should only create streams and put events"
  }
}
