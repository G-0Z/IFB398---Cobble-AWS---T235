# A hardened S3 bucket: the one recipe every data-holding bucket in the PoC
# uses. All four protections are always on; callers choose only the name,
# the encryption key, where access logs go, and an optional bucket policy.

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  # true in the PoC so `terraform destroy` works on a non-empty bucket.
  # A production bucket should set this to false.
  force_destroy = var.force_destroy

  # Object Lock can only be switched on when a bucket is created. null (the
  # default) leaves the setting out entirely, so existing buckets don't change.
  object_lock_enabled = var.object_lock_retention_days != null ? true : null
}

# Keeps every previous version of every object, so overwrites and deletes
# can be recovered.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypts every object with the supplied KMS key. The bucket key reduces
# KMS request costs.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

# Blocks every route to making the bucket or its objects public.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Records every request made to this bucket in the access-log bucket.
resource "aws_s3_bucket_logging" "this" {
  bucket        = aws_s3_bucket.this.id
  target_bucket = var.access_log_bucket_id
  target_prefix = var.access_log_prefix
}

resource "aws_s3_bucket_policy" "this" {
  count = var.bucket_policy_json == null ? 0 : 1

  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy_json

  # Applying a policy while the public access block is still being created
  # can fail with a conflict, so wait for it.
  depends_on = [aws_s3_bucket_public_access_block.this]
}

# --- Optional extras (off by default) ---------------------------------------

# Object Lock: objects can't be changed or deleted until they are
# object_lock_retention_days old. Used for the audit log archive in
# Solution A, so even an administrator can't erase the record of what they did.
resource "aws_s3_bucket_object_lock_configuration" "this" {
  count  = var.object_lock_retention_days != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    default_retention {
      mode = var.object_lock_mode
      days = var.object_lock_retention_days
    }
  }

  # Object Lock needs versioning on first.
  depends_on = [aws_s3_bucket_versioning.this]
}

# Lifecycle: tidies up old object versions, and optionally moves older
# objects to cheaper archive storage. Only created when at least one of the
# two settings is used.
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.noncurrent_version_expiration_days != null || var.archive_after_days != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "tidy-up"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    dynamic "noncurrent_version_expiration" {
      for_each = var.noncurrent_version_expiration_days != null ? [1] : []

      content {
        noncurrent_days = var.noncurrent_version_expiration_days
      }
    }

    dynamic "transition" {
      for_each = var.archive_after_days != null ? [1] : []

      content {
        days          = var.archive_after_days
        storage_class = "GLACIER_IR"
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}
