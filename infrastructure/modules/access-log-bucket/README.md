# Access-log bucket (`access-log-bucket`)

**What it builds:** a locked-down bucket that collects access logs from the
other buckets in the account, and optionally from load balancers.

**Used by:** Solution A (every account). Solution B has its own version
inside `security-baseline`.

## What you get

| Part | Why |
|---|---|
| S3 bucket, versioned | Where the logs land. Deleted or overwritten logs can be recovered |
| Public access blocked | The logs can never be made public |
| Encryption (AWS-managed) | Logs are encrypted at rest. AWS's log delivery only supports its own keys here, not ours |
| Clean-up rule | Deletes logs after `log_retention_days`, so storage doesn't grow forever |
| Bucket policy | Only AWS's logging service (and optionally load balancers) can write, and only over HTTPS |

## Settings

| Setting | Meaning | Default |
|---|---|---|
| `bucket_name` | Unique bucket name | required |
| `force_destroy` | Let `terraform destroy` delete it while it still holds logs | required |
| `log_retention_days` | Days to keep logs | 365 |
| `allow_load_balancer_logs` | Also accept load balancer access logs | `false` |

**Outputs:** `bucket_id`, `bucket_arn`

Further reading: [S3 security best practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html).
