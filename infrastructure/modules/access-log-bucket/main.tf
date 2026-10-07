# A bucket that collects access logs from other buckets (S3 server access
# logs) and, optionally, from load balancers. Every account in Solution A has
# one, because AWS only delivers these logs to a bucket in the same account
# and region.
#
# It can't be built with the s3-bucket module, for two reasons:
#   - it is the log destination, so it doesn't log itself
#   - S3 and load balancer log delivery only support SSE-S3 encryption on the
#     destination, not KMS
#
# Solution B's security-baseline module has its own copy of this bucket,
# left as it is so Solution B's deployment never changes (ADR 0003).

data "aws_caller_identity" "current" {}

# The AWS-owned account that load balancers in this region write logs from.
data "aws_elb_service_account" "current" {}

#tfsec:ignore:aws-s3-enable-bucket-logging -- this bucket IS the access-log destination; it doesn't log itself.
#trivy:ignore:AWS-0089 -- same reason as the line above (Trivy's ID for this check).
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#tfsec:ignore:aws-s3-encryption-customer-key -- S3 server access logs and load balancer logs can only be delivered to SSE-S3 buckets, not KMS; an AWS platform constraint.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Logs are only useful for so long; old ones are deleted automatically.
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

# Who may write into the bucket: the S3 logging service (from this account
# only) and, if load balancer logs are on, this region's load balancer
# service account (under the alb/ prefix only).
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Sid       = "S3ServerAccessLogs"
        Effect    = "Allow"
        Principal = { Service = "logging.s3.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
        Condition = { StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id } }
      }],
      var.allow_load_balancer_logs ? [{
        Sid       = "LoadBalancerAccessLogs"
        Effect    = "Allow"
        Principal = { AWS = data.aws_elb_service_account.current.arn }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.this.arn}/alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }] : [],
      [{
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      }],
    )
  })

  depends_on = [aws_s3_bucket_public_access_block.this]
}
