#tfsec:ignore:aws-s3-enable-bucket-logging -- the shared access-log bucket lives in envs/poc, which gets torn down and redeployed; the state bucket must outlive it, so it can't log there. Versioning is on, so every state change is recoverable.
#trivy:ignore:AWS-0089 -- same reason as the line above (Trivy's ID for this check).
resource "aws_s3_bucket" "tfstate" {
  bucket = var.state_bucket_name

  # Deliberately no force_destroy: state bucket should never be casually deleted.

  tags = {
    Name = var.state_bucket_name
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

#tfsec:ignore:aws-s3-encryption-customer-key -- documented PoC simplification: SSE-S3 keeps bootstrap self-contained (no KMS key to manage before anything else exists). Production would use a dedicated CMK for state.
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
