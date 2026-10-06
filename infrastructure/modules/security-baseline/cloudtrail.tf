# CloudTrail: records every API call in every region of the account.
# Logs go to two places:
#   - a dedicated S3 bucket (long-term, tamper-evident record), kept separate
#     from platform data because audit logs have different access rules
#   - a CloudWatch Logs group (searchable within seconds, for alerting)

locals {
  # Built from known values (not read back from the module) so the bucket
  # policy below can be fully worked out at plan time.
  trail_bucket_name = "${var.project_name}-cloudtrail-${data.aws_caller_identity.current.account_id}"
  trail_bucket_arn  = "arn:aws:s3:::${local.trail_bucket_name}"
}

module "trail_bucket" {
  source = "../s3-bucket"

  bucket_name          = local.trail_bucket_name
  kms_key_arn          = aws_kms_key.logs.arn
  access_log_bucket_id = aws_s3_bucket.access_logs.id
  access_log_prefix    = "cloudtrail-bucket-logs/"
  bucket_policy_json   = data.aws_iam_policy_document.trail_bucket.json

  # CloudTrail writes objects almost immediately, so a plain destroy would
  # fail on a non-empty bucket. Not something to carry into production.
  force_destroy = true
}

# Lets CloudTrail check the bucket's ACL and write log files into it, only
# under this account's AWSLogs/ prefix.
data "aws_iam_policy_document" "trail_bucket" {
  statement {
    sid       = "AWSCloudTrailAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [local.trail_bucket_arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSCloudTrailWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${local.trail_bucket_arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

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

module "trail_logs" {
  source = "../log-delivery"

  log_group_name    = "/${var.project_name}/cloudtrail"
  retention_in_days = 90
  kms_key_arn       = aws_kms_key.logs.arn
  role_name         = "${var.project_name}-trail-to-cloudwatch"
  service_principal = "cloudtrail.amazonaws.com"
}

resource "aws_cloudtrail" "this" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = module.trail_bucket.bucket_name
  kms_key_id                    = aws_kms_key.logs.arn
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${module.trail_logs.log_group_arn}:*"
  cloud_watch_logs_role_arn     = module.trail_logs.role_arn

  # The bucket policy must exist before CloudTrail checks it can write.
  depends_on = [module.trail_bucket]
}
