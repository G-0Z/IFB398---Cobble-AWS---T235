# Deliverable 3: Security control design

The security controls that protect Cobble, grouped into the ten areas the
project brief names: what each control does, where it's built, and what
risk is left.

**In short:** no one has a permanent password or key to AWS, everything is
encrypted, only the load balancer faces the internet, every action is
recorded in logs that can't be deleted, and threats and misconfigurations
are reported automatically. The biggest gap is backups: they don't yet have
a copy outside the account.

Two companion pages go deeper:

- the [control map](../../infrastructure/README.md#control-map), which shows how finished each control is in each solution (designed, configured or enforced);
- the [scan findings register](security-controls.md#scan-findings-register), which records every security scanner finding and what we decided about it.

## The controls

### Identity and access
- **What we do:** people sign in through single sign-on with groups and roles, and Solution A's code creates no IAM users or stored keys. GitHub has one role that can only look (and can't see data) and one that can make changes from `main` through a GitHub environment, where staging and prod are meant to need a reviewer. No GitHub environments or deploy workflow exist yet, so nothing uses the GitHub roles today. A guardrail stops the root user being used in member accounts.
- **Built in:** [`identity-center.tf`](../../infrastructure/solution-a/landing-zone/1-organization/identity-center.tf), [`github-oidc`](../../infrastructure/modules/github-oidc/), [guardrails](../../infrastructure/solution-a/landing-zone/1-organization/policies/)
- **Risk left:** the admin role and GitHub's deploy role have full access to their accounts. There's no break-glass role yet. The team's own account (Solution B's account, and Solution A's management account) still has the team's IAM users in a shared full-administrator group, with access keys. Removing them is Phase 2 milestone M1 ([ADR 0001](../decisions/0001-deferred-landing-zone-design.md) D10).

### MFA
- **What we do:** MFA is required at every single sign-on. The team's remaining IAM users have MFA too, but they also have access keys, which MFA doesn't cover; removing them is M1. Member accounts' root users can't be used at all.
- **Built in:** an Identity Center setting (console only; AWS has no API for it).
- **Risk left:** it can't be enforced as code, so we keep a [screenshot](../media/screenshots/04-idc-mfa.png) as evidence and check it in access reviews. Phishing-resistant MFA (Essential Eight, Nov 2023) isn't required yet.

### Secrets
- **What we do:** no passwords in code or settings files. AWS creates and stores the database password in Secrets Manager, and the web servers read it when they start.
- **Built in:** [`postgres-database`](../../infrastructure/modules/postgres-database/), [`container-service/ecs.tf`](../../infrastructure/modules/container-service/ecs.tf)
- **Risk left:** the application connects as the database's main user. There's no alert when a secret is read unexpectedly.

### Encryption
- **What we do:** each account has its own encryption key, rotated automatically. It encrypts storage, the database, logs and the audit trail. The database only accepts encrypted connections. The load balancer uses TLS 1.2 or later once a certificate is set; until then the demo serves plain HTTP.
- **Built in:** [`workload/kms.tf`](../../infrastructure/solution-a/workload/kms.tf), [`2-security/kms.tf`](../../infrastructure/solution-a/landing-zone/2-security/kms.tf), [`load-balancer.tf`](../../infrastructure/modules/container-service/load-balancer.tf)
- **Risk left:** keys are per environment, not per type of data. HTTPS needs a certificate, which needs a domain name we don't have yet.

### Network separation
- **What we do:** a separate account per environment, and three network layers in each. Only the load balancer is public. Firewall rules chain load balancer → web servers → database, and the database has no route out.
- **Built in:** [`network`](../../infrastructure/modules/network/), [`security-groups.tf`](../../infrastructure/modules/container-service/security-groups.tf)
- **Risk left:** the web servers can reach any website over HTTPS. There's no outbound filtering.

### Logging
- **What we do:** every action in every account is recorded in one audit trail, stored in the Security account and locked against changes. Network traffic, load balancer and storage access, and application output are logged too.
- **Built in:** [`2-security/cloudtrail.tf`](../../infrastructure/solution-a/landing-zone/2-security/cloudtrail.tf), [`log-archive.tf`](../../infrastructure/solution-a/landing-zone/2-security/log-archive.tf)
- **Risk left:** reads of individual files and web firewall decisions aren't logged. Solution B's trail is deleted on teardown.

### Monitoring
- **What we do:** threat detection (GuardDuty), best-practice checks (Security Hub, against CIS and AWS standards), configuration history (Config) and public-sharing checks (Access Analyzer) run in every account. The Security account manages them all, and a guardrail stops anyone in a member account muting them (the management account's `OrganizationAccountAccessRole` is exempt).
- **Built in:** [`detection.tf`](../../infrastructure/solution-a/landing-zone/2-security/detection.tf), [`protect-security-services`](../../infrastructure/solution-a/landing-zone/1-organization/policies/protect-security-services.json.tftpl)
- **Risk left:** no alarms on application or database health, and no dashboards.

### Vulnerability management
- **What we do:** application images are scanned when they're pushed. Every code change is scanned by Trivy in CI, and by Checkov by hand. Patch deadlines are set: 7 days for critical, 30 for high.
- **Built in:** [`3-shared-services`](../../infrastructure/solution-a/landing-zone/3-shared-services/), [`ci.yml`](../../.github/workflows/ci.yml), [operations model](deployment-operations.md#3-patching-and-vulnerability-management)
- **Risk left:** basic image scanning only; running servers aren't scanned, and neither are code dependencies.

### Incident response
- **What we do:** high and critical findings are emailed (set up in the code; no alert has been received end to end yet). Runbooks cover an application outage, database failure, stolen credentials, drift, the firewall blocking real users, and a cost spike. Roles and responsibilities are agreed.
- **Built in:** [`alerts.tf`](../../infrastructure/solution-a/landing-zone/2-security/alerts.tf), [operations model](deployment-operations.md#6-runbooks)
- **Risk left:** email only, no on-call paging. There's no step yet for reporting to the government (ASD) within 12 or 72 hours ([compliance mapping](compliance-mapping.md#soci-style-considerations)).

### Backup and recovery
- **What we do:** the database can be restored to any point in the last 7 days (35 in prod). Prod also keeps a standby copy in a second zone, deletion protection and a final snapshot. Files are versioned, audit logs are locked, and a restore is tested every quarter.
- **Built in:** [`postgres-database`](../../infrastructure/modules/postgres-database/), [operations model](deployment-operations.md#4-backup-and-recovery)
- **Risk left:** **no copy outside the account or region.** This is the largest recovery risk.

## How the controls are checked

- **Before a change merges:** formatting, validation, automated tests and a security scan run on every pull request, and a teammate reviews it.
- **After deployment:** Security Hub scores the live accounts against CIS and AWS best practice, and re-running the deployment shows anything changed outside the code (a clean run reports 0 changes). A nightly drift check is built, but no environment is enrolled yet.
- **By people:** an access review and a restore test every quarter ([operations model](deployment-operations.md#5-routine-operations)).

The threats these controls answer, and the ones still open, are in the
[threat model](threat-model.md).

---

## Scan findings register

Two tools scan the code for security mistakes. This page records everything
they found and what we decided about each finding, so nothing is quietly
ignored.

**In short:** the scanner that guards every change (Trivy) reports nothing
open. The stricter second opinion (Checkov) reports 75 findings. We fixed
one, and the rest are deliberate trade-offs, false alarms, or Phase 2 work,
each explained below. A manual review found five more issues that no
scanner could see, and all five are fixed.

| Tool | Where it runs | Result |
|---|---|---|
| [Trivy](https://trivy.dev/) | Automatically on every pull request, on all 7 root configs. A finding fails the CI run; the ruleset on `main` doesn't require the CI checks, so reviewers don't approve a failing run | **0 open findings** (14 Oct 2026, Trivy 0.74.0). Each deliberate exception is a comment next to the code, giving the reason |
| [Checkov](https://www.checkov.io/) | By hand, as a stricter second opinion | **75 findings across 32 checks** (6 Oct 2026), all reviewed below |

**Why so many Checkov findings?** Checkov reads each building block on its
own, without the settings each environment gives it. So it flags "load
balancer uses HTTP" even though HTTPS switches on as soon as there's a
certificate, and "no deletion protection" even though prod turns it on.

### Fixed

| Check | Finding | Fix |
|---|---|---|
| CKV2_AWS_12 | VPC default security group allows traffic (CIS 5.4) | `restrict_default_security_group` added to `network`; on in every Solution A environment |

### Deliberate trade-offs

| Check(s) | Finding | Decision | Applies to |
|---|---|---|---|
| CKV_AWS_144, CKV2_AWS_62 | No cross-region replication; no S3 event notifications | Disaster recovery to a second region is out of scope (project plan). Notifications aren't needed. | Both |
| CKV_AWS_145, CKV_AWS_18 | Some buckets use SSE-S3, not KMS; some buckets don't log access | Access-log buckets can only use SSE-S3 and can't log to themselves (AWS limitation). The state bucket stays self-contained. | Both |
| CKV_AWS_338 | CloudWatch log retention under 1 year | 30 to 90 days in CloudWatch keeps cost down; audit logs are kept long term in S3 (Object Lock in A) | Both |
| CKV_AWS_130, CKV_AWS_333 | Public subnets assign public IPs; demo container has a public IP | Public tier by design. Solution B's demo avoids a NAT gateway (~A$62/month); its firewall only accepts the load balancer. Solution A's containers are private. | B (demo) |
| CKV_AWS_260 | Port 80 open to the internet | The load balancer is the public entry point; with a certificate, port 80 only redirects to HTTPS | Both |
| CKV_AWS_274, CKV_AWS_109, CKV_AWS_110, CKV_AWS_111, CKV_AWS_107, CKV_AWS_108, CKV_AWS_356, CKV2_AWS_40 | Broad IAM permissions | The GitHub deploy role is admin of its own account only, and can only be used from `main` through a GitHub environment (reviewers are meant for staging and prod; no environments or deploy workflow exist yet, so it's unused today); in Solution A, guardrails also limit it. The KMS key policies' `"Resource": "*"` is how KMS key policies work (it means the key itself). | Both |
| CKV_AWS_136 | ECR not encrypted with KMS | AWS-managed encryption keeps cross-account pulls simple; images hold code, not tenant data | A |
| CKV_AWS_121, CKV2_AWS_3 | Config and GuardDuty not in all regions | The restrict-regions SCP blocks every other region | A |
| CKV_AWS_394 | Availability zone data source not pinned | Zones are picked by index; a pinned list would break the module in other regions | Both |

### False alarms (Checkov can't see the settings)

| Check(s) | Finding | Why it doesn't apply |
|---|---|---|
| CKV_AWS_378, CKV_AWS_103, CKV2_AWS_20 | Load balancer uses HTTP / no TLS 1.2 / no redirect | HTTPS (TLS 1.2+) and a redirect switch on whenever `certificate_arn` is set. Plain HTTP only exists without a certificate (B's demo). |
| CKV_AWS_150, CKV_AWS_65, CKV_AWS_118 | No deletion protection, container insights or enhanced monitoring | Set per environment; deletion protection and container insights are on in prod |
| CKV2_AWS_76 | WAF missing Log4j rules | `AWSManagedRulesKnownBadInputsRuleSet`, which contains the Log4j rules, is included (`waf.tf`) |
| CKV_AWS_70 | Bucket policy allows any principal | Those statements are `Deny` (refuse non-HTTPS), or `Allow` limited by `aws:PrincipalOrgID` to the organisation |
| CKV2_AWS_61 | No lifecycle configuration | Lifecycle rules are optional inputs to `s3-bucket`; Solution A's log and data buckets set them |

### Found by manual review (7 Oct 2026)

Issues no scanner reports, because they depend on how the pieces fit together. All are fixed.

| Finding | Fix |
|---|---|
| The security-services SCP blocked turning services *off*, but not quietly disabling them: emptying the Config recorder, auto-archiving GuardDuty findings, suppressing Security Hub findings, deleting flow logs | 11 more actions denied in `1-organization/policies/protect-security-services.json.tftpl` |
| GitHub's read-only role could read the contents of buckets and logs. Anyone with a branch can open a pull request, so tenant data was reachable | `plan_no_data` policy in `modules/github-oidc/main.tf` denies it, except the state file; tested |
| The automatic checks only covered Solution B: Solution A's code and most module tests never ran | Every root config and module added to `.github/workflows/ci.yml` |
| CI's GitHub token had the repo's default permissions; actions were pinned by movable tags | `permissions: contents: read`; every action pinned to a commit hash |
| Solution A's filled-in settings files (real account IDs and emails) weren't git-ignored | Added to `.gitignore` |

### Phase 2

| Check | Finding | Plan |
|---|---|---|
| CKV2_AWS_10, CKV_AWS_252 | CloudTrail not streamed to CloudWatch / no SNS topic | Stream the organisation trail to CloudWatch and add CIS 4.x metric-filter alarms |
| CKV2_AWS_31 | WAF has no logging | Send WAF logs to a CloudWatch log group in each environment |

### How to re-run

```powershell
# Trivy (same as CI), from the repo root:
trivy config --ignorefile .trivyignore.yaml infrastructure/solution-a/workload

# Checkov:
pip install checkov
checkov -d infrastructure --framework terraform
```
