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
- the [scan findings register](scan-findings.md), which records every security scanner finding and what we decided about it.

## The controls

### Identity and access
- **What we do:** people sign in through single sign-on with groups and roles, and Solution A has no IAM users or stored keys. GitHub has one role that can only look (and can't see data) and one that can make changes after a reviewer approves. A guardrail stops the root user being used in member accounts.
- **Built in:** [`identity-center.tf`](../../infrastructure/solution-a/landing-zone/1-organization/identity-center.tf), [`github-oidc`](../../infrastructure/modules/github-oidc/), [guardrails](../../infrastructure/solution-a/landing-zone/1-organization/policies/)
- **Risk left:** the admin role and GitHub's deploy role have full access to their accounts. There's no break-glass role yet. Solution B still uses IAM users with MFA.

### MFA
- **What we do:** MFA is required at every single sign-on. In Solution B it's turned on for each IAM user. Member accounts' root users can't be used at all.
- **Built in:** an Identity Center setting (console only; AWS has no API for it).
- **Risk left:** it can't be enforced as code, so we keep a screenshot as evidence and check it in access reviews. Phishing-resistant MFA (Essential Eight, Nov 2023) isn't required yet.

### Secrets
- **What we do:** no passwords in code or settings files. AWS creates and stores the database password in Secrets Manager, and the web servers read it when they start.
- **Built in:** [`postgres-database`](../../infrastructure/modules/postgres-database/), [`container-service/ecs.tf`](../../infrastructure/modules/container-service/ecs.tf)
- **Risk left:** the application connects as the database's main user. There's no alert when a secret is read unexpectedly.

### Encryption
- **What we do:** each account has its own encryption key, rotated automatically. It encrypts storage, the database, logs and the audit trail. The load balancer and the database only accept encrypted connections (TLS 1.2 or later).
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
- **What we do:** threat detection (GuardDuty), best-practice checks (Security Hub, against CIS and AWS standards), configuration history (Config) and public-sharing checks (Access Analyzer) run in every account. The Security account manages them all, and a guardrail stops anyone muting them.
- **Built in:** [`detection.tf`](../../infrastructure/solution-a/landing-zone/2-security/detection.tf), [`protect-security-services`](../../infrastructure/solution-a/landing-zone/1-organization/policies/protect-security-services.json.tftpl)
- **Risk left:** no alarms on application or database health, and no dashboards.

### Vulnerability management
- **What we do:** application images are scanned when they're pushed. Every code change is scanned by Trivy before it can merge, and by Checkov by hand. Patch deadlines are set: 7 days for critical, 30 for high.
- **Built in:** [`3-shared-services`](../../infrastructure/solution-a/landing-zone/3-shared-services/), [`ci.yml`](../../.github/workflows/ci.yml), [operations model](../05-deployment-operations/README.md#3-patching-and-vulnerability-management)
- **Risk left:** basic image scanning only; running servers aren't scanned, and neither are code dependencies.

### Incident response
- **What we do:** high and critical findings are emailed. Runbooks cover an application outage, database failure, stolen credentials, drift, the firewall blocking real users, and a cost spike. Roles and responsibilities are agreed.
- **Built in:** [`alerts.tf`](../../infrastructure/solution-a/landing-zone/2-security/alerts.tf), [operations model](../05-deployment-operations/README.md#6-runbooks)
- **Risk left:** email only, no on-call paging. There's no step yet for reporting to the government (ASD) within 12 or 72 hours ([compliance mapping](../07-compliance-mapping/README.md#soci-style-considerations)).

### Backup and recovery
- **What we do:** the database can be restored to any point in the last 7 days (35 in prod). Prod also keeps a standby copy in a second zone, deletion protection and a final snapshot. Files are versioned, audit logs are locked, and a restore is tested every quarter.
- **Built in:** [`postgres-database`](../../infrastructure/modules/postgres-database/), [operations model](../05-deployment-operations/README.md#4-backup-and-recovery)
- **Risk left:** **no copy outside the account or region.** This is the largest recovery risk.

## How the controls are checked

- **Before a change merges:** formatting, validation, automated tests and a security scan run on every pull request, and a teammate reviews it.
- **After deployment:** Security Hub scores the live accounts against CIS and AWS best practice, and a nightly check flags anything changed outside the code.
- **By people:** an access review and a restore test every quarter ([operations model](../05-deployment-operations/README.md#5-routine-operations)).

The threats these controls answer, and the ones still open, are in the
[threat model](../06-threat-model/README.md).
