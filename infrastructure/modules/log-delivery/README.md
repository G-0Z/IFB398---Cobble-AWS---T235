# Log delivery (`log-delivery`)

**What it builds:** an encrypted CloudWatch log group, and the permission an
AWS service needs to write into it, and nothing more.

**Used by:** the audit trail (`security-baseline`) and the network traffic
logs (`network`).

## What you get

| Part | Why |
|---|---|
| Log group | Stores the logs, encrypted, for a set number of days |
| Role | Can only be used by the one AWS service named (for example, CloudTrail) |
| Role policy | Lets that service write to this one log group, and nothing else |

## Settings

| Setting | Meaning |
|---|---|
| `log_group_name` | For example `/cobble/cloudtrail` |
| `retention_in_days` | How long logs are kept |
| `kms_key_arn` | Key that encrypts the logs. Its policy must allow CloudWatch Logs |
| `role_name` | Name of the role and its policy |
| `service_principal` | The AWS service that writes the logs, for example `cloudtrail.amazonaws.com` |

**Outputs:** `log_group_arn`, `role_arn`

## Good to know

- The permission for CloudWatch Logs to use the encryption key is granted where the key is defined (`security-baseline/kms.tf`), not here.
- The policies are written in a way the tests can check for real, without AWS.
