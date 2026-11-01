# Hardened S3 bucket (`s3-bucket`)

**What it builds:** one S3 bucket with every protection switched on. Every
bucket that holds real data is built from this one recipe, so "how are our
buckets protected?" has one answer, in one place.

**Used by:** both solutions: the audit-log buckets, the data buckets and the
locked audit archive.

## What every bucket gets

None of these can be switched off by whoever uses the module.

| Protection | Why |
|---|---|
| Versioning | A deleted or overwritten file can be recovered |
| Encryption with our own key | Data at rest is encrypted with a key we control and can audit |
| Public access blocked (all four settings) | The bucket can't be made public by mistake |
| Access logging | Every request to the bucket is recorded |

## Optional extras

| Setting | What it adds |
|---|---|
| `bucket_policy_json` | A bucket policy, when a service needs to write in (for example, CloudTrail) |
| `object_lock_retention_days`, `object_lock_mode` | Files can't be changed or deleted until a date. Used for audit logs |
| `noncurrent_version_expiration_days` | Old versions are deleted after this many days |
| `archive_after_days` | Files move to cheaper storage after this many days |
| `force_destroy` | `true` lets `terraform destroy` delete a bucket that still has files in it. For demos only |

**Required:** `bucket_name` (unique across all of AWS), `kms_key_arn`, `access_log_bucket_id`, `access_log_prefix`.

## Not built with this module, on purpose

- **The access-log buckets** (`security-baseline`, `access-log-bucket`). They're where access logs go, so they can't log to themselves, and AWS's log delivery doesn't support our own encryption keys there.
- **The state bucket** (`bootstrap/`). It's set up once, by hand, and mustn't change just because this module changed.

## Usage

How it's called in [`solution-a/landing-zone/2-security/log-archive.tf`](../../solution-a/landing-zone/2-security/log-archive.tf):

```hcl
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
```

## Reference

Generated from the module's code by [terraform-docs](https://terraform-docs.io/), so it's always
complete. Don't edit it by hand: run `terraform-docs -c ../.terraform-docs.yml .`
in this folder after changing a variable or output.

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.10 |
| aws | ~> 5.0 |

### Providers

| Name | Version |
| ---- | ------- |
| aws | ~> 5.0 |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| access\_log\_bucket\_id | Bucket that receives this bucket's server access logs. | `string` | n/a | yes |
| access\_log\_prefix | Prefix for this bucket's logs inside the access-log bucket, e.g. "platform-data/". Must be unique per bucket. | `string` | n/a | yes |
| bucket\_name | Globally unique bucket name. | `string` | n/a | yes |
| force\_destroy | Let `terraform destroy` delete the bucket even when it holds objects. true for the PoC; false for anything that must survive. | `bool` | n/a | yes |
| kms\_key\_arn | KMS key that encrypts every object in the bucket. | `string` | n/a | yes |
| archive\_after\_days | Move objects to cheaper Glacier Instant Retrieval storage after this many days. null never archives. | `number` | `null` | no |
| bucket\_policy\_json | Optional bucket policy (JSON), e.g. to let CloudTrail write to the bucket. null for no policy. | `string` | `null` | no |
| noncurrent\_version\_expiration\_days | Delete old (overwritten or deleted) object versions after this many days. null keeps them forever. | `number` | `null` | no |
| object\_lock\_mode | "GOVERNANCE" lets a specially permitted user remove a lock; "COMPLIANCE" lets nobody, not even the root user. Only used with object\_lock\_retention\_days. | `string` | `"GOVERNANCE"` | no |
| object\_lock\_retention\_days | Turn on Object Lock and keep every object locked for this many days. null (default) means no Object Lock. Can only be set when the bucket is first created. | `number` | `null` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| bucket\_arn | Bucket ARN, for use in policies. |
| bucket\_name | Bucket name. |
<!-- END_TF_DOCS -->
