# The Security account's encryption key. It encrypts the audit logs, the
# central Config history and the security alert messages. Each statement
# below lets one AWS service (or the organisation's Config recorders) use it.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_organizations_organization" "this" {}

locals {
  security_account_id = data.aws_caller_identity.current.account_id
  organization_id     = data.aws_organizations_organization.this.id
  region              = data.aws_region.current.name

  trail_name = "cobble-organization-trail"
  trail_arn  = "arn:aws:cloudtrail:${local.region}:${var.management_account_id}:trail/${local.trail_name}"
}

resource "aws_kms_key" "security" {
  description             = "Cobble security: audit logs, Config history, alerts"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableIAMPolicies"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.security_account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "CloudTrailEncryptsOrganizationLogs"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "kms:GenerateDataKey*"
        Resource  = "*"
        Condition = {
          StringLike   = { "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:*:${var.management_account_id}:trail/*" }
          StringEquals = { "aws:SourceArn" = local.trail_arn }
        }
      },
      {
        Sid       = "CloudTrailDescribesKey"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "kms:DescribeKey"
        Resource  = "*"
      },
      {
        Sid       = "ConfigServiceDelivers"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = ["kms:GenerateDataKey", "kms:Decrypt"]
        Resource  = "*"
        Condition = { StringEquals = { "aws:SourceOrgID" = local.organization_id } }
      },
      {
        # Each account's Config recorder role writes through S3.
        Sid       = "OrganizationConfigRecordersDeliver"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = ["kms:GenerateDataKey", "kms:Decrypt"]
        Resource  = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.organization_id
            "kms:ViaService"     = "s3.${local.region}.amazonaws.com"
          }
          ArnLike = { "aws:PrincipalArn" = "arn:aws:iam::*:role/*-config-recorder" }
        }
      },
      {
        Sid       = "EventBridgePublishesAlerts"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = ["kms:GenerateDataKey*", "kms:Decrypt"]
        Resource  = "*"
        Condition = { StringEquals = { "aws:SourceAccount" = local.security_account_id } }
      },
    ]
  })
}

resource "aws_kms_alias" "security" {
  name          = "alias/cobble-security"
  target_key_id = aws_kms_key.security.key_id
}
