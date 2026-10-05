# CloudTrail: its own dedicated bucket, separate from the data/ module's
# platform bucket, since audit logs and application data have different
# retention/access requirements. Also streams to CloudWatch Logs for
# real-time analysis, not just batched S3 delivery.

resource "aws_s3_bucket" "trail" {
  bucket = "${var.project_name}-cloudtrail-${data.aws_caller_identity.current.account_id}"

  # PoC needs to destroy/redeploy cleanly; CloudTrail writes objects almost
  # immediately, so a plain destroy would otherwise fail on a non-empty
  # bucket. Not something to carry into a real production trail bucket.
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "trail" {
  bucket = aws_s3_bucket.trail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail" {
  bucket = aws_s3_bucket.trail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.logs.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "trail" {
  bucket = aws_s3_bucket.trail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "trail_bucket" {
  statement {
    sid       = "AWSCloudTrailAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.trail.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSCloudTrailWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.trail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "trail" {
  bucket = aws_s3_bucket.trail.id
  policy = data.aws_iam_policy_document.trail_bucket.json
}

resource "aws_cloudwatch_log_group" "trail" {
  name              = "/cobble/${var.project_name}/cloudtrail"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.logs.arn
}

data "aws_iam_policy_document" "trail_to_cloudwatch_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "trail_to_cloudwatch" {
  name               = "${var.project_name}-trail-to-cloudwatch"
  assume_role_policy = data.aws_iam_policy_document.trail_to_cloudwatch_assume.json
}

#tfsec:ignore:aws-iam-no-policy-wildcards -- the "*" here is scoped to this one log group's own streams (arn:*), not a blanket resource wildcard; this is AWS's own documented pattern for granting CloudWatch Logs write access.
data "aws_iam_policy_document" "trail_to_cloudwatch_permissions" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.trail.arn}:*"]
  }
}

resource "aws_iam_role_policy" "trail_to_cloudwatch" {
  name   = "${var.project_name}-trail-to-cloudwatch"
  role   = aws_iam_role.trail_to_cloudwatch.id
  policy = data.aws_iam_policy_document.trail_to_cloudwatch_permissions.json
}

resource "aws_cloudtrail" "this" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = aws_s3_bucket.trail.id
  kms_key_id                    = aws_kms_key.logs.arn
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.trail_to_cloudwatch.arn

  depends_on = [aws_s3_bucket_policy.trail]
}
