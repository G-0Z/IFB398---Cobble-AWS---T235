# An encrypted CloudWatch Logs group, plus the IAM role an AWS service
# (CloudTrail, VPC Flow Logs, ...) assumes to write into it, and nothing else.
#
# The policies are written with jsonencode, not aws_iam_policy_document, so
# the tests can check the real JSON offline.

resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days

  # The key's policy must allow the CloudWatch Logs service to use it; see
  # security-baseline/kms.tf.
  kms_key_id = var.kms_key_arn
}

# Only the named service can assume this role.
resource "aws_iam_role" "this" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = var.service_principal }
    }]
  })
}

# The role can only add log streams and events to this one log group.
#tfsec:ignore:aws-iam-no-policy-wildcards -- the trailing ":*" means "this log group's own streams", AWS's documented pattern for CloudWatch Logs write access, not a blanket wildcard.
resource "aws_iam_role_policy" "this" {
  name = var.role_name
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.this.arn}:*"
    }]
  })
}
