## Purpose

Baseline account-level security logging: a CMK, an organisation-wide
CloudTrail trail, and GuardDuty.

## Resources created

- `aws_kms_key` + alias — shared by CloudTrail, `network/`'s VPC flow log
  group, and the `data/` module's platform bucket. One key for the whole PoC
  is a documented simplification; target design separates keys by
  environment/data class.
- `aws_s3_bucket` (+ versioning, SSE-KMS, public access block, bucket policy,
  server access logging) — dedicated CloudTrail log bucket, separate from
  application data.
- `aws_cloudtrail` — multi-region trail, log file integrity validation on,
  also streaming to a CloudWatch Logs group (via its own IAM role) for
  real-time analysis.
- `aws_guardduty_detector` — enabled with default settings.
- `aws_s3_bucket` `access_logs` (+ versioning, SSE-S3, public access block,
  bucket policy) — shared server access-log destination for the trail bucket
  and `data/`'s platform bucket. SSE-S3 not SSE-KMS: S3 access-log delivery
  doesn't support KMS-encrypted destination buckets.

## Inputs

| Name | Description |
|---|---|
| `project_name` | Naming prefix |

## Outputs

| Name | Description |
|---|---|
| `kms_key_arn` | Shared KMS key ARN, consumed by `network/` and `data/` |
| `trail_arn` | CloudTrail trail ARN |
| `trail_bucket_name` | CloudTrail log bucket name |
| `guardduty_detector_id` | GuardDuty detector ID |
| `access_log_bucket_id` | Shared access-log destination bucket, consumed by `data/` |

## Notes

- Only one GuardDuty detector is allowed per account/region; if one already
  exists, `terraform import` it instead of applying.
- No log archive/security-tooling account separation yet (single-account
  PoC) — trail and detector live in the same account as everything else.
