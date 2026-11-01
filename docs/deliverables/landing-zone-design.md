# Deliverable 2: Secure landing zone design

The AWS accounts Cobble uses, who can do what in each one, and the
guardrails that hold no matter who signs in. It ends with the key design
decisions and the gaps that remain.

**In short:** six accounts, grouped by purpose. Staff sign in once through
single sign-on and get only the access their role needs. Four guardrails
apply to every account, even to administrators: stay in Sydney (plus
`us-east-1` for AWS's global services), never use the root user, never
switch off security monitoring, and never leave the organisation.

The code is Solution A's landing zone
([`infrastructure/solution-a/landing-zone/`](../../infrastructure/solution-a/landing-zone/)).

## Accounts

The layout follows the AWS Security Reference Architecture, with one
simplification: a single Security account does the job of AWS's separate
"Log Archive" and "Security Tooling" accounts, which halves the fixed cost.

| Group (OU) | Account | Purpose | Built by |
|---|---|---|---|
| (top level) | Management | Runs the organisation, billing and single sign-on. Meant to run no applications; in the team's organisation it also hosts Solution B and the demo | `1-organization` |
| Security | `cobble-security` | Holds the locked audit logs and runs threat detection and security checks for every account | `2-security` |
| Infrastructure | `cobble-shared-services` | The container image registry every environment pulls from. **In the code, but the account isn't created yet:** the five accounts closed on 17 October count against the organisation's 10-account limit until about mid-January 2027 | `3-shared-services` |
| Workloads > NonProduction | `cobble-dev` | Where developers try changes | `workload/dev.tfvars` |
| Workloads > NonProduction | `cobble-staging` | A dress rehearsal for prod, with synthetic data. Also the Guide's "test" environment | `workload/staging.tfvars` |
| Workloads > Production | `cobble-prod` | What tenants use | `workload/prod.tfvars` |

Each environment has its own account, network range and encryption key, so
nothing in one environment can reach another by accident.

**Not built yet:** the Guide's disaster recovery and backup accounts (see
[gaps](#gaps)).

## Who can do what

People sign in through IAM Identity Center (single sign-on). Solution A's
code creates no IAM users and no long-lived passwords or keys
([`identity-center.tf`](../../infrastructure/solution-a/landing-zone/1-organization/identity-center.tf)).
The team's own account, which is also the management account, still has the
team's IAM users in a shared full-administrator group, with access keys.
Removing them is Phase 2 milestone M1
([ADR 0001](../decisions/0001-deferred-landing-zone-design.md) D10).
**Groups** say who people are. **Permission sets** say what they can do.
Who is in which group is kept in a simple list, `users.csv`
([`identity/`](../../infrastructure/solution-a/landing-zone/identity/)).

| Group | Management | Security | Shared Services | dev | staging | prod |
|---|---|---|---|---|---|---|
| `cobble-platform-admins` | Admin | Admin | Admin | Admin | Admin | Admin |
| `cobble-developers` | | | | Developer | Read-only | Read-only |
| `cobble-auditors` | Read-only | Read-only | Read-only | Read-only | Read-only | Read-only |

| Permission set | Can do | Sign-in lasts |
|---|---|---|
| Admin (`CobblePlatformAdmin`) | Anything | 4 hours |
| Developer (`CobbleDeveloper`) | Anything except managing users and permissions | 8 hours |
| Read-only (`CobbleReadOnly`) | Look, don't touch | 8 hours |

**Automation gets its own identities.** GitHub signs in without any stored
keys and gets one of two roles. The **plan** role can only look, and can't
read the contents of buckets or logs, so a pull request can never reach
tenant data. The **apply** role can make changes, but only from `main`
through a GitHub environment; staging and prod are meant to need a
reviewer's approval there
([`modules/github-oidc`](../../infrastructure/modules/github-oidc/)). No
GitHub environments or deploy workflow exist yet, so nothing uses the apply
role today, and CI doesn't sign in to AWS at all. Only the nightly drift
check would use the plan role.

**MFA** is required at every sign-in. It's an Identity Center setting with
no AWS API, so it's a console step in the
[runbook](../../runbooks/deploy-solution-a.md#people-and-groups) rather than code.

## Guardrails

Guardrails (service control policies) apply to every member account,
administrators included. They don't apply to the management account, which
is why the design keeps applications out of it.

One exception: the guardrail that protects the security services exempts
`OrganizationAccountAccessRole`, the role the management account uses to
administer member accounts. So an administrator of the management account
can still switch those services off, which `lz-dev.ps1 down` relies on.

| Guardrail | Stops anyone... | File |
|---|---|---|
| Restrict regions | creating anything outside Sydney (and `us-east-1`, which some global AWS services need) | [`restrict-regions.json.tftpl`](../../infrastructure/solution-a/landing-zone/1-organization/policies/restrict-regions.json.tftpl) |
| Deny root user | using an account's root user | [`deny-root-user.json`](../../infrastructure/solution-a/landing-zone/1-organization/policies/deny-root-user.json) |
| Protect security services | switching off, or quietly muting, the audit trail, threat detection, security checks, configuration history or network logs | [`protect-security-services.json.tftpl`](../../infrastructure/solution-a/landing-zone/1-organization/policies/protect-security-services.json.tftpl) |
| Deny leaving the organisation | taking an account out of the organisation | [`deny-leave-organization.json`](../../infrastructure/solution-a/landing-zone/1-organization/policies/deny-leave-organization.json) |

## How Solution B relates

Solution B is the same design in one account: one network, one encryption
key, and the audit trail and threat detection in the same account. The
team's IAM users (with MFA, but also access keys that MFA doesn't cover)
are still in that account until M1 removes them; single sign-on is the
supported way in.
[ADR 0009](../decisions/0009-solution-b-shortcuts.md)
lists each simplification and how Solution A handles it.

## Key decisions

The decisions that shaped the design. Each one has a full
[decision record](../decisions/README.md) with its context, the options
weighed, and what would make us change it.

| # | Decision | Rejected | Revisit if | Record |
|---|---|---|---|---|
| 1 | Two solutions from one set of building blocks, so B is a working slice of A | Two separate codebases, which would drift apart | The two solutions need different modules | [ADR 0003](../decisions/0003-two-solutions-mvp-and-full-landing-zone.md) |
| 2 | One workload folder, one settings file per environment (`demo`, `dev`, `staging`, `prod.tfvars`) | A folder per environment | Environments differ in structure, not just size | [ADR 0004](../decisions/0004-one-workload-per-environment.md) |
| 3 | Containers on ECS Fargate, not Kubernetes (Guide §7) | EKS: a cluster to run and upgrade | Cobble needs something only Kubernetes offers | [ADR 0005](../decisions/0005-ecs-fargate-not-eks.md) |
| 4 | One Security account, not two | Separate Log Archive and Security Tooling accounts | Production scale, or an auditor asks | [ADR 0006](../decisions/0006-one-security-account.md) |
| 5 | PostgreSQL in the prototype, SQL Server as the target | Licensed SQL Server for the demo | The Centre confirms the SQL Server edition | [ADR 0007](../decisions/0007-postgresql-now-sql-server-target.md) |
| 6 | A load balancer with a web firewall, not CloudFront and API Gateway | The Guide's full edge, before a domain exists | The domain and API routes exist | [ADR 0008](../decisions/0008-load-balancer-and-waf.md) |
| 7 | Solution B accepts shortcuts to stay near A$0 (one account, no NAT gateway, audit trail deleted on teardown) | The full controls in one account | Solution B is left running long-term | [ADR 0009](../decisions/0009-solution-b-shortcuts.md) |

## Gaps

Measured against the Implementation Guide §3 (pp.8–9).

| Gap | Risk | Next step |
|---|---|---|
| The admin role has full access in every account, including management, where guardrails don't apply | One stolen admin session could change anything | Add the Guide's separate database-admin, deployment and security-auditor roles; narrow the admin role outside management |
| No break-glass role or procedure | No safe way in if single sign-on fails, and no alert when emergency access is used | A break-glass role in management, an alarm when it's used, and a tested procedure |
| No guardrails against public databases or unencrypted storage | A misconfigured resource could be public or unencrypted | Add two more guardrails |
| No disaster recovery or backup account, and the region guardrail blocks the Guide's recovery region (Melbourne) | Losing prod's account or region loses data | Add the accounts and allow Melbourne once disaster recovery is designed ([operations model](deployment-operations.md#4-backup-and-recovery)) |
| MFA is a console setting, not code | It could be switched off without a code review | Keep a screenshot as evidence; check it in every access review |

## Open decisions

From the Implementation Guide, Appendix C (p.34). The Centre makes these at
the Phase 2 decision points: Solution A or B and the account at G0, and the
licence, recovery targets, backup location, domain and applicable laws at G1
([Phase 2 plan](../project/phase-2-plan.md#decision-points)).

| Decision | Where we are now |
|---|---|
| Primary and recovery regions | Sydney is primary. No recovery region yet; the guardrail allows only Sydney and `us-east-1` |
| SQL Server edition | PostgreSQL for Phase 1 (decision 5) |
| ECS or EKS | ECS Fargate (decision 3) |
| API Gateway type | No API Gateway yet (decision 6) |
| Identity provider and tenant sign-in | Identity Center's own directory for staff; tenant sign-in belongs to the application |
| Recovery time and data-loss targets | Proposed in the [operations model](deployment-operations.md#recovery-objectives); waiting on the business owner |
| How much to centralise | Logs and security tools are central; networking stays in each account |
