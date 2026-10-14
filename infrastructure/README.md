# Infrastructure

The Terraform code for the Cobble AWS platform (capstone deliverable 4).
Terraform reads these files and builds the matching resources in AWS. Run it
again and you get exactly the same result.

**In short:** there are two solutions, built from one shared set of
building blocks (modules).

- **Solution B** builds a secure single-account platform: 48 resources in about 5 minutes, for about A$0.
- **Solution A** builds the full design. Its workload (web servers, database, network) can be deployed into one account for a demo: 66 resources, about A$0.22 an hour. Its landing zone sets up the six-account organisation around it.

To deploy anything, start with [runbooks/README.md](../runbooks/README.md).

## What's in here

```
infrastructure/
├── bootstrap/          The S3 bucket Terraform keeps its records (state) in. Set up once.
├── solution-b/         Solution B. Run Terraform here.
├── solution-a/
│   ├── workload/       One Solution A environment. Run Terraform here with demo/dev/staging/prod.tfvars
│   └── landing-zone/   The organisation around the environments, in numbered steps:
│       ├── identity/           people and groups
│       ├── 1-organization/     accounts, guardrails, single sign-on
│       ├── 2-security/         locked audit logs, threat detection, alerts
│       └── 3-shared-services/  container image registry
└── modules/            Building blocks used by both solutions. Never run directly
```

There are seven folders you run Terraform in (**root configs**). Everything
else is a **module**, a building block those folders use. Every folder has a
README saying what it builds and how to run it.

| Folder | Solution | Runs in | Runbook |
|---|---|---|---|
| [`bootstrap`](bootstrap/) | Both | The team's account | [bootstrap.md](../runbooks/bootstrap.md) |
| [`solution-b`](solution-b/) | B | The team's account | [deploy.md](../runbooks/deploy.md), [teardown.md](../runbooks/teardown.md) |
| [`solution-a/workload`](solution-a/workload/) + `demo.tfvars` | A (demo) | The team's account | [demo-solution-a.md](../runbooks/demo-solution-a.md) |
| [`solution-a/workload`](solution-a/workload/) + `dev`, `staging`, `prod.tfvars` | A | Each environment's own account | [deploy-solution-a.md, step 4](../runbooks/deploy-solution-a.md#step-4-dev-then-staging-then-prod) |
| [`solution-a/landing-zone/*`](solution-a/landing-zone/) (4 folders) | A | Management, Security and Shared Services accounts | [deploy-solution-a.md](../runbooks/deploy-solution-a.md) |

Every change to any of them is formatted, validated, tested and
security-scanned automatically ([`ci.yml`](../.github/workflows/ci.yml)).
dev, staging and prod also get a nightly check that nothing has been changed
by hand ([`drift.yml`](../.github/workflows/drift.yml)).

## Where to find things

| I'm looking for... | Solution B | Solution A |
|---|---|---|
| Everything that gets built | [`solution-b/main.tf`](solution-b/main.tf) | [`solution-a/workload/main.tf`](solution-a/workload/main.tf), then each landing-zone step |
| The settings to change | [`solution-b/poc.auto.tfvars`](solution-b/poc.auto.tfvars) | One file per environment: [`demo`](solution-a/workload/demo.tfvars), [`dev`](solution-a/workload/dev.tfvars), [`staging`](solution-a/workload/staging.tfvars), [`prod`](solution-a/workload/prod.tfvars); each landing-zone step's `settings.auto.tfvars` |
| Accounts and guardrails | (one account) | [`1-organization/`](solution-a/landing-zone/1-organization/), [`policies/`](solution-a/landing-zone/1-organization/policies/) |
| Who can sign in, and what they can do | IAM users (being replaced) | [`identity/`](solution-a/landing-zone/identity/), [`identity-center.tf`](solution-a/landing-zone/1-organization/identity-center.tf) |
| Encryption keys | [`security-baseline/kms.tf`](modules/security-baseline/kms.tf) | [`workload/kms.tf`](solution-a/workload/kms.tf), [`2-security/kms.tf`](solution-a/landing-zone/2-security/kms.tf) |
| Audit logging | [`security-baseline/cloudtrail.tf`](modules/security-baseline/cloudtrail.tf) | [`2-security/cloudtrail.tf`](solution-a/landing-zone/2-security/cloudtrail.tf), [`log-archive.tf`](solution-a/landing-zone/2-security/log-archive.tf) |
| Threat detection and security checks | [`security-baseline/guardduty.tf`](modules/security-baseline/guardduty.tf) | [`2-security/detection.tf`](solution-a/landing-zone/2-security/detection.tf), [`alerts.tf`](solution-a/landing-zone/2-security/alerts.tf) |
| The network | [`modules/network/`](modules/network/) | Same module, with NAT gateways and database subnets switched on |
| Web servers and load balancer | [`modules/container-service/`](modules/container-service/) (optional demo) | Same module |
| Database | (none) | [`modules/postgres-database/`](modules/postgres-database/) |
| GitHub's access to AWS | [`modules/github-oidc/`](modules/github-oidc/) | Same module |
| Cost alerts | `aws_budgets_budget` in [`solution-b/main.tf`](solution-b/main.tf) | The same, in [`workload/main.tf`](solution-a/workload/main.tf) |
| Where Terraform's records are kept | [`solution-b/backend.tf`](solution-b/backend.tf) | Each folder's `backend.tf`, all in the same bucket |

## Control map

How finished each security control is, in each solution:

- **Designed:** written down only.
- **Configured:** built by the code, so it's there whenever the platform is deployed. An administrator could still change it.
- **Enforced:** built, and no one in the account can turn it off (a guardrail stops them).
- **Not covered:** not part of that solution.

The Solution A column shows the status each control reaches once the whole
landing zone is deployed. Nothing in Solution B is enforced, because
enforcing needs guardrails, which need the multi-account organisation.

| Control | Solution B | Solution A | Built in |
|---|---|---|---|
| Separate account per environment | Designed | Configured | `landing-zone/1-organization/accounts.tf` |
| Only Sydney (and `us-east-1`) can be used | Not covered | Enforced | `1-organization/policies/restrict-regions.json.tftpl` |
| Root user blocked in member accounts | Not covered | Enforced | `1-organization/policies/deny-root-user.json` |
| Single sign-on with separate admin, developer and read-only roles | Designed (IAM users with MFA for now) | Configured | `1-organization/identity-center.tf` |
| MFA for everyone | Designed (set on each IAM user) | Configured (an Identity Center console setting) | Runbooks |
| Data encrypted with our own key, rotated automatically | Configured (one shared key) | Configured (a key per account) | `security-baseline/kms.tf`, `workload/kms.tf`, `2-security/kms.tf` |
| Every bucket versioned, never public, access-logged | Configured | Configured, plus an account-wide block on public buckets | `s3-bucket/main.tf`, `account-baseline/main.tf` |
| Audit trail of every action, all regions, tamper-evident | Configured (deleted on teardown) | Enforced | `security-baseline/cloudtrail.tf`, `2-security/cloudtrail.tf` |
| Audit logs can't be changed or deleted | Not covered | Configured (Object Lock) | `2-security/log-archive.tf` |
| Audit trail searchable in CloudWatch | Configured (90 days) | Designed (Phase 2) | `security-baseline/cloudtrail.tf` |
| Threat detection (GuardDuty) | Configured | Enforced | `security-baseline/guardduty.tf`, `2-security/detection.tf` |
| Best-practice checks (Security Hub: CIS and AWS standards) | Designed | Enforced | `2-security/detection.tf` |
| Configuration history (AWS Config) | Designed | Enforced | `account-baseline/config.tf` |
| Anything shared outside the organisation flagged (Access Analyzer) | Not covered | Enforced | `2-security/detection.tf` |
| Email alert on high and critical findings | Not covered | Configured | `2-security/alerts.tf` |
| Container images scanned when pushed | Not covered | Configured | `3-shared-services/main.tf` |
| Running servers scanned for vulnerabilities (Inspector) | Designed | Designed (Phase 2) | |
| Network traffic logged (VPC Flow Logs) | Configured (30 days) | Configured (30 or 90 days) | `network/flow-logs.tf` |
| Web servers in private subnets; database with no route to the internet | Configured (no web servers unless the demo is on) | Configured | `network/` |
| Network's default firewall rule locked down | Not covered | Configured | `network/default-security-group.tf` |
| Only the load balancer reaches the web servers; only they reach the database | Configured (demo only) | Configured | `container-service/security-groups.tf`, `postgres-database/main.tf` |
| Web firewall (AWS managed rules, rate limit) | Not covered | Configured (staging, prod) | `container-service/waf.tf` |
| HTTPS with TLS 1.2 or later | Not covered (demo is HTTP) | Configured (once there's a certificate) | `container-service/load-balancer.tf` |
| Database password never in code | Not covered (no database) | Configured | `postgres-database/main.tf` |
| Backups | Configured (file versioning) | Configured (plus database backups, 35 days in prod) | `s3-bucket/`, `postgres-database/` |
| GitHub deploys without stored keys: read-only role for checks, approval needed to deploy | Configured | Configured | `github-oidc/main.tf` |
| Terraform refuses to run against the wrong account | Configured | Configured | Each `providers.tf` |
| Monthly cost alert | Configured (US$1, about A$1.45) | Configured (per account) | `solution-b/main.tf`, `workload/main.tf` |
| The Guide's required tags on every resource | Configured | Configured | Each `providers.tf` |
| Every change formatted, validated, tested and scanned | Configured (GitHub Free can't make it mandatory) | Configured (same) | `.github/workflows/ci.yml` |

Every security scanner finding, and what we decided about it, is in the
[scan findings register](../docs/03-security-controls/scan-findings.md).

Known gaps in Solution A:

- The audit trail isn't streamed to CloudWatch, so the CIS alarms on it aren't set up. Phase 2.
- The application signs in to the database as the main (admin) user. A user with fewer rights is Phase 2.
- GitHub's deploy role is an administrator of its own account, guarded by approval and the guardrails. Narrowing it is Phase 2.
- One Security account does the job of AWS's separate Log Archive and Security Tooling accounts, to save cost.

## What it costs

Rough estimates in **Australian dollars** for Sydney, with low traffic and
everything left running all month. AWS publishes its prices in US dollars,
so they're converted at **A$1.44 per US$1** (the rate in late July 2026).
They're for comparing options, not quotes: check the
[AWS Pricing Calculator](https://calculator.aws/) and today's exchange rate
before committing.

AWS budgets only work in US dollars, so the budget limits in the code are
in USD (Solution B's US$1 alert is about A$1.45). By default AWS also bills
in US dollars; the payment currency can be changed to AUD in the Billing
console.

| | Cost |
|---|---|
| Solution B | Under A$7 a month; about A$0 when torn down between demos |
| Solution B with the demo web page on | About A$1.90 a day |
| Solution A demo (the workload in one account) | About A$0.22 an hour, A$5 a day |
| Solution A, everything running | About A$790 a month |

Solution A by account:

| Account | Main costs | Per month |
|---|---|---|
| Management, Security, Shared Services | Threat detection, security checks, configuration history, keys, log storage, image registry | A$70 to A$145 |
| dev | NAT gateway A$62, load balancer ~A$29, web server ~A$16, database A$26, public IPs ~A$16, logs and keys | About A$160 |
| staging | As dev, plus the web firewall ~A$14 | About A$175 |
| prod | 2 NAT gateways A$124, load balancer ~A$29, 2 larger web servers ~A$62, database with standby copy ~A$115, web firewall ~A$14, public IPs ~A$22 | About A$375 |

The biggest saving is turning dev and staging off when nobody is using them.
They're built to tear down and rebuild cleanly, and doing so brings Solution
A to about A$475 a month.

Unit prices used (AWS's US-dollar price, converted):

| Item | Price | Source |
|---|---|---|
| NAT gateway (Sydney) | A$0.085 per hour (~A$62/month) | [cloudburn.io regional table](https://cloudburn.io/blog/aws-nat-gateway-pricing) |
| RDS PostgreSQL db.t4g.micro / db.t4g.small (Sydney, single zone) | ~A$26 / ~A$53 per month; a standby copy doubles it | [Bytebase RDS price data](https://www.bytebase.com/dbcost/rds/instance/db.t4g.small/) |
| Public IPv4 address | A$0.0072 per hour (~A$5.25/month) | [Amazon VPC pricing](https://aws.amazon.com/vpc/pricing/) |
| Application Load Balancer | ~A$0.036 per hour plus usage | [Elastic Load Balancing pricing](https://aws.amazon.com/elasticloadbalancing/pricing/) |
| Fargate | ~A$0.072 per vCPU-hour, ~A$0.0072 per GB-hour | [AWS Fargate pricing](https://aws.amazon.com/fargate/pricing/) |
| AWS WAF | A$7.20 per web ACL + A$1.44 per rule per month + A$0.86 per million requests | [AWS WAF pricing](https://aws.amazon.com/waf/pricing/) |
| KMS key | A$1.44 per key per month | [AWS KMS pricing](https://aws.amazon.com/kms/pricing/) |
| AWS Config | A$0.0043 per configuration item recorded | [AWS Config pricing](https://aws.amazon.com/config/pricing/) |
| Security Hub | A$0.0014 per check (first 100,000); 30-day free trial | [Security Hub pricing](https://aws.amazon.com/security-hub/cspm/pricing) |

## Handy commands

| Task | Where | Command |
|---|---|---|
| Deploy, demo or tear down | | See [runbooks/README.md](../runbooks/README.md) |
| Tidy the formatting of every file | `infrastructure/` | `terraform fmt -recursive` |
| Check a folder's code without touching AWS | That folder | `terraform init -backend=false`, then `terraform validate` |
| Run the automated tests | `modules/<name>/` or `solution-a/workload/` | `terraform init -backend=false`, then `terraform test` |

The tests use a pretend (mocked) AWS, so they need no AWS sign-in and cost
nothing.

## Why it's built this way

| Practice | Source |
|---|---|
| One account per environment, grouped into Security, Infrastructure and Workloads | [AWS Security Reference Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/welcome.html), [Organizing your AWS environment](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/organizing-your-aws-environment.html) |
| Security services run from a dedicated Security account, not the management account | AWS Security Reference Architecture |
| Guardrails that deny specific actions | [AWS Organizations SCP examples](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples.html) |
| Only temporary credentials: single sign-on for people, OIDC for GitHub | [IAM security best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html) |
| Small modules, each with a README; standard file names; consistent formatting | [Terraform style guide](https://developer.hashicorp.com/terraform/language/style), [Standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure) |

The design decisions themselves, with their reasons, are in
[deliverable 2](../docs/02-landing-zone-design/README.md#key-decisions).
Every framework the design follows is in
[frameworks and standards](../docs/frameworks-and-standards.md).
