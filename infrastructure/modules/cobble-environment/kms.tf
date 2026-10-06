# The environment's own encryption key. It encrypts the database, its
# backups and admin password, the data bucket, and the CloudWatch log groups.
# Each environment has its own key, so a problem in dev can never expose prod
# data (unlike Solution B's single shared key; see ADR 0001, D1).

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key" "this" {
  description             = "${local.name}: data and log encryption"
  enable_key_rotation     = true
  deletion_window_in_days = var.protect_from_deletion ? 30 : 7

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Lets IAM policies in this account control use of the key.
        Sid       = "EnableIAMPolicies"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        # Lets CloudWatch Logs encrypt this account's log groups.
        Sid       = "AllowCloudWatchLogs"
        Effect    = "Allow"
        Principal = { Service = "logs.${data.aws_region.current.name}.amazonaws.com" }
        Action    = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
        Resource  = "*"
        Condition = {
          ArnLike = { "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*" }
        }
      },
    ]
  })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${local.name}"
  target_key_id = aws_kms_key.this.key_id
}
