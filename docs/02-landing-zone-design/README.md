# Deliverable 2: Secure landing zone design

The AWS accounts Cobble uses, who can do what in each one, and the
guardrails that hold no matter who signs in. It ends with the key design
decisions and the gaps that remain.

**In short:** six accounts, grouped by purpose. Staff sign in once through
single sign-on and get only the access their role needs. Four guardrails
apply to every account, even to administrators: stay in Australian regions,
never use the root user, never switch off security monitoring, and never
leave the organisation.

The code is Solution A's landing zone
([`infrastructure/solution-a/landing-zone/`](../../infrastructure/solution-a/landing-zone/)).

## Accounts

The layout follows the AWS Security Reference Architecture, with one
simplification: a single Security account does the job of AWS's separate
"Log Archive" and "Security Tooling" accounts, which halves the fixed cost.

| Group (OU) | Account | Purpose | Built by |
|---|---|---|---|
| (top level) | Management | Runs the organisation, billing and single sign-on. Runs no applications | `1-organization` |
| Security | `cobble-security` | Holds the locked audit logs and runs threat detection and security checks for every account | `2-security` |
| Infrastructure | `cobble-shared-services` | The container image registry every environment pulls from | `3-shared-services` |
| Workloads > NonProduction | `cobble-dev` | Where developers try changes | `workload/dev.tfvars` |
| Workloads > NonProduction | `cobble-staging` | A dress rehearsal for prod, with synthetic data. Also the Guide's "test" environment | `workload/staging.tfvars` |
| Workloads > Production | `cobble-prod` | What tenants use | `workload/prod.tfvars` |

Each environment has its own account, network range and encryption key, so
nothing in one environment can reach another by accident.

**Not built yet:** the Guide's disaster recovery and backup accounts (see
[gaps](#gaps)).

## Who can do what

People sign in through IAM Identity Center (single sign-on). Solution A has
no IAM users and no long-lived passwords or keys
([`identity-center.tf`](../../infrastructure/solution-a/landing-zone/1-organization/identity-center.tf)).
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
tenant data. The **apply** role can make changes, but only after a team
member approves the deployment in GitHub
([`modules/github-oidc`](../../infrastructure/modules/github-oidc/)).

**MFA** is required at every sign-in. It's an Identity Center setting with
no AWS API, so it's a console step in the
[runbook](../../runbooks/deploy-solution-a.md#people-and-groups) rather than code.

## Guardrails

Guardrails (service control policies) apply to every member account,
administrators included. They don't apply to the management account, which
is why nothing else runs there.

| Guardrail | Stops anyone... | File |
|---|---|---|
| Restrict regions | creating anything outside Sydney (and `us-east-1`, which some global AWS services need) | [`restrict-regions.json.tftpl`](../../infrastructure/solution-a/landing-zone/1-organization/policies/restrict-regions.json.tftpl) |
| Deny root user | using an account's root user | [`deny-root-user.json`](../../infrastructure/solution-a/landing-zone/1-organization/policies/deny-root-user.json) |
| Protect security services | switching off, or quietly muting, the audit trail, threat detection, security checks, configuration history or network logs | [`protect-security-services.json.tftpl`](../../infrastructure/solution-a/landing-zone/1-organization/policies/protect-security-services.json.tftpl) |
| Deny leaving the organisation | taking an account out of the organisation | [`deny-leave-organization.json`](../../infrastructure/solution-a/landing-zone/1-organization/policies/deny-leave-organization.json) |

## How Solution B relates

Solution B is the same design in one account: one network, one encryption
key, the audit trail and threat detection in the same account, and IAM users
with MFA instead of single sign-on. The
[root README](../../README.md#what-solution-b-leaves-out-and-how-solution-a-fills-the-gap)
lists each simplification and how Solution A handles it.

## Key decisions

The decisions that shaped the design, why we made them, and what would make
us change them.

**1. Two solutions from one set of building blocks.** Solution B, the
minimum viable product, can be shown working today for almost nothing.
Solution A is the full design the Cyber Security Centre would run. Both use
the same modules, so B is a working slice of A rather than a throwaway
prototype. *We rejected* writing two separate codebases, because the copies
would drift apart.

**2. Both solutions can be deployed and torn down.** Solution A's workload
is one folder whose settings come from one file per environment
(`demo.tfvars`, `dev.tfvars`, `staging.tfvars`, `prod.tfvars`). The demo
file deploys it into Solution B's account for a few hours, so both solutions
can be shown in the console. *Revisit if* environments start to differ in
structure, not just size.

**3. Containers on ECS Fargate, not Kubernetes (EKS).** The Guide (§7)
recommends EKS only when the team can run Kubernetes day to day. Fargate
needs no servers or cluster upgrades, so a small team can operate it. *Revisit
if* Cobble needs something only Kubernetes offers.

**4. One Security account, not two.** AWS's reference design splits logs
and security tools into two accounts. One account halves the fixed cost and
keeps the same separation from the workloads. *Revisit* at production scale,
or if an auditor asks for the split.

**5. PostgreSQL for now, not SQL Server.** The Guide's database is RDS for
SQL Server. Licensed SQL Server costs far more per hour on the small sizes
we use, and no Cobble database exists yet to tie us to it. All the security
controls (private network, encryption, enforced encrypted connections,
managed password, backups, standby copy) are built the same way, so moving
to SQL Server is a swap of one building block. *Revisit when* the client
confirms the SQL Server edition.

**6. A load balancer with a web firewall, not CloudFront and API Gateway.**
The Guide puts CloudFront and API Gateway in front of a private load
balancer. Until Cobble has a domain name and defined API routes, a public
load balancer with a web firewall and HTTPS gives the protection we need for
less cost and complexity. *Revisit when* the domain and the application's
API routes exist.

**7. Solution B accepts some shortcuts to stay near A$0.** One account; no
NAT gateway (it costs about A$62 a month), so the private network has no
outbound internet; and the audit trail is deleted on teardown. Solution A
shows the full answer to each one. *Revisit* if Solution B is ever left
running long-term.

## Gaps

Measured against the Implementation Guide §3 (pp.8–9).

| Gap | Risk | Next step |
|---|---|---|
| The admin role has full access in every account, including management, where guardrails don't apply | One stolen admin session could change anything | Add the Guide's separate database-admin, deployment and security-auditor roles; narrow the admin role outside management |
| No break-glass role or procedure | No safe way in if single sign-on fails, and no alert when emergency access is used | A break-glass role in management, an alarm when it's used, and a tested procedure |
| No guardrails against public databases or unencrypted storage | A misconfigured resource could be public or unencrypted | Add two more guardrails |
| No disaster recovery or backup account, and the region guardrail blocks the Guide's recovery region (Melbourne) | Losing prod's account or region loses data | Add the accounts and allow Melbourne once disaster recovery is designed ([operations model](../05-deployment-operations/README.md#4-backup-and-recovery)) |
| MFA is a console setting, not code | It could be switched off without a code review | Keep a screenshot as evidence; check it in every access review |

## Open decisions

From the Implementation Guide, Appendix C (p.34). Each needs an owner and a
decision before Phase 2.

| Decision | Where we are now |
|---|---|
| Primary and recovery regions | Sydney is primary. No recovery region yet; the guardrail allows only Sydney and `us-east-1` |
| SQL Server edition | PostgreSQL for Phase 1 (decision 5) |
| ECS or EKS | ECS Fargate (decision 3) |
| API Gateway type | No API Gateway yet (decision 6) |
| Identity provider and tenant sign-in | Identity Center's own directory for staff; tenant sign-in belongs to the application |
| Recovery time and data-loss targets | Proposed in the [operations model](../05-deployment-operations/README.md#recovery-objectives); waiting on the business owner |
| How much to centralise | Logs and security tools are central; networking stays in each account |
