# Security

The controls that protect the platform, how strong each one is, what the
threat model says about what's left, what the scanners and reviews found,
and how the design lines up with the frameworks the brief named.

**In one paragraph:** nobody has a permanent password or key to AWS; every
account is its own blast radius; four guardrails hold even against
administrators; everything is encrypted at rest and in transit; only a load
balancer faces the internet; every action is recorded in logs that can't be
deleted; threats and misconfigurations are detected centrally and
automatically. The three things that must be fixed before real tenant data
arrives are tenant isolation (which the infrastructure leaves to the
application), an administrator role that can do anything everywhere, and
backups that sit in the same account as the data.

## Controls by area

The ten areas are the ones the project brief named. "Strength" uses the
scale in the [handbook README](README.md#two-words-youll-see-everywhere):
designed / configured / enforced, for Solution B / Solution A.

| Area | What's in place | Strength (B / A) | Built in | What's left |
|---|---|---|---|---|
| **Identity and access** | Single sign-on with groups and permission sets; no IAM users or long-lived keys in A; GitHub gets a read-only role (denied data reads) and an apply role behind reviewer approval; root user denied in member accounts | Designed / Configured (root denial: Enforced) | [`identity-center.tf`](../../infrastructure/solution-a/landing-zone/1-organization/identity-center.tf), [`github-oidc`](../../infrastructure/modules/github-oidc/), [`policies/`](../../infrastructure/solution-a/landing-zone/1-organization/policies/) | Admin role is `AdministratorAccess` everywhere; apply role is admin of its account; no break-glass role; B still uses IAM users |
| **MFA** | Required at every Identity Center sign-in; on each IAM user in B | Designed / Configured (console setting) | Identity Center settings, no API | Can't be enforced as code; evidenced by screenshot and access reviews. Not phishing-resistant |
| **Secrets** | No passwords in code or settings; RDS generates the admin password into Secrets Manager; the task reads it at start-up | — / Configured | [`postgres-database`](../../infrastructure/modules/postgres-database/), [`ecs.tf`](../../infrastructure/modules/container-service/ecs.tf) | App uses the database admin user; no alert on unexpected secret reads |
| **Encryption** | Customer-managed KMS key per account, rotated; encrypts database, buckets, logs, secrets; EBS encrypted by default; TLS 1.2+ at the ALB; database refuses non-TLS; audit and log buckets refuse non-HTTPS | Configured (one key) / Configured (key per account) | [`workload/kms.tf`](../../infrastructure/solution-a/workload/kms.tf), [`2-security/kms.tf`](../../infrastructure/solution-a/landing-zone/2-security/kms.tf), [`load-balancer.tf`](../../infrastructure/modules/container-service/load-balancer.tf) | Keys per environment, not per data type. HTTPS needs a certificate, which needs a domain |
| **Network segmentation** | Account per environment; three subnet layers; only the ALB is public; security-group chain ALB → tasks → database; database has no route out; default security group locked; flow logs | Configured / Configured | [`network`](../../infrastructure/modules/network/), [`security-groups.tf`](../../infrastructure/modules/container-service/security-groups.tf) | Tasks can reach any address on 443; no egress filtering; no interface endpoints |
| **Logging** | Organisation CloudTrail, all regions, integrity validation, Object Lock in a separate account; VPC flow, ALB access, S3 access and application logs | Configured (deleted on teardown) / Enforced | [`cloudtrail.tf`](../../infrastructure/solution-a/landing-zone/2-security/cloudtrail.tf), [`log-archive.tf`](../../infrastructure/solution-a/landing-zone/2-security/log-archive.tf) | No S3 object-level events; no WAF logs; trail not streamed to CloudWatch (so no CIS metric alarms) |
| **Monitoring** | GuardDuty, Security Hub (CIS v3.0 + FSBP), Config, Access Analyzer in every account, administered from Security; email on high/critical | Configured (GuardDuty only) / Enforced | [`detection.tf`](../../infrastructure/solution-a/landing-zone/2-security/detection.tf), [`alerts.tf`](../../infrastructure/solution-a/landing-zone/2-security/alerts.tf) | No application or database alarms; no dashboards; alert not yet proven end to end |
| **Vulnerability management** | ECR scan on push; Trivy on every change blocks merge; Checkov by hand; patch SLAs (7 days critical, 30 high) | Configured / Configured | [`3-shared-services`](../../infrastructure/solution-a/landing-zone/3-shared-services/), [`ci.yml`](../../.github/workflows/ci.yml) | Basic image scanning only; no Inspector on running workloads; no dependency scanning; containers run as root |
| **Incident response** | High/critical findings emailed; runbooks for outage, database, compromise, drift, WAF, cost; roles agreed | — / Configured | [`alerts.tf`](../../infrastructure/solution-a/landing-zone/2-security/alerts.tf), [operations.md](operations.md#incident-runbooks) | Email only, no paging; no regulator-reporting procedure |
| **Backup and recovery** | Point-in-time restore (7/35 days); Multi-AZ, deletion protection and final snapshot in prod; S3 versioning; locked audit logs; quarterly restore test | Configured (versioning) / Configured | [`postgres-database`](../../infrastructure/modules/postgres-database/), [operations.md](operations.md#backup-and-recovery) | **No copy outside the account or region** |

The full control-by-control map, including things like the account-pinning
in every `providers.tf` and the required tags, is the
[control map](../../infrastructure/README.md#control-map).

### What "enforced" means here

A control is enforced when a guardrail stops anyone in the account from
turning it off. In Solution A that applies to region restriction, root-user
denial, the audit trail, GuardDuty, Security Hub, Config, Access Analyzer
and flow logs. Nothing in Solution B is enforced, because guardrails need an
organisation. Everything else is configured: real and deployed, but an
administrator could change it, which is why drift detection and access
reviews exist.

## How controls are checked

- **Before a change merges:** formatting, validation, module tests against
  a mocked AWS, and a Trivy scan that fails on any finding. One approving
  review is required. See
  [infrastructure-code.md](infrastructure-code.md#checks-on-every-change).
- **After deployment:** Security Hub scores the live accounts against CIS
  and AWS best practice; the nightly drift job flags anything changed
  outside the code.
- **By people:** a quarterly access review and a quarterly restore test.

## What the scanners found

Everything found by Trivy, Checkov and the manual review, with the decision
on each, is in the [scan findings register](../03-security-controls/scan-findings.md).
The short version:

- **Trivy** (runs in CI on all 7 root configs): 0 open findings. Each
  deliberate exception is a comment beside the code with its reason.
- **Checkov** (run by hand, stricter): 75 findings across 32 checks. One was
  a real fix (the VPC default security group now has no rules). The rest
  are deliberate trade-offs (for example, no cross-region replication, 30
  to 90-day CloudWatch retention), false alarms caused by Checkov reading
  modules without their per-environment settings (HTTP, which becomes HTTPS
  with a certificate; deletion protection, which prod turns on), or
  next-phase work (streaming CloudTrail to CloudWatch, WAF logging).
- **Manual review, 7 October 2026:** five issues no scanner could see, all
  fixed. The security-services guardrail blocked turning services *off* but
  not quietly muting them; GitHub's read-only role could read bucket and log
  contents; CI only covered Solution B; the CI token had default write
  permissions and actions were pinned by movable tags; Solution A's
  filled-in settings files weren't git-ignored.

## Threat model

Scope: the AWS platform in this repository (Solution A, with notes where B
differs). Method: STRIDE at each trust boundary, rated likelihood × impact
for a production Cobble with real tenants, as the platform stands today.
The full write-up is [deliverable 6](../06-threat-model/README.md).

### Trust boundaries

| # | Boundary | Controls there |
|---|---|---|
| TB1 | Internet → load balancer | WAF (staging, prod), TLS 1.2+, security group |
| TB2 | Load balancer → tasks | Security-group reference; private subnets; no public IP |
| TB3 | Tasks → database | Security-group reference; no-route subnets; forced TLS |
| TB4 | Tasks → AWS APIs | Task role; NAT; S3 gateway endpoint |
| TB5 | GitHub → AWS | OIDC trust limited to this repository; plan role can't read data; apply role behind approval |
| TB6 | Staff → AWS | Identity Center, MFA, permission sets, 4-hour admin sessions |
| TB7 | Member accounts → Security account | Organisation trail, Object Lock, protect-security-services guardrail |
| TB8 | Registry → workloads | Organisation-only pull, immutable tags, scan on push |
| TB9 | Tenant ↔ tenant | Application only |

### Threats

| ID | Threat | Mitigated by | What's left | Rating |
|---|---|---|---|---|
| T1 | A tenant reads or changes another tenant's data through the shared database or bucket | Network path limited to ALB → app → database; encryption | Pooled tenancy; isolation depends on the application; app uses the master database user; one task role covers the whole bucket | **High** |
| T2 | A stolen admin session changes or destroys infrastructure | MFA; 4-hour sessions; guardrails; every action logged | `PlatformAdmin` is `AdministratorAccess` everywhere, including management where guardrails don't apply; no break-glass role or alert | **High** |
| T3 | A malicious pull request or compromised workflow uses the CI roles | OIDC; repo-bound trust; plan role denied data; apply behind approval; pinned actions | Apply role is admin of its account; checks can't be made mandatory on GitHub Free | Medium |
| T4 | Web attacks or floods against the public load balancer | WAF managed rules, IP reputation, rate limit; only the ALB is public | No WAF in dev; rules untuned; no WAF logs; no per-route throttling | Medium |
| T5 | Abuse goes unnoticed and can't be traced | ALB access logs; CloudTrail; GuardDuty | No WAF logs; no alarms on errors or traffic spikes | Medium |
| T6 | Compromised code exfiltrates data over open egress | KMS limits who can decrypt; public access blocked; GuardDuty | Tasks can reach any address on 443; no endpoint policies; no S3 data events | Medium |
| T7 | Data intercepted in transit | TLS 1.2+ with certificate; `rds.force_ssl` | Demo is plain HTTP until a certificate exists; the tenant data bucket doesn't deny non-TLS requests | Low |
| T8 | Someone deletes the audit trail to hide activity | Trail in a separate account; Object Lock; guardrail | Governance mode can be lifted by a privileged admin; B's trail dies on teardown | Low |
| T9 | Ransomware or account compromise deletes the database and its backups | Deletion protection, final snapshot, PITR, Multi-AZ | **No backup outside the account or region** | **High** |
| T10 | An AZ or region outage takes the service down | Two AZs; Multi-AZ database and NAT per AZ in prod; auto scaling | No recovery region (the guardrail blocks Melbourne); single NAT outside prod; no DR runbook | Medium |
| T11 | An outage is noticed by users before the team | Security findings emailed | No application or database alarms | Medium |
| T12 | A vulnerable or malicious image is deployed | Immutable tags; scan on push; org-only pull; circuit breaker | Basic scanning only; no Inspector, signing, SBOM or digest pinning; root containers | Medium |
| T13 | Someone signs in with a phished password | MFA at every sign-in | MFA not phishing-resistant; B uses IAM users | Medium |

### What would reduce the High risks

| Threat | Next step | Effort |
|---|---|---|
| T1 tenant isolation | A database user per module with least privilege; a task role per module; tenant-prefixed bucket access; row-level-security negative tests in CI | Large: needs the application |
| T2 admin access | Separate database-admin, deployment and security-auditor roles; narrow `PlatformAdmin` outside management; a monitored break-glass role with an alarm on use | Medium |
| T9 backups | AWS Backup to a vault in a separate backup account with a copy in Melbourne; Vault Lock; a timed, recorded restore | Medium |

Everything rated Medium or Low is accepted for a proof of concept and
scheduled for the next phase. The assumptions: AWS runs the underlying
infrastructure securely (shared responsibility); the application will
implement tenant isolation as the Implementation Guide specifies; staging
holds only synthetic data.

## Compliance posture

The design is mapped to four frameworks in
[deliverable 7](../07-compliance-mapping/README.md). It shows where the
platform *supports* each framework; it doesn't claim certification.

| Framework | Position |
|---|---|
| **NIST CSF 2.0** | Good coverage of Protect and Detect (identity, encryption, segmentation, logging, continuous monitoring) and of Identify through tags, Config and the threat model. Thin on Govern (policy, risk appetite, supplier management), on training, and on *exercised* recovery |
| **ASD Essential Eight** (Nov 2023 maturity model) | Of the strategies that apply to a cloud platform: restrict admin privileges largely met in Solution A (guardrails, permission sets, short sessions) though the admin role is broad; MFA required but not phishing-resistant; patching of OS and applications partly covered by managed services and scan-on-push; regular backups partial with no isolated copies and no tested restore yet. Application control, Office macros and user application hardening are workforce-endpoint concerns outside this platform. A realistic claim is Maturity Level 1 once Solution A is deployed and a restore is tested |
| **ISO/IEC 27001:2022** | Strong on the technological controls in Annex A (8.x: access, encryption, logging, monitoring, network, secure development). People and physical themes are organisational or inherited from AWS. Not covered: malware protection (GuardDuty Malware Protection off), data masking, data leakage prevention, supplier and legal controls |
| **SOCI Act 2018** | Cobble isn't critical infrastructure itself, but could fall under SOCI if it holds business-critical data for critical-infrastructure tenants. Detection and the locked trail support incident reporting (12 hours significant / 72 hours relevant impact to ASD), but there's no written reporting procedure or named contacts. The region guardrail keeps data in Australia; any DR region must too |

## Known gaps

The consolidated list, each with its planned fix. Most are scheduled in the
[next phase](deliverables.md#whats-next).

| Gap | Risk | Fix |
|---|---|---|
| Admin role has full access everywhere, including the management account where guardrails don't apply | One stolen session changes anything | Separate database-admin, deployment and security-auditor roles; narrow the admin role |
| No break-glass role or procedure | No safe way in if SSO fails; no alert on emergency access | Break-glass role in management with an alarm, and a tested procedure |
| No backups outside the account or region | Losing an account or region loses data | AWS Backup to a backup account and Melbourne; quarterly DR exercise |
| Tenant isolation is the application's job | Cross-tenant data access | Per-module database users and task roles; tenant-prefixed storage; isolation tests |
| No application or database alarms | Outages noticed by users first | CloudWatch alarms on ALB 5xx and unhealthy hosts, database CPU/storage/connections, to an on-call topic |
| No automatic deploy workflow | Deploys depend on one admin's laptop | Deploy workflow using the existing apply roles and GitHub environments |
| No guardrails against public databases or unencrypted storage | A misconfigured resource could be exposed | Two more SCPs |
| No Inspector on running workloads; basic image scanning only | Vulnerabilities in running images go unnoticed | Inspector organisation-wide; image signing and SBOM later |
| MFA is a console setting | Could be switched off without a code review | Screenshot as evidence; check at every access review |
| CloudTrail not streamed to CloudWatch; no WAF logs | No CIS metric alarms; no record of firewall decisions | Stream the trail; WAF log group per environment |
| No disaster recovery or backup accounts; recovery region blocked by the region guardrail | Region loss is unrecoverable | Add the accounts and allow Melbourne once DR is designed |
| Tasks have open egress on 443 | Exfiltration path | Interface endpoints with policies; egress filtering |
| No regulator-reporting procedure | SOCI deadlines missed if they apply | Written procedure with contacts |
