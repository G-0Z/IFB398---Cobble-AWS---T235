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

Taken from the code (see the [reference architecture](reference-architecture.md)).

| # | Boundary | Controls at the boundary |
|---|---|---|
| TB1 | Internet → load balancer | WAF (staging, prod), TLS 1.2+, security group |
| TB2 | Load balancer → ECS tasks | Security group reference; tasks in private subnets, no public IP |
| TB3 | ECS tasks → database | Security group reference; database subnets with no route; forced TLS |
| TB4 | ECS tasks → AWS APIs (S3, Secrets Manager, KMS) | Task role; NAT; S3 gateway endpoint |
| TB5 | GitHub Actions → AWS | OIDC trust limited to this repo; plan role can't read data; apply role trusted only from `main` through a GitHub environment (reviewers meant for staging and prod). No environments or deploy workflow exist yet and CI doesn't sign in to AWS, so nothing crosses this boundary today |
| TB6 | Staff → AWS accounts | Identity Center, MFA, permission sets, 4-hour admin sessions |
| TB7 | Member accounts → Security account | Organisation CloudTrail, Object Lock, SCP protecting security services |
| TB8 | Shared Services registry → workloads | Organisation-only pull, immutable tags, scan on push |
| TB9 | Tenant ↔ tenant | Application only |

## Threats

| ID | Theme | Boundary | Threat | STRIDE | Mitigations in the design | Residual risk | Rating |
|---|---|---|---|---|---|---|---|
| T1 | Multi-tenancy | TB9 | A tenant reads or changes another tenant's data through the shared database or bucket | I, T | Network path limited to load balancer → app → database; encryption; private database | Tenancy is pooled. Isolation depends on the application (row-level security from a validated token). The app uses the master database user and one task role covers the whole bucket | **High** |
| T2 | Privileged access | TB6 | A stolen admin session changes or destroys infrastructure | E, T | MFA; 4-hour sessions; SCPs stop disabling security services, using root, leaving the org or leaving the allowed regions; every action in the locked trail | PlatformAdmin is `AdministratorAccess` everywhere, including management (no SCPs there); no break-glass role or alert on admin use | **High** |
| T3 | Privileged access | TB5 | A malicious pull request or compromised workflow uses the CI roles | E, T | OIDC (no stored keys); trust bound to this repository; plan role denied data and log reads; apply role trusted only from `main` through a GitHub environment, with reviewers meant for staging and prod; actions pinned to commit SHAs | Apply role is administrator in its account; no GitHub environments or reviewers set up yet (nothing uses the role today); no required status checks on `main` | Medium |
| T4 | API exposure | TB1 | Web attacks (injection, bad inputs) or floods against the public load balancer | S, T, D | WAF managed rules, IP reputation, rate limit (staging, prod); only the load balancer is public; `drop_invalid_header_fields` | No WAF in dev; rules not tuned in count mode; no WAF logs; no per-route throttling (no API Gateway, [key decisions](landing-zone-design.md#key-decisions)) | Medium |
| T5 | API exposure | TB1 | Abuse goes unnoticed and can't be traced afterwards | R | ALB access logs; CloudTrail; GuardDuty | No WAF logs; no CloudWatch alarms on errors or traffic spikes | Medium |
| T6 | Data protection | TB4 | Data is exfiltrated by compromised code over open egress | I | KMS keys limit who can decrypt; S3 public access blocked; GuardDuty | Tasks can reach any internet address on 443; no interface endpoints or endpoint policies; no S3 data events in CloudTrail | Medium |
| T7 | Data protection | TB3, TB4 | Data is intercepted in transit | I | TLS 1.2+ at the load balancer (with a certificate); `rds.force_ssl` | Demo is plain HTTP until a certificate is added; data buckets don't deny non-TLS requests | Low |
| T8 | Data protection | TB7 | An insider or attacker deletes the audit trail to hide activity | R, T | Organisation trail in a separate account; Object Lock (governance mode); SCP blocks stopping or changing the trail | Governance mode can be bypassed by a privileged admin; Solution B's trail is deleted on teardown (accepted, [key decisions](landing-zone-design.md#key-decisions)) | Low |
| T9 | Availability | TB3 | Ransomware or account compromise deletes the database and its backups | D, T | Deletion protection and final snapshot (prod); point-in-time restore; Multi-AZ | **No AWS Backup and no copy outside the account or region.** Backups live in the account that would be compromised | **High** |
| T10 | Availability | Whole platform | An AZ or region outage takes the service down | D | Two AZs; Multi-AZ database and NAT per AZ in prod; auto scaling 2–10 | No recovery region (the SCP blocks `ap-southeast-4`); single NAT in dev and staging; no DR runbook | Medium |
| T11 | Availability | Whole platform | An outage is noticed by users before the team | D | Security findings emailed | No CloudWatch alarms on load balancer 5xx, unhealthy hosts or database health | Medium |
| T12 | Supply chain | TB8 | A vulnerable or malicious container image is deployed | T, E | Immutable tags; scan on push; organisation-only pull; circuit breaker rollback | Basic scanning only; no Inspector, signing, SBOM or digest pinning; containers run as root by default | Medium |
| T13 | Spoofing | TB6 | Someone signs in as a team member with a phished password | S | MFA at every sign-in | MFA isn't phishing-resistant by design; the team's IAM users, with access keys MFA doesn't cover, remain in the management account until M1 | Medium |

## Risk ratings

Rating = likelihood × impact, each Low / Medium / High, judged for a
production Cobble with real tenants.

| Rating | Threats | Treatment |
|---|---|---|
| **High** | T1 tenant isolation, T2 admin access, T9 backups | Fix before tenant data or a first module: T2 in Phase 2's M1, T9 in M4; T1 needs Cobble's own code |
| Medium | T3, T4, T5, T6, T10, T11, T12, T13 | Recommended follow-on work; accept for the PoC |
| Low | T7, T8 | Accept, with the noted conditions |

## How this page relates to the detailed risk assessment

The [threat model and risk assessment](threat-model.md#detailed-risk-assessment)
(10 October) and the [risk management plan](threat-model.md#risk-management-plan) (19 October)
look at the same platform in more depth. They score each threat from 1 to 5
for likelihood and impact, and give each risk an owner and a contingency.
They rate residual risk **once the proposed controls are in place**. This
page rates it **as the platform stands today**, with some of those controls
designed but not yet built or tested. So the ratings differ on purpose, and
the priorities are the same:

| This page (today) | Detailed assessment | Before controls | After the proposed controls |
|---|---|---|---|
| T1 Tenant isolation: **High** | T01 Cross-tenant data access | High (15) | Low |
| T2 Admin access: **High** | T02 Compromise of privileged AWS access | High (15) | Medium |
| T9 Backups: **High** | T09 Backup failure or unrecoverable data loss | High (15) | Medium |

A High threat here only comes down once its control has been tested, not
just written: a cross-tenant test (T1), narrowed admin roles with an alarm
on break-glass use (T2), and a restore from a backup kept outside the
account (T9).

## What would reduce the High risks

| Threat | Next step | Effort |
|---|---|---|
| T1 | A database user per module with least privilege; per-module task roles; tenant-prefixed S3 access; row-level security tests in CI (Guide §12) | Large (needs the application) |
| T2 | Separate database-admin, deployment and security-auditor roles; narrow PlatformAdmin; a monitored break-glass role ([landing zone gaps](landing-zone-design.md#gaps)) | Medium |
| T9 | AWS Backup with a vault in a separate backup account and a tested restore (Phase 2, M4); later a copy in a second region and Vault Lock ([operations model §4](deployment-operations.md#4-backup-and-recovery)) | Medium |

Assumptions: AWS operates the underlying infrastructure securely (shared
responsibility model); the application will implement tenant isolation as
the Guide specifies; staging holds only synthetic data.

---

## Detailed risk assessment

- **Status:** Final
- **Date:** 2026-10-10
- **Author:** Timothy Hartmann
- **Reviewed by:** T235

### 1. Purpose and Scope

This document provides a practical threat model and risk assessment for the proposed Cobbled AWS environment. Its purpose is to identify key cloud security threats that could affect the confidentiality, integrity and availability of the platform, and to document practical controls that can reduce those risks. 

This assessment focuses on the areas considered most relevant to the Cobbled architecture and Proof of Concept (PoC), including:

- Multi-Tenancy and unauthorised access between tenants 
- Privileged access to AWS resources and administrative functions
- Public and internal API exposure
- Protection of application data, credentials and secrets
- Service availability and resilience
- Infrastructure and Terraform configuration risks
- Logging, monitoring and recovery

The assessment considers both the current PoC and the proposed production architecture. The PoC is intentionally lightweight and cost-conscious, while the target production platform includes stronger availability, identity and operational controls. 

This document is intended to support Phase 1 security analysis and Phase 2 implementation planning. It is not a formal test, compliance or complete production security assessment. Risks and controls should be reviewed again as the architecture and deployed environment mature.

### 2. System Context

Cobbled is designed as a modular, multi-tenant platform where independently deployable modules own their frontend components, APIs, data stores and release lifecycle. 

The proposed AWS design separates the platform across dedicated accounts for management, security, shared services, development staging and production. This separation reduces the impact of configuration errors or security incidents by preventing development andproduction workloads from sharing the same security boundary.

Only the public edge of the platform is intended to be directly accessible from the internet. Requests pass through the web firewall and load balancer before reaching application services running on ECS Fargate within private subnts. The database is also private and has no direct route to the internet. 

The production design also aims to use short-lived AWS credentials, single sign-on and MFA rather than standing passwords or access keys

### 3. Assets to Protect

The following assets have been identified as important to the confidentiality, integrity and availability of Cobbled:

| Asset | Importance |
|---|---|
| Tenant data | Information belonging to one client must remain protected from other tenants and unauthorised users. |
| User identities and permissions | Used to determine who can access the platform and what actions they are allowed to perform. |
| AWS accounts and privileged roles | Compromise could allow modification, deletion or exposure of platform resources. |
| Application APIs | Provide access to backend functions and may expose tenant data if improperly secured. |
| Database | Stores application and tenant information and must remain private and protected. |
| Secrets and credentials | Includes application secrets, database credentials and authentication information. |
| Terraform configuration and state | Controls the AWS environment and can create, modify or destroy infrastructure. |
| Source code and deployment pipeline | Changes may be promoted into AWS and therefore require controlled review and deployment. |
| Logs and security records | Required for monitoring, troubleshooting and investigation of security events. |
| Backups | Required to recover from accidental deletion, corruption or service failure. |

### 4. Risk Assessment

Risks are assessed using a likelihood and impact rating from 1 to 5.

#### Likelihood

| Score | Rating | Description |
|---:|---|---|
| 1 | Rare | Unlikely to occur. |
| 2 | Unlikely | Could occur, but is not expected regularly. |
| 3 | Possible | A realistic scenario that may occur. |
| 4 | Likely | Expected to occur unless controls are effective. |
| 5 | Almost Certain | Expected to occur frequently or repeatedly. |

#### Impact

| Score | Rating | Description |
|---:|---|---|
| 1 | Insignificant | Minimal operational or security impact. |
| 2 | Minor | Limited impact with straightforward recovery. |
| 3 | Moderate | Noticeable impact requiring intervention. |
| 4 | Major | Significant service disruption or security impact. |
| 5 | Severe | Major data exposure, infrastructure compromise or prolonged outage. |

Risk score is calculated as:

`Likelihood × Impact`

| Score | Risk Rating |
|---:|---|
| 1-4 | Low |
| 5-9 | Medium |
| 10-16 | High |
| 17-25 | Critical |

The initial risk represents the level of exposure before controls are considered. Residual risk represents the expected risk remaining after the proposed controls are implemented.

### 5. Threat and Risk Assessment

| ID | Threat | Likelihood | Impact | Initial Risk | Key Mitigations | Residual Risk |
|---|---|---:|---:|---|---|---|
| T01 | Cross-tenant data access | 3 | 5 | High (15) | Tenant validation, application access controls and database isolation | Low |
| T02 | Compromise of privileged AWS access | 3 | 5 | High (15) | SSO, MFA, short-lived roles, least privilege and audit logging | Medium |
| T03 | Unauthorised or malicious API access | 3 | 5 | High (15) | Web firewall, authentication, authorisation, request validation and rate limiting | Medium |
| T04 | Exposure of credentials or secrets | 3 | 5 | High (15) | Secrets management, short-lived credentials and no secrets stored in source control | Low |
| T05 | Database exposure | 2 | 5 | High (10) | Private database, restricted network access and encryption | Low |
| T06 | Service outage or failed deployment | 3 | 4 | High (12) | Health checks, monitoring, rollback procedures and environment separation | Medium |
| T07 | Terraform or AWS misconfiguration | 3 | 4 | High (12) | Pull requests, Terraform plan review, automated validation and account guardrails | Medium |
| T08 | Loss of logs or security evidence | 3 | 4 | High (12) | Central security account, CloudTrail, monitoring and protected logging services | Medium |
| T09 | Backup failure or unrecoverable data loss | 3 | 5 | High (15) | Automated backup, restore testing and future off-account backup copies | Medium |
| T10 | Compromise of the deployment pipeline | 2 | 5 | High (10) | GitHub short-lived roles, branch review and restricted deployment permissions | Medium 

### 6. Key Threat Areas

#### 6.1 Multi-Tenacy

Multi-tenancy is a high-impact risk because Cobbled may host information belonging to multiple clients. A failure in tenant isolation could allow one client to access information belonging to another.

Controls should ensure that tenant identity is validated before data is accesssed and that application and database permissions prevent unauthorised cross-tenant access.

Key controls include:

- Validate tenant identity before processing requests.
- Prevent users from selecting or modifying another tenant's identity.
- Restrict access to tenant data at both the application and database layers.
- Test that incorrect tenant identifiers are rejected.
- Review tenant isolation as new modules are introduced.

#### 6.2 Privileged Access

 Privileged AWS access could allow an attacker or compromised account to modify security controls, retrieve data or destroy resources.

The target design reduces this risk by removing long-lived credentials and using single sign-on, MFA and temporary roles.

Key controls include:

- Require MFA for privileged access.
- Use IAM Identity Center for human access.
- Use short-lived AWS sessions rather than long-lived access keys.
- Apply least-privilege permissions.
- Separate platform administrator, developer and auditor access.
- Record privileged activity through CloudTrail.

#### 6.3 API Exposure

Application APIs are a major entry point into Cobbled and may be targeted through unauthorised requests, malformed input, excessive requests or attempts to bypass authentication.

The proposed architecture limits public exposure by allowing internet traffic to enter only through the public edge.

Key controls include:

- Authenticate and authorise API requests.
- Place application workloads inside private subnets.
- Use the web firewall to filter malicious traffic.
- Apply request validation and rate limiting.
- Prevent direct internet access to application containers and databases.

#### 6.4 Data Protection

Tenant and application data must remain protected both while stored and while being transmitted.

Secrets and credentials should not be stored directly in source code, Terraform files or application logs.

Key controls include:

- Encrypt sensitive data at rest and in transit.
- Store credentials and application secrets using an approved secrets-management service.
- Keep databases private.
- Restrict database access to approved application services.
- Avoid storing secrets or unnecessary sensitive information in logs.

#### 6.5 Service Availability

The platform must remain available when individual components fail or when deployments introduce errors.

Environment separation also reduces the risk that changes made during development affect production services.

Key controls include:

- Separate development, staging and production environments.
- Monitor application and infrastructure health.
- Use health checks and automated recovery where possible.
- Maintain rollback procedures for failed deployments.
- Maintain backups and regularly test recovery.

#### 6.6 Infrastructure and Configuration Risk

Terraform provides a repeatable method for managing AWS infrastructure, but an incorrect configuration could affect many resources at once.

Key controls include:

- Use feature branches and pull requests.
- Review Terraform plans before changes are applied.
- Restrict deployments to approved AWS accounts and regions.
- Use automated Terraform validation and security scanning.
- Test infrastructure changes before production deployment.
- Prevent routine manual changes that bypass Infrastructure-as-Code.

### 7. Current PoC Limitations and Residual Risk

The current Proof of Concept is intentionally designed to remain lightweight and cost-conscious. As a result, not every production security control is implemented at its final level.

Current limitations include:

- Some production controls are designed but not yet fully implemented or tested.
- The production multi-account structure is more complex than the current PoC environment.
- Tenant-isolation controls cannot be completely validated until representative Cobbled application workloads are deployed.
- Backup resilience remains an identified gap because backups currently do not have a protected copy outside the account they are intended to protect.
- Availability and recovery controls require further testing during Phase 2.

These limitations do not prevent the PoC from demonstrating the proposed architecture, but they must be considered before Cobbled is used as a production platform.

### 8. Phase 2 Security Actions

The following security activities should be prioritised during Phase 2:

1. Validate tenant isolation using representative Cobbled application workloads.
2. Confirm IAM Identity Center, MFA and role-based access are operating as designed.
3. Test API authentication, authorisation and public-edge controls.
4. Verify that application services and databases are not publicly reachable.
5. Test logging and monitoring across the platform.
6. Implement and test backup and restore procedures, including off-account backup protection.
7. Review Terraform plans and security scan results before infrastructure changes are deployed.
8. Reassess the threat model after the Phase 2 environment is operational.

> [!NOTE]
> How the [Phase 2 plan](../project/phase-2-plan.md) covers these: 2 is M1; 1 and 4 are M2,
> with a stand-in module, so tenant isolation inside Cobble's own code (T1)
> stays open until it can be tested with the Centre's developers; 5 is M3;
> 6 is M4; 7 runs on every change. API and public-edge tests (3) aren't in
> Phase 2, because there's no domain or API Gateway yet.

### 9. Conclusion

The threat model identifies multi-tenancy, privileged access, API exposure, data protection, service availability and infrastructure configuration as the most significant security concerns for the proposed Cobbled AWS environment.

The proposed architecture reduces these risks through account separation, private networking, central security controls, short-lived access, Infrastructure-as-Code and logging and monitoring. However, several controls remain to be implemented or validated as the project progresses into Phase 2.

This assessment should therefore be treated as a living document and reviewed as the Cobbled architecture, workloads and production requirements continue to develop.

---

## Risk management plan

- **Status:** Final
- **Date:** 2026-10-19
- **Author:** Timothy Hartmann
- **Reviewed by:** T235

### 1. Purpose

This document defines how risks identified throughout the Cobbled AWS project will be recorded, assessed, treated and reviewed. It builds on the Threat Model and Risk Assessment by assigning ownership, mitigation actions and contingency responses to significant technical, security and project risks.

### 2. Risk Management Approach

Risks are identified through architecture reviews, threat modelling, prototype testing, project planning and discussions with the Industry Partner.

Each risk is recorded with:

- Likelihood
- Impact
- Overall risk rating
- Risk owner
- Mitigation actions
- Contingency actions
- Current status

Risks should be reviewed when the architecture changes, new AWS services are introduced, significant prototype issues are discovered, or before major Phase 2 deployment milestones.

### 3. Risk scoring

Likelihood and impact use the same 1–5 scoring model defined in the [detailed risk assessment](#4-risk-assessment) above.

Risk score:

`Likelihood × Impact`

| Score | Rating |
|---:|---|
| 1–4 | Low |
| 5–9 | Medium |
| 10–16 | High |
| 17–25 | Critical |

### 4. Risk Register

> [!NOTE]
> This is the register as written on 19 October 2026. The live register,
> with later status updates and the delivery risks R10 to R17, is in
> [governance, risks and ethics](../project/governance-risks-ethics.md#risk-register).

| ID | Risk | Likelihood | Impact | Rating | Owner | Mitigation | Contingency | Status |
|---|---|---:|---:|---|---|---|---|---|
| R01 | Cross-tenant data exposure | 3 | 5 | High | Application / Security | Tenant validation, isolation controls, testing | Disable affected service and investigate access paths | Open |
| R02 | Privileged AWS account compromise | 3 | 5 | High | Platform Team | MFA, SSO, least privilege, short-lived roles | Revoke access, rotate credentials, review CloudTrail | Open |
| R03 | Unauthorised API access | 3 | 5 | High | Application / Platform | Authentication, WAF, request validation, rate limiting | Restrict endpoint, investigate logs and redeploy controls | Open |
| R04 | Terraform configuration causes incorrect infrastructure change | 3 | 4 | High | Platform Team | PR review, Terraform plan review, CI validation | Roll back configuration and redeploy last known-good state | Open |
| R05 | AWS costs exceed estimates | 3 | 3 | Medium | Project Team | Budgets, alerts, low-cost PoC design | Tear down non-essential resources and review sizing | Open |
| R06 | Prototype cannot be completed within Phase 1 | 3 | 4 | High | Project Team | Prioritise core functionality and track GitHub tasks | Reduce prototype scope and document deferred work for Phase 2 | Open |
| R07 | Loss of service or failed deployment | 3 | 4 | High | Platform Team | Environment separation, health checks, testing | Roll back to previous working deployment | Open |
| R08 | Backup or restore failure | 3 | 5 | High | Platform Team | Automated backups and restore testing | Rebuild from available state/data and escalate recovery gap | Open |
| R09 | Delayed access, credentials or Industry Partner input | 3 | 3 | Medium | Project Team | Raise dependencies early and use Discord/meetings | Re-sequence independent project work | Open |

### 5. Risk Ownership and Treatment

High and critical risks should have an identified owner and mitigation action before the affected component is considered production-ready.

Risk treatment may include:

- **Avoid** – change the design to remove the risk
- **Reduce** – implement controls that lower likelihood or impact
- **Transfer** – rely on an external service or responsible party where appropriate
- **Accept** – document and consciously accept residual risk where further treatment is not practical

Accepted risks should include a reason and, where appropriate, a trigger for future review.

### 6. Risk Review Process

The risk register should be reviewed:

- During major architecture changes
- Following prototype testing
- Before production deployment
- When new security issues are identified
- Following significant incidents or failed deployments
- At major Phase 2 milestones

Changes to high or critical risks should be documented in the repository.

### 7. Phase 2 Priorities

During Phase 2, the team should prioritise:

1. Validation of tenant isolation
2. Finalisation of privileged access controls
3. Testing of API protection
4. Backup and restore validation
5. Review of Terraform deployment controls
6. Validation of monitoring and incident-response capability

> [!NOTE]
> In the [Phase 2 plan](../project/phase-2-plan.md): privileged access is M1, tenant
> isolation (platform side, with a stand-in module) is M2, monitoring is M3,
> and backup and restore is M4. API protection isn't in Phase 2.
7. Reassessment of risks after the application is deployed

### 8. Relationship to Threat Model and Risk Assessment

The Threat Model and Risk Assessment identifies cloud security threats and evaluates their initial and residual risk.

This Risk Management Plan defines how those risks, together with broader technical and project risks, are owned, treated, monitored and reviewed throughout the project lifecycle.

The two documents should therefore be maintained together: the Threat Model provides the detailed security analysis, while this plan provides the ongoing process for managing the resulting risks.

### 9. Risk Escalation

Critical risks, or high risks that cannot be adequately mitigated by the project team, should be raised with the industry Partner and relevant project stakeholers.

Risks that meterially affect project scope, cost, security or delivery timeframes should be reviewed before the affected work continues. 
