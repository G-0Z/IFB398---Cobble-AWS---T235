# AWS Config: keeps a history of how every resource's settings change, and
# sends it to the central bucket in the Security account. Security Hub uses
# this to check the account against best-practice standards.

locals {
  config_bucket_arn = "arn:aws:s3:::${var.config_bucket_name}"
}

resource "aws_iam_role" "config" {
  name = "${var.name}-config-recorder"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# AWS's managed policy that lets Config read resource settings.
resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# Write access to this account's folder in the central bucket only.
resource "aws_iam_role_policy" "config_delivery" {
  name = "${var.name}-config-delivery"
  role = aws_iam_role.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:GetBucketAcl"
        Resource = local.config_bucket_arn
      },
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${local.config_bucket_arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"
      },
      {
        Effect   = "Allow"
        Action   = ["kms:GenerateDataKey", "kms:Decrypt"]
        Resource = var.config_kms_key_arn
      },
    ]
  })
}

resource "aws_config_configuration_recorder" "this" {
  name     = "${var.name}-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = "${var.name}-delivery"
  s3_bucket_name = var.config_bucket_name
  s3_kms_key_arn = var.config_kms_key_arn

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}
