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
**Outputs:** `bucket_name`, `bucket_arn`

## Not built with this module, on purpose

- **The access-log buckets** (`security-baseline`, `access-log-bucket`). They're where access logs go, so they can't log to themselves, and AWS's log delivery doesn't support our own encryption keys there.
- **The state bucket** (`bootstrap/`). It's set up once, by hand, and mustn't change just because this module changed.
