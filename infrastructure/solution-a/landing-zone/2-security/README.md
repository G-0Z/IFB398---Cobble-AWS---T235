# Step 2: security

Central audit logging and threat detection for every account, run from the
Security account so that people working in the environments can't switch
them off.

| | |
|---|---|
| **Builds** | A locked bucket for audit logs (they can't be changed or deleted), the organisation-wide audit trail, threat detection (GuardDuty), best-practice checks (Security Hub, against CIS v3.0 and AWS standards), configuration history, public-sharing checks (Access Analyzer), and email alerts on high and critical findings |
| **Runs in** | The Security account (plus the management account, for the trail and the delegation). After step 1, before step 3 |
| **Tear down** | `terraform destroy`. Set `force_destroy_buckets = true` first if the log buckets should go too (demo only) |
| **You fill in** | `settings.auto.tfvars` (copy the `.example`): account IDs from step 1 and an alerts email address. Set `enable_management_guardduty = false` if something else in the management account already owns its GuardDuty detector (Solution B does in the PoC account) |
| **Gives the next steps** | `config_bucket_name`, `config_kms_key_arn` |
| **Runbook** | [deploy-solution-a.md, step 2](../../../../runbooks/deploy-solution-a.md#step-2-security-account) |

| File | Holds |
|---|---|
| [`delegation.tf`](delegation.tf) | Makes this account the organisation's administrator for GuardDuty, Security Hub, Config and Access Analyzer |
| [`log-archive.tf`](log-archive.tf) | The locked audit-log bucket |
| [`cloudtrail.tf`](cloudtrail.tf) | The organisation-wide audit trail |
| [`detection.tf`](detection.tf) | Threat detection, security checks, configuration history, Access Analyzer |
| [`alerts.tf`](alerts.tf) | Sends serious findings to email |
| [`kms.tf`](kms.tf) | The Security account's encryption key |
