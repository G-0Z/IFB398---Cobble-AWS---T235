# `data` module

## Purpose

One encrypted S3 bucket for platform data. Stands in for the RDS-based data
tier described in the target architecture (section 9 of the engineering
guide) — a database is out of scope for this PoC deliverable.

## Resources created

- `aws_s3_bucket` (+ versioning, SSE-KMS using the shared key from
  `security-baseline`, public access block, server access logging to the
  shared access-log bucket)

## Inputs

| Name | Description |
|---|---|
| `project_name` | Naming prefix |
| `kms_key_arn` | KMS key ARN to encrypt with (from `security-baseline`'s `kms_key_arn` output) |
| `access_log_bucket_id` | Access-log destination bucket (from `security-baseline`'s `access_log_bucket_id` output) |

## Outputs

| Name | Description |
|---|---|
| `bucket_name` | Platform data bucket name |
| `bucket_arn` | Platform data bucket ARN |
