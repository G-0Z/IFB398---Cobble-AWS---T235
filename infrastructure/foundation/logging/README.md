## Purpose

Baseline account-level security logging: a CMK, an organisation-wide
CloudTrail trail, and GuardDuty.

## Resources created

- `aws_kms_key` + alias — shared by CloudTrail and the `data/` module's
  platform bucket. One key for the whole PoC is a documented simplification;
  target design separates keys by environment/data class.
- `aws_s3_bucket` (+ versioning, SSE-KMS, public access block, bucket policy)
  — dedicated CloudTrail log bucket, separate from application data.
- `aws_cloudtrail` — multi-region trail, log file integrity validation on.
- `aws_guardduty_detector` — enabled with default settings.

## Inputs

| Name | Description |
|---|---|
| `project_name` | Naming prefix |

## Outputs

| Name | Description |
|---|---|
| `kms_key_arn` | Shared KMS key ARN, consumed by `data/` |
| `trail_arn` | CloudTrail trail ARN |
| `trail_bucket_name` | CloudTrail log bucket name |
| `guardduty_detector_id` | GuardDuty detector ID |

## Notes

- Only one GuardDuty detector is allowed per account/region; if one already
  exists, `terraform import` it instead of applying.
- No log archive/security-tooling account separation yet (single-account PoC,
  see ADR 0003) — trail and detector live in the same account as everything
  else.
