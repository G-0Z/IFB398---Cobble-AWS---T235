# `security-baseline` module

## Purpose

The account's core security controls: the KMS key, CloudTrail (an audit
record of every API call), GuardDuty (threat detection), and the bucket that
collects every other bucket's access logs.

## Files

| File | Contents |
|---|---|
| `kms.tf` | The PoC's one KMS key, its policy (one statement per consumer), and alias |
| `cloudtrail.tf` | The trail, its bucket (`s3-bucket` module), its CloudWatch delivery (`log-delivery` module), and the bucket policy letting CloudTrail write |
| `access-logs.tf` | The access-log bucket, written by hand (see its header for why) |
| `guardduty.tf` | GuardDuty detector |
| `data.tf` | Current account ID and region lookups |

## Inputs

| Name | Description |
|---|---|
| `project_name` | Naming prefix |

## Outputs

| Name | Description |
|---|---|
| `kms_key_arn` | Shared KMS key, used by `network` and the platform data bucket |
| `access_log_bucket_id` | Access-log bucket, used by every `s3-bucket` |
| `trail_arn` | CloudTrail trail ARN |
| `trail_bucket_name` | CloudTrail log bucket name |
| `guardduty_detector_id` | GuardDuty detector ID |

## Notes

- One GuardDuty detector is allowed per account and region. If one already
  exists (for example, enabled by the org), see the deploy runbook's
  troubleshooting table.
- **Testing gap:** the tests replace the KMS key and bucket policies with
  empty placeholders (the mock provider can't render them), so the policies'
  content isn't tested. The trail bucket's hardening and the delivery role are
  tested in `s3-bucket` and `log-delivery`.
- Single-account PoC: no separate log-archive account yet (ADR 0001, D1).
