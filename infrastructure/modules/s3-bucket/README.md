# `s3-bucket` module

## Purpose

The one recipe for a hardened S3 bucket. Every bucket that holds real data
(the CloudTrail bucket and the platform data bucket) is built from it, so
"how are our buckets protected?" has one answer, in one place.

## What every bucket gets

| Protection | Resource | Why |
|---|---|---|
| Versioning | `aws_s3_bucket_versioning` | Overwritten or deleted objects can be recovered |
| Encryption with a KMS key | `aws_s3_bucket_server_side_encryption_configuration` | Data at rest is encrypted with a key we control and audit |
| Public access blocked (all 4 settings) | `aws_s3_bucket_public_access_block` | The bucket can't be made public by mistake |
| Access logging | `aws_s3_bucket_logging` | Every request to the bucket is recorded |
| Bucket policy (optional) | `aws_s3_bucket_policy` | Only when a service needs to write in (e.g. CloudTrail) |

None of the first four can be turned off by a caller.

## Inputs

| Name | Description |
|---|---|
| `bucket_name` | Globally unique name |
| `kms_key_arn` | Key that encrypts every object |
| `access_log_bucket_id` | Where access logs go |
| `access_log_prefix` | This bucket's folder in the access-log bucket (unique per bucket) |
| `force_destroy` | `true` lets `terraform destroy` delete a non-empty bucket (PoC only) |
| `bucket_policy_json` | Optional policy JSON; default `null` (no policy) |

## Outputs

| Name | Description |
|---|---|
| `bucket_name` | Bucket name |
| `bucket_arn` | Bucket ARN |

## Not built with this module (on purpose)

- **The access-log bucket** (`security-baseline/access-logs.tf`). It is the
  log destination, so it can't log to itself, and S3 log delivery doesn't
  support KMS on the destination.
- **The Terraform state bucket** (`bootstrap/`). It's deployed once, by hand,
  and must not change because this module changed.

See [ADR 0002](../../../docs/02-landing-zone-design/adr/0002-codebase-structure-for-readability.md).
