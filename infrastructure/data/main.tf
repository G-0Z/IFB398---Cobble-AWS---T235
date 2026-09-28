data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "platform_data" {
  bucket = "${var.project_name}-platform-data-${data.aws_caller_identity.current.account_id}"

  # PoC needs to destroy/redeploy cleanly; force_destroy lets terraform
  # destroy remove the bucket even if something has written objects into it.
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "platform_data" {
  bucket = aws_s3_bucket.platform_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "platform_data" {
  bucket = aws_s3_bucket.platform_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "platform_data" {
  bucket = aws_s3_bucket.platform_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "platform_data" {
  bucket        = aws_s3_bucket.platform_data.id
  target_bucket = var.access_log_bucket_id
  target_prefix = "platform-data-bucket-logs/"
}
