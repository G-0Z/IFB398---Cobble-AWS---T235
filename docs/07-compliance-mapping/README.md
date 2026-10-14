# Deliverable 7: Compliance and assurance mapping

A lightweight mapping of the platform's controls to four frameworks. It
shows where the design supports each framework, not that Cobble is
certified against any of them. Each row is a control **the code actually
builds**, and the "not covered" lists say plainly what isn't addressed.

**In short:** the platform gives good coverage of NIST CSF's Protect and
Detect functions and of ISO 27001's technical controls. Against the
Essential Eight, Maturity Level 1 is a realistic claim once Solution A is
deployed and a backup restore has been tested. The gaps are mostly
organisational (policies, training, suppliers) or depend on the Cobble
application. If Cobble hosts critical-infrastructure tenants, the SOCI Act's
incident reporting deadlines would need a written procedure.

| Framework | Version used | Why it's here |
|---|---|---|
| [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework) | 2.0 (Feb 2024) | Common language for the whole security programme; rows are grouped by its six Functions |
| [ASD Essential Eight](https://www.cyber.gov.au/business-government/asds-cyber-security-frameworks/essential-eight/essential-eight-maturity-model) | Maturity Model, Nov 2023 | Australian Government baseline; the client is Australian |
| [ISO/IEC 27001](https://www.iso.org/standard/27001) | 2022 (Annex A: 93 controls in 4 themes) | The certification most tenants will ask about |
| SOCI Act 2018 | As amended; enhanced CIRMP rules from 10 Jun 2026 | "SOCI-style considerations" in case Cobble hosts critical-infrastructure tenants |

Status uses the [control map](../../infrastructure/README.md#control-map)'s
scale for Solution B / Solution A: **C** = Configured, **E** = Enforced,
**D** = Designed only, **—** = not covered. Control IDs follow the published
structures; check them against the NIST CSF 2.0 Core and ISO/IEC
27002:2022 before quoting them externally.

## Mapping

| # | Control (where in the code) | NIST CSF 2.0 | Essential Eight | ISO/IEC 27001:2022 Annex A | B / A |
|---|---|---|---|---|---|
| **Govern / Identify** | | | | | |
| 1 | Operations model: roles, RACI, severities, patch SLAs, quarterly access and restore reviews ([ops model](../05-deployment-operations/README.md)) | GV.RR-02, ID.IM-04, RS.MA-03 | Patch applications (timeframes, process) | 5.24, 5.26, 5.37 | D / D |
| 2 | Guide-required tags on every resource, AWS Config history ([naming §6](../naming-conventions.md#6-tags), [`account-baseline/config.tf`](../../infrastructure/modules/account-baseline/config.tf)) | ID.AM-02, ID.AM-08 | — | 5.9 (partial), 5.12 (DataClass tag) | C (tags only) / E |
| 3 | Threat model and risk register ([deliverable 6](../06-threat-model/README.md)) | ID.RA-03, ID.RA-04, ID.RA-05 | — | 5.7; ISMS clause 6.1 (risk assessment) | D / D |
| **Protect** | | | | | |
| 4 | Account per environment, OUs ([`accounts.tf`](../../infrastructure/solution-a/landing-zone/1-organization/accounts.tf)) | PR.IR-01, PR.AA-05 | Restrict admin privileges | 8.31, 5.3 | D / C |
| 5 | SCPs: regions, root, security services, leave-org ([`policies/`](../../infrastructure/solution-a/landing-zone/1-organization/policies/)) | PR.AA-05, PR.PS-01 | Restrict admin privileges | 5.15, 8.2, 8.9 | — / E |
| 6 | Identity Center groups and permission sets; 4-hour admin sessions; no IAM users ([`identity-center.tf`](../../infrastructure/solution-a/landing-zone/1-organization/identity-center.tf)) | PR.AA-01, PR.AA-03, PR.AA-05 | Restrict admin privileges; MFA (console setting) | 5.15–5.18, 8.2, 8.5 | D / C |
| 7 | CI OIDC roles: no stored keys; plan role can't read data; apply needs approval ([`github-oidc`](../../infrastructure/modules/github-oidc/)) | PR.AA-05, PR.PS-06 | Restrict admin privileges | 8.2, 8.4, 8.25, 8.32 | C / C |
| 8 | Customer-managed KMS keys, rotation on ([`workload/kms.tf`](../../infrastructure/solution-a/workload/kms.tf)) | PR.DS-01 | — | 8.24 | C / C |
| 9 | Hardened S3, account-wide public access block, EBS encryption by default ([`s3-bucket`](../../infrastructure/modules/s3-bucket/), [`account-baseline`](../../infrastructure/modules/account-baseline/)) | PR.DS-01, PR.PS-04 | — | 8.3, 8.24 | C / C |
| 10 | Three-tier VPC, database with no route out, security group chain, locked default SG ([`network`](../../infrastructure/modules/network/)) | PR.IR-01 | — | 8.20, 8.22 | C / C |
| 11 | WAF managed rules and rate limit, TLS 1.2+ ([`waf.tf`](../../infrastructure/modules/container-service/waf.tf)) | PR.IR-01, PR.DS-02 | — | 8.20, 8.21, 8.26 | — / C |
| 12 | Database: private, encrypted, forced TLS, managed secret, PITR, Multi-AZ in prod, auto minor upgrades ([`postgres-database`](../../infrastructure/modules/postgres-database/)) | PR.DS-01, PR.DS-02, PR.DS-11 | Regular backups (partial); patch applications | 8.13, 8.14, 8.24, 8.8 | — / C |
| 13 | ECS Fargate (no servers to patch), circuit breaker, separate task/execution roles ([`container-service`](../../infrastructure/modules/container-service/)) | PR.PS-02, PR.IR-03 | Patch operating systems (AWS-managed) | 8.9, 8.14, 8.19 | D / C |
| 14 | CI: fmt, validate, tests, Trivy; pinned actions; scan register ([`ci.yml`](../../.github/workflows/ci.yml), [scan findings](../03-security-controls/scan-findings.md)) | PR.PS-06, ID.RA-01 | — | 8.25, 8.28, 8.29, 8.32 | C / C |
| **Detect** | | | | | |
| 15 | Organisation CloudTrail, all regions, log validation, Object Lock ([`2-security/cloudtrail.tf`](../../infrastructure/solution-a/landing-zone/2-security/cloudtrail.tf)) | DE.CM-03, DE.CM-09, PR.PS-04 | Restrict admin privileges (privileged actions logged) | 8.15, 8.16 | C / E |
| 16 | GuardDuty, Security Hub (CIS + FSBP), Config, Access Analyzer ([`detection.tf`](../../infrastructure/solution-a/landing-zone/2-security/detection.tf)) | DE.CM-01, DE.CM-09, DE.AE-02, ID.RA-01 | — (posture checks, not vulnerability scanning) | 5.7, 8.8 (partial), 8.16 | C (GuardDuty only) / E |
| 17 | VPC flow logs ([`flow-logs.tf`](../../infrastructure/modules/network/flow-logs.tf)) | DE.CM-01 | — | 8.15, 8.16 | C / C |
| 18 | Nightly drift plan ([`drift.yml`](../../.github/workflows/drift.yml)) | DE.CM-09, PR.PS-01 | — | 8.9 | — / C |
| 19 | ECR scan on push ([`3-shared-services`](../../infrastructure/solution-a/landing-zone/3-shared-services/)) | ID.RA-01 | Patch applications (basic scanning) | 8.8 | — / C |
| **Respond / Recover** | | | | | |
| 20 | High and critical findings emailed; incident runbooks ([`alerts.tf`](../../infrastructure/solution-a/landing-zone/2-security/alerts.tf), [ops model §6](../05-deployment-operations/README.md#6-runbooks)) | DE.AE-06, RS.MA-01, RS.CO-02 | — | 5.24, 5.25, 5.26, 6.8 | D / C |
| 21 | Backups, RTO/RPO, restore test procedure ([ops model §4](../05-deployment-operations/README.md#4-backup-and-recovery)) | RC.RP-01, PR.DS-11 | Regular backups (partial) | 8.13, 5.30 | C (versioning) / C |

## Not covered

### NIST CSF 2.0

- **Govern:** organisational context (GV.OC), risk appetite (GV.RM),
  policy (GV.PO), supplier risk management (GV.SC) beyond pinned actions.
- **Identify:** a formal asset and data inventory (ID.AM), beyond tags and
  Config.
- **Protect:** awareness and training (PR.AT); *tested* backups (PR.DS-11).
- **Respond / Recover:** automated containment (RS.MI); external
  communication (RS.CO); an exercised recovery plan (RC.RP, RC.CO).

### Essential Eight

| Strategy | Position |
|---|---|
| Patch applications | Partial: managed services, scan on push, SLAs in the ops model |
| Patch operating systems | Partial: Fargate and RDS are patched by AWS |
| Multi-factor authentication | Partial: required by setting, not evidenced in code, not phishing-resistant by design |
| Restrict administrative privileges | Largely met in Solution A (SCPs, permission sets, short sessions); PlatformAdmin is still broad |
| Regular backups | Partial: point-in-time restore and versioning; **no isolated copies and no tested restore yet** |
| Application control | N/A: workforce endpoints, owned by the client's IT |
| Configure Microsoft Office macro settings | N/A: workforce endpoints |
| User application hardening | N/A: workforce endpoints |

The realistic claim for the in-scope strategies is Maturity Level 1 once
Solution A is deployed and backups are tested. AWS's Essential Eight
conformance pack for AWS Config could provide live evidence (AWS notes it
doesn't by itself ensure compliance).

### ISO/IEC 27001:2022

- **People (theme 6)** and **Physical (theme 7)**: organisational, or
  inherited from AWS under the shared responsibility model.
- Organisational controls 5.1 (policies), 5.19–5.22 (suppliers), 5.31–5.34
  (legal, privacy, records), 5.35–5.36 (independent review).
- Technological 8.7 (malware protection: GuardDuty Malware Protection not
  enabled), 8.11 (data masking), 8.12 (data leakage prevention: no Macie),
  8.10 (information deletion).

## SOCI-style considerations

Cobble isn't itself critical infrastructure. It could fall under the SOCI
Act if it holds **business-critical data** for critical-infrastructure
tenants, or provides data storage or processing to government. The data
storage and processing sector isn't among the classes covered by the
enhanced CIRMP rules that started on 10 June 2026.

| SOCI theme | What the design gives | Gap |
|---|---|---|
| Cyber incident reporting (12 hours for significant impact, 72 hours for relevant impact, to ASD) | Detection (GuardDuty, Security Hub) and alerts start the clock; the locked trail preserves evidence | No documented reporting procedure or contacts |
| Data residency and control | Region SCP keeps resources in Sydney (plus us-east-1 for global services) | DR region choice must stay in Australia |
| Supporting a tenant's risk management programme | Evidence from this mapping, CI results and Security Hub scores | No customer-facing assurance pack |
| Personnel, supply chain, physical hazards | Least privilege and access reviews; pinned CI dependencies; AWS physical security | Organisational; out of this project's scope |
