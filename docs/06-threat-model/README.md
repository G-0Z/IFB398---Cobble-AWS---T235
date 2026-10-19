# Deliverable 6: Threat model and risk assessment

The main security threats to the Cobble platform, what the design does
about each one, and how much risk is left. It covers the five themes in the
project brief: **multi-tenancy, privileged access, API exposure, data
protection and availability**.

**In short:** 13 threats, three rated High. (1) One tenant seeing another's
data, because keeping tenants apart is left to the application. (2) A stolen
admin session, because the admin role can do anything. (3) Losing the
database and its backups together, because there's no copy outside the
account. Each High risk has a clear next step at the end of this page.
Everything else is Medium or Low, and acceptable for a proof of concept.

**Scope:** the AWS platform in this repo (Solution A, with notes where
Solution B differs). The Cobble application's own code is out of scope, but
threats that depend on it are listed so they aren't lost.

**Method:** we looked at each point where trust changes hands (a "trust
boundary", for example internet to load balancer) and asked six questions,
the STRIDE checklist: could someone pretend to be someone else (**S**poofing),
change something (**T**ampering), deny doing it (**R**epudiation), see what
they shouldn't (**I**nformation disclosure), stop the service (**D**enial of
service), or gain more access (**E**levation of privilege)? Each threat is
then rated by likelihood × impact. The model can also be recorded in
[AWS Threat Composer](https://awslabs.github.io/threat-composer/), with its
export saved alongside this page.

## Trust boundaries

Taken from the code (see the [reference architecture](../01-reference-architecture/README.md)).

| # | Boundary | Controls at the boundary |
|---|---|---|
| TB1 | Internet → load balancer | WAF (staging, prod), TLS 1.2+, security group |
| TB2 | Load balancer → ECS tasks | Security group reference; tasks in private subnets, no public IP |
| TB3 | ECS tasks → database | Security group reference; database subnets with no route; forced TLS |
| TB4 | ECS tasks → AWS APIs (S3, Secrets Manager, KMS) | Task role; NAT; S3 gateway endpoint |
| TB5 | GitHub Actions → AWS | OIDC trust limited to this repo; plan role can't read data; apply role behind reviewer approval |
| TB6 | Staff → AWS accounts | Identity Center, MFA, permission sets, 4-hour admin sessions |
| TB7 | Member accounts → Security account | Organisation CloudTrail, Object Lock, SCP protecting security services |
| TB8 | Shared Services registry → workloads | Organisation-only pull, immutable tags, scan on push |
| TB9 | Tenant ↔ tenant | Application only |

## Threats

| ID | Theme | Boundary | Threat | STRIDE | Mitigations in the design | Residual risk | Rating |
|---|---|---|---|---|---|---|---|
| T1 | Multi-tenancy | TB9 | A tenant reads or changes another tenant's data through the shared database or bucket | I, T | Network path limited to load balancer → app → database; encryption; private database | Tenancy is pooled. Isolation depends on the application (row-level security from a validated token). The app uses the master database user and one task role covers the whole bucket | **High** |
| T2 | Privileged access | TB6 | A stolen admin session changes or destroys infrastructure | E, T | MFA; 4-hour sessions; SCPs stop disabling security services, using root, leaving the org or leaving the allowed regions; every action in the locked trail | PlatformAdmin is `AdministratorAccess` everywhere, including management (no SCPs there); no break-glass role or alert on admin use | **High** |
| T3 | Privileged access | TB5 | A malicious pull request or compromised workflow uses the CI roles | E, T | OIDC (no stored keys); trust bound to this repository; plan role denied data and log reads; apply role needs a GitHub environment approval; actions pinned to commit SHAs | Apply role is administrator in its account; no required status checks on `main` | Medium |
| T4 | API exposure | TB1 | Web attacks (injection, bad inputs) or floods against the public load balancer | S, T, D | WAF managed rules, IP reputation, rate limit (staging, prod); only the load balancer is public; `drop_invalid_header_fields` | No WAF in dev; rules not tuned in count mode; no WAF logs; no per-route throttling (no API Gateway, [key decisions](../02-landing-zone-design/README.md#key-decisions)) | Medium |
| T5 | API exposure | TB1 | Abuse goes unnoticed and can't be traced afterwards | R | ALB access logs; CloudTrail; GuardDuty | No WAF logs; no CloudWatch alarms on errors or traffic spikes | Medium |
| T6 | Data protection | TB4 | Data is exfiltrated by compromised code over open egress | I | KMS keys limit who can decrypt; S3 public access blocked; GuardDuty | Tasks can reach any internet address on 443; no interface endpoints or endpoint policies; no S3 data events in CloudTrail | Medium |
| T7 | Data protection | TB3, TB4 | Data is intercepted in transit | I | TLS 1.2+ at the load balancer (with a certificate); `rds.force_ssl` | Demo is plain HTTP until a certificate is added; data buckets don't deny non-TLS requests | Low |
| T8 | Data protection | TB7 | An insider or attacker deletes the audit trail to hide activity | R, T | Organisation trail in a separate account; Object Lock (governance mode); SCP blocks stopping or changing the trail | Governance mode can be bypassed by a privileged admin; Solution B's trail is deleted on teardown (accepted, [key decisions](../02-landing-zone-design/README.md#key-decisions)) | Low |
| T9 | Availability | TB3 | Ransomware or account compromise deletes the database and its backups | D, T | Deletion protection and final snapshot (prod); point-in-time restore; Multi-AZ | **No AWS Backup and no copy outside the account or region.** Backups live in the account that would be compromised | **High** |
| T10 | Availability | — | An AZ or region outage takes the service down | D | Two AZs; Multi-AZ database and NAT per AZ in prod; auto scaling 2–10 | No recovery region (the SCP blocks `ap-southeast-4`); single NAT in dev and staging; no DR runbook | Medium |
| T11 | Availability | — | An outage is noticed by users before the team | D | Security findings emailed | No CloudWatch alarms on load balancer 5xx, unhealthy hosts or database health | Medium |
| T12 | Supply chain | TB8 | A vulnerable or malicious container image is deployed | T, E | Immutable tags; scan on push; organisation-only pull; circuit breaker rollback | Basic scanning only; no Inspector, signing, SBOM or digest pinning; containers run as root by default | Medium |
| T13 | Spoofing | TB6 | Someone signs in as a team member with a phished password | S | MFA at every sign-in | MFA isn't phishing-resistant by design; Solution B uses IAM users | Medium |

## Risk ratings

Rating = likelihood × impact, each Low / Medium / High, judged for a
production Cobble with real tenants.

| Rating | Threats | Treatment |
|---|---|---|
| **High** | T1 tenant isolation, T2 admin access, T9 backups | Fix before real tenant data: Phase 2 priorities |
| Medium | T3, T4, T5, T6, T10, T11, T12, T13 | Planned in Phase 2; accept for the PoC |
| Low | T7, T8 | Accept, with the noted conditions |

## What would reduce the High risks

| Threat | Next step | Effort |
|---|---|---|
| T1 | A database user per module with least privilege; per-module task roles; tenant-prefixed S3 access; row-level security tests in CI (Guide §12) | Large (needs the application) |
| T2 | Separate database-admin, deployment and security-auditor roles; narrow PlatformAdmin; a monitored break-glass role ([landing zone gaps](../02-landing-zone-design/README.md#gaps)) | Medium |
| T9 | AWS Backup with a vault in a separate backup account and a copy in a second region; Vault Lock; a tested restore ([operations model §4](../05-deployment-operations/README.md#4-backup-and-recovery)) | Medium |

Assumptions: AWS operates the underlying infrastructure securely (shared
responsibility model); the application will implement tenant isolation as
the Guide specifies; staging holds only synthetic data.
