# `access-log-bucket` module

**In one sentence:** a locked-down bucket that collects access logs from the
other buckets in the account, and optionally from load balancers.

**Used by:** Solution A (every account). Solution B has its own copy inside
`security-baseline`, deliberately left unchanged (ADR 0003).

## What it creates

| Resource | Why |
|---|---|
| S3 bucket | The log destination |
| Versioning | Deleted or overwritten logs can be recovered |
| Public access block | No way to make the logs public |
| SSE-S3 encryption | Logs are encrypted at rest (AWS only supports SSE-S3 for log delivery, not KMS) |
| Lifecycle rule | Deletes logs after `log_retention_days` so storage doesn't grow forever |
| Bucket policy | Only the S3 logging service (and optionally load balancers) can write; HTTPS only |

## Inputs

| Name | Meaning | Default |
|---|---|---|
| `bucket_name` | Globally unique bucket name | required |
| `force_destroy` | Allow `terraform destroy` to delete a non-empty bucket | required |
| `log_retention_days` | Days to keep logs | 365 |
| `allow_load_balancer_logs` | Also accept ALB access logs | false |

## Outputs

`bucket_id`, `bucket_arn`

## Best practice

- S3 server access logging: [AWS S3 security best practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- Enforce HTTPS with `aws:SecureTransport`: same page, "Enforce encryption of data in transit"
