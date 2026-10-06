# Account-wide safety settings, applied once in every Solution A account.
# These are cheap, set-and-forget controls from the CIS AWS Foundations
# Benchmark and AWS Foundational Security Best Practices.

data "aws_caller_identity" "current" {}

# No bucket in this account can ever be made public, whatever its own settings.
resource "aws_s3_account_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Every new disk (EBS volume) is encrypted automatically.
resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}

# People sign in through IAM Identity Center, not IAM users. This policy is
# a backstop in case an IAM user is ever created (CIS 1.8 and 1.9).
resource "aws_iam_account_password_policy" "this" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  password_reuse_prevention      = 24
  max_password_age               = 90
  allow_users_to_change_password = true
}
