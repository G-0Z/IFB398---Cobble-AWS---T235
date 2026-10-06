# `log-delivery` module

## Purpose

The one recipe for "an AWS service writes logs into an encrypted CloudWatch
Logs group". Used by CloudTrail (`security-baseline`) and VPC Flow Logs
(`network`).

## Resources created

| Resource | What it does |
|---|---|
| `aws_cloudwatch_log_group` | Stores the logs, encrypted with the supplied KMS key, for `retention_in_days` |
| `aws_iam_role` | Can be assumed only by `service_principal` (e.g. `cloudtrail.amazonaws.com`) |
| `aws_iam_role_policy` | Lets that role create log streams and put log events in this one log group, nothing else |

## Inputs

| Name | Description |
|---|---|
| `log_group_name` | e.g. `/cobble/cloudtrail` |
| `retention_in_days` | How long logs are kept |
| `kms_key_arn` | Encrypts the log group; its key policy must allow CloudWatch Logs |
| `role_name` | Name of the delivery role and its policy |
| `service_principal` | The AWS service that writes the logs |

## Outputs

| Name | Description |
|---|---|
| `log_group_arn` | Log group ARN (without `:*`) |
| `role_arn` | Delivery role ARN |

## Notes

- The IAM policies are written with `jsonencode`, so the tests check their real
  content offline, not a mocked stand-in.
- The KMS key policy grant for CloudWatch Logs lives with the key
  (`security-baseline/kms.tf`), not here.
