# The log archive: buckets that keep the organisation's records safe from
# the accounts that produce them.

# Access logs for the two buckets below.
module "access_logs" {
  source = "../../../modules/access-log-bucket"

  bucket_name   = "cobble-security-access-logs-${local.security_account_id}"
  force_destroy = var.force_destroy_buckets
}

# --- Audit log bucket (CloudTrail, every account) --------------------------
# Object Lock: nobody can edit or delete a log until it is
# audit_log_retention_days old, so someone who breaks in can't cover their
# tracks. After 90 days logs move to cheaper archive storage.

locals {
  trail_bucket_name = "cobble-audit-logs-${local.security_account_id}"
  trail_bucket_arn  = "arn:aws:s3:::${local.trail_bucket_name}"
}

module "trail_bucket" {
  source = "../../../modules/s3-bucket"

  bucket_name          = local.trail_bucket_name
  kms_key_arn          = aws_kms_key.security.arn
  access_log_bucket_id = module.access_logs.bucket_id
  access_log_prefix    = "audit-logs/"
  force_destroy        = var.force_destroy_buckets

  object_lock_retention_days = var.audit_log_retention_days
  object_lock_mode           = var.audit_log_lock_mode
  archive_after_days         = 90

  bucket_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "CloudTrailChecksBucket"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = local.trail_bucket_arn
        Condition = { StringEquals = { "aws:SourceArn" = local.trail_arn } }
      },
      {
        Sid       = "CloudTrailWritesManagementAccountLogs"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${local.trail_bucket_arn}/AWSLogs/${var.management_account_id}/*"
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control", "aws:SourceArn" = local.trail_arn } }
      },
      {
        Sid       = "CloudTrailWritesOrganizationLogs"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${local.trail_bucket_arn}/AWSLogs/${local.organization_id}/*"
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control", "aws:SourceArn" = local.trail_arn } }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [local.trail_bucket_arn, "${local.trail_bucket_arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
    ]
  })
}

# --- Config history bucket (AWS Config, every account) ---------------------

locals {
  config_bucket_name = "cobble-config-history-${local.security_account_id}"
  config_bucket_arn  = "arn:aws:s3:::${local.config_bucket_name}"
}

module "config_bucket" {
  source = "../../../modules/s3-bucket"

  bucket_name                        = local.config_bucket_name
  kms_key_arn                        = aws_kms_key.security.arn
  access_log_bucket_id               = module.access_logs.bucket_id
  access_log_prefix                  = "config-history/"
  force_destroy                      = var.force_destroy_buckets
  archive_after_days                 = 90
  noncurrent_version_expiration_days = 365

  bucket_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ConfigChecksBucket"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = ["s3:GetBucketAcl", "s3:ListBucket"]
        Resource  = local.config_bucket_arn
        Condition = { StringEquals = { "aws:SourceOrgID" = local.organization_id } }
      },
      {
        Sid       = "ConfigDelivers"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${local.config_bucket_arn}/AWSLogs/*/Config/*"
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control", "aws:SourceOrgID" = local.organization_id } }
      },
      {
        # Each account's Config recorder role (modules/account-baseline).
        Sid       = "OrganizationConfigRecordersDeliver"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = ["s3:GetBucketAcl", "s3:PutObject"]
        Resource  = [local.config_bucket_arn, "${local.config_bucket_arn}/AWSLogs/*/Config/*"]
        Condition = {
          StringEquals = { "aws:PrincipalOrgID" = local.organization_id }
          ArnLike      = { "aws:PrincipalArn" = "arn:aws:iam::*:role/*-config-recorder" }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [local.config_bucket_arn, "${local.config_bucket_arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
    ]
  })
}
