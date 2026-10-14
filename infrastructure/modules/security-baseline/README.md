# Account security baseline (`security-baseline`)

**What it builds:** Solution B's core security in one package: an
encryption key, an audit trail of every action (CloudTrail), threat
detection (GuardDuty), and the bucket that collects access logs from the
other buckets.

**Used by:** Solution B. Solution A spreads the same controls across its
Security account (`landing-zone/2-security`) and the `access-log-bucket`
module.

## What's in each file

| File | Holds |
|---|---|
| `kms.tf` | The account's encryption key and who may use it |
| `cloudtrail.tf` | The audit trail, its locked-down bucket (`s3-bucket`), and its searchable copy in CloudWatch (`log-delivery`) |
| `access-logs.tf` | The access-log bucket (the header explains why it's written by hand) |
| `guardduty.tf` | Threat detection. Optional, see below |
| `data.tf` | Looks up the current account and region |

## Settings

| Setting | Meaning | Default |
|---|---|---|
| `project_name` | Name prefix | required |
| `enable_guardduty` | Turn on threat detection. Set `false` once Solution A's landing zone runs in the same account, because it then owns the one detector AWS allows | `true` |

**Outputs:** `kms_key_arn`, `access_log_bucket_id`, `trail_arn`, `trail_bucket_name`, `guardduty_detector_id`

## Good to know

- The audit trail is deleted when Solution B is torn down, an accepted trade-off for a demo platform. Solution A keeps it in a separate account where it can't be deleted.
- The automated tests can't check the content of the key and bucket policies (the pretend AWS can't render them). The bucket hardening and the log delivery role are tested in their own modules.
