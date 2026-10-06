# Infrastructure

Terraform for the Cobble AWS platform (Capstone deliverable 4), in two
solutions built from one set of modules:

- **Solution B (MVP):** a secure landing zone in one AWS account, deployed
  with one `terraform apply` (43 resources) and removed with one
  `terraform destroy`. Deployed today.
- **Solution A (full):** the complete multi-account design, in numbered
  steps. Written, validated and tested; not yet deployed.

Why there are two: [ADR 0003](../docs/02-landing-zone-design/adr/0003-two-solutions-mvp-and-full-landing-zone.md).

## Start here

**Solution B**

1. **[`envs/poc/main.tf`](envs/poc/main.tf)** lists everything that gets
   deployed, top to bottom.
2. **[`envs/poc/poc.auto.tfvars`](envs/poc/poc.auto.tfvars)** holds every
   value (account, region, IP ranges, budget, tags, demo app switch). It's the
   only file to edit to change a value.

**Solution A**

1. **[`solution-a/README.md`](solution-a/README.md)** shows the accounts and
   the order the steps run in.
2. **[`solution-a/4-workloads/prod/main.tf`](solution-a/4-workloads/prod/main.tf)**
   shows one whole environment's settings on one page; compare it with
   [`dev`](solution-a/4-workloads/dev/main.tf).

Each module's README explains what it creates and why.

```
infrastructure/
├── bootstrap/              Root config. The state bucket. Applied once per account, local state.
├── envs/
│   └── poc/                SOLUTION B. Root config. Run init/plan/apply here.
├── solution-a/             SOLUTION A. One root config per step, run in order.
│   ├── 1-organization/         accounts, guardrail SCPs, single sign-on
│   ├── 2-security/             locked audit logs, threat detection, alerts
│   ├── 3-shared-services/      container image registry
│   └── 4-workloads/            dev/, staging/, prod/
└── modules/
    ├── security-baseline/   (B) KMS key, CloudTrail, GuardDuty, access-log bucket
    ├── oidc-deploy-role/    (B) Lets GitHub Actions deploy without stored keys
    ├── network/             (A, B) VPC, subnets, flow logs; optional NAT and database tier
    ├── s3-bucket/           (A, B) Building block: one hardened bucket
    ├── log-delivery/        (A, B) Building block: one encrypted log group + its writer role
    ├── container-service/   (A, B demo) Containers behind a load balancer, optional WAF
    ├── access-log-bucket/   (A) Collects S3 and load balancer access logs
    ├── account-baseline/    (A) Account-wide safety settings and AWS Config
    ├── postgres-database/   (A) Private, encrypted PostgreSQL
    ├── github-oidc/         (A) Separate plan and apply roles for GitHub Actions
    └── cobble-environment/  (A) One whole environment, built from the modules above
```

**Root configs** are where you run Terraform. **Modules** are never applied
directly. Some modules deliver a capability (`security-baseline`, `network`,
`container-service`); `s3-bucket` and `log-delivery` are building blocks the
others reuse, so each recipe is written once. Every module's optional
features default to off, so adding something for Solution A never changes
what Solution B deploys.

## Where to find each concept

| Concept | Solution B | Solution A |
|---|---|---|
| What gets deployed | [`envs/poc/main.tf`](envs/poc/main.tf) | Each step's `main.tf`; one environment in [`modules/cobble-environment/main.tf`](modules/cobble-environment/main.tf) |
| Every configurable value | [`envs/poc/poc.auto.tfvars`](envs/poc/poc.auto.tfvars) | Each step's `settings.auto.tfvars`; sizes in `4-workloads/<env>/main.tf` |
| Accounts and organisation | (one account) | [`solution-a/1-organization/`](solution-a/1-organization/) |
| Guardrails (SCPs) | (none) | [`solution-a/1-organization/policies/`](solution-a/1-organization/policies/) |
| Who can sign in, with what rights | IAM users (interim) | [`solution-a/1-organization/identity-center.tf`](solution-a/1-organization/identity-center.tf) |
| Encryption keys and who may use them | [`modules/security-baseline/kms.tf`](modules/security-baseline/kms.tf) | [`modules/cobble-environment/kms.tf`](modules/cobble-environment/kms.tf), [`solution-a/2-security/kms.tf`](solution-a/2-security/kms.tf) |
| How buckets are protected | [`modules/s3-bucket/`](modules/s3-bucket/) | same, plus [`modules/account-baseline/main.tf`](modules/account-baseline/main.tf) |
| Audit logging (CloudTrail) | [`modules/security-baseline/cloudtrail.tf`](modules/security-baseline/cloudtrail.tf) | [`solution-a/2-security/cloudtrail.tf`](solution-a/2-security/cloudtrail.tf), [`log-archive.tf`](solution-a/2-security/log-archive.tf) |
| How services write logs | [`modules/log-delivery/`](modules/log-delivery/) | same |
| Threat detection and posture checks | [`modules/security-baseline/guardduty.tf`](modules/security-baseline/guardduty.tf) | [`solution-a/2-security/detection.tf`](solution-a/2-security/detection.tf) |
| Security alerts | (none) | [`solution-a/2-security/alerts.tf`](solution-a/2-security/alerts.tf) |
| Network layout | [`modules/network/main.tf`](modules/network/main.tf) | same, plus [`nat.tf`](modules/network/nat.tf), [`database-subnets.tf`](modules/network/database-subnets.tf) |
| Application hosting | [`modules/container-service/`](modules/container-service/) (demo, off by default) | same |
| Database | (none) | [`modules/postgres-database/`](modules/postgres-database/) |
| CI deploy identity | [`modules/oidc-deploy-role/main.tf`](modules/oidc-deploy-role/main.tf) | [`modules/github-oidc/main.tf`](modules/github-oidc/main.tf) |
| Cost alerts | `aws_budgets_budget` in [`envs/poc/main.tf`](envs/poc/main.tf) | same, in [`modules/cobble-environment/main.tf`](modules/cobble-environment/main.tf) |
| Tags and wrong-account guard | [`envs/poc/providers.tf`](envs/poc/providers.tf) | each step's `providers.tf` |
| Where state is stored | [`envs/poc/backend.tf`](envs/poc/backend.tf), created by [`bootstrap/`](bootstrap/) | each step's `backend.hcl` (same bootstrap bucket) |

## Control map

Status follows the project plan's wording:

- **Designed:** documented only.
- **Configured:** in this Terraform, so present whenever it is deployed. An
  account admin could still change it.
- **Enforced:** can't be turned off by people in the account (for example,
  by a service control policy).
- **Not covered:** not part of that solution.

Solution A is written and tested but not deployed; its column shows the
status each control reaches once it is.

Nothing in Solution B is enforced, because enforcement needs service control
policies or required CI checks (GitHub Free can't require them on a private
repo; project risk R7). Solution A adds the SCPs.

| Control | Solution B | Solution A (once deployed) | Implemented in |
|---|---|---|---|
| Separate account per environment | Designed | Configured | `solution-a/1-organization/accounts.tf` |
| Region restriction (Sydney + us-east-1 only) | Not covered | Enforced (SCP) | `1-organization/policies/restrict-regions.json.tftpl` |
| Root user blocked in member accounts | Not covered | Enforced (SCP) | `1-organization/policies/deny-root-user.json` |
| Single sign-on, separate admin/developer/read-only roles | Designed (IAM users with MFA for now) | Configured | `1-organization/identity-center.tf` |
| MFA for all people | Designed (set manually on IAM users) | Configured (Identity Center setting, set in the console) | Runbooks |
| Data at rest encrypted with a customer-managed KMS key, rotation on | Configured (one shared key) | Configured (a key per account) | `security-baseline/kms.tf`, `cobble-environment/kms.tf`, `2-security/kms.tf` |
| Every data bucket: versioned, public access blocked, access-logged | Configured | Configured, plus an account-wide public access block | `s3-bucket/main.tf`, `account-baseline/main.tf` |
| Audit log of every API call, all regions, integrity validation | Configured (removed on teardown) | Enforced (organisation trail; SCP) | `security-baseline/cloudtrail.tf`, `2-security/cloudtrail.tf` |
| Audit logs can't be edited or deleted | Not covered | Configured (Object Lock, governance mode); enforced with compliance mode | `2-security/log-archive.tf` |
| Audit log searchable in CloudWatch (90 days) | Configured | Designed (Phase 2; alerts come from Security Hub) | `security-baseline/cloudtrail.tf` |
| Threat detection (GuardDuty) | Configured | Enforced (every account; SCP) | `security-baseline/guardduty.tf`, `2-security/detection.tf` |
| Posture checks (Security Hub: CIS v3.0, AWS FSBP) | Designed | Enforced (SCP) | `2-security/detection.tf` |
| Configuration history (AWS Config) | Designed | Enforced (SCP) | `account-baseline/config.tf` |
| Resources shared outside the organisation flagged (Access Analyzer) | Not covered | Enforced (SCP) | `2-security/detection.tf` |
| Email alert on high and critical findings | Not covered | Configured | `2-security/alerts.tf` |
| Vulnerability scanning of container images | Not covered | Configured (ECR scan on push) | `3-shared-services/main.tf` |
| Vulnerability scanning of running workloads (Inspector) | Designed | Designed (Phase 2) | Implementation Guide §15 |
| Network traffic logging (VPC Flow Logs) | Configured (30 days) | Configured (30 or 90 days) | `network/flow-logs.tf` → `log-delivery` |
| App in private subnets, database with no internet route | Configured (no NAT, no app tier) | Configured (app reaches out via NAT; database tier has no route) | `network/` |
| VPC default security group locked down | Not covered | Configured | `network/default-security-group.tf` |
| Only the load balancer reaches the app; only the app reaches the database | Configured (demo only) | Configured | `container-service/security-groups.tf`, `postgres-database/main.tf` |
| Web firewall (AWS WAF managed rules, rate limit) | Not covered | Configured (staging, prod) | `container-service/waf.tf` |
| HTTPS with TLS 1.2 or later | Not covered (demo is HTTP) | Configured (once a certificate is set) | `container-service/load-balancer.tf` |
| Database password never in code | Not covered (no database) | Configured (RDS-managed secret) | `postgres-database/main.tf` |
| Backups | Configured (S3 versioning) | Configured (plus database backups, 35 days in prod) | `s3-bucket/`, `postgres-database/` |
| CI deploys without stored keys | Configured (`main` only; not used by CI yet) | Configured (read-only plan role for PRs; apply role behind GitHub environment approval) | `oidc-deploy-role/main.tf`, `github-oidc/main.tf` |
| Terraform refuses to run against the wrong account | Configured | Configured | each `providers.tf` |
| Monthly cost alert | Configured (USD 1) | Configured (per account) | `envs/poc/main.tf`, `cobble-environment/main.tf` |
| Guide-required tags on every resource | Configured | Configured | each `providers.tf` |
| fmt, validate, tests and tfsec on every pull request | Configured (merge not blocked: R7) | Configured (merge not blocked: R7) | `.github/workflows/ci.yml` |

Every finding from the two security scanners, and what was decided about it,
is in the [scan findings register](../docs/03-security-controls/scan-findings.md).

Known gaps in Solution A, kept honest:

- The organisation CloudTrail isn't streamed to CloudWatch, so the CIS 4.x
  metric-filter alarms aren't set up. Phase 2.
- The app signs in to the database as the admin user. A least-privilege app
  user is Phase 2.
- The apply role is an administrator of its own account, guarded by GitHub
  environment approval and SCPs. Narrowing it is Phase 2.
- Log Archive and Security Tooling share one account to save cost (the AWS
  Security Reference Architecture uses two).

## What it costs

Rough monthly estimates in US dollars for the Sydney region (AWS bills in
USD), assuming low traffic and resources left running all month. They are
for comparing the options, not quotes: confirm in the
[AWS Pricing Calculator](https://calculator.aws/) before committing.

| | Solution B | Solution B with demo app on | Solution A |
|---|---|---|---|
| Typical monthly cost | under $5 (near $0 when torn down between demos) | about $40 if left on (about $1.30 a day) | about $550 with every environment running |

Solution A by account:

| Account | Main costs | Estimate per month |
|---|---|---|
| Management + Security + Shared Services | GuardDuty, Security Hub checks, Config, KMS, log storage, ECR | $50 to $100 |
| dev | NAT gateway $43, load balancer ~$20, container ~$11, database $18, public IPs ~$11, logs and KMS | about $110 |
| staging | as dev, plus WAF ~$10 | about $120 |
| prod | 2 NAT gateways $86, load balancer ~$20, 2 larger containers ~$43, Multi-AZ database ~$80, WAF ~$10, public IPs ~$15 | about $260 |

The biggest lever is turning dev and staging off when nobody is using them
(`terraform destroy`; they're built to tear down cleanly), which brings
Solution A to roughly $330 a month.

Unit prices used:

| Item | Price | Source |
|---|---|---|
| NAT gateway (Sydney) | $0.059 per hour (~$43/month) | [cloudburn.io regional table](https://cloudburn.io/blog/aws-nat-gateway-pricing) |
| RDS PostgreSQL db.t4g.micro / db.t4g.small (Sydney, single-AZ) | ~$18 / ~$37 per month; Multi-AZ doubles it | [Bytebase RDS price data](https://www.bytebase.com/dbcost/rds/instance/db.t4g.small/) |
| Public IPv4 address | $0.005 per hour (~$3.65/month) | [Amazon VPC pricing](https://aws.amazon.com/vpc/pricing/) |
| Application Load Balancer | ~$0.025 per hour plus usage (US rate; Sydney is similar or slightly higher) | [Elastic Load Balancing pricing](https://aws.amazon.com/elasticloadbalancing/pricing/) |
| Fargate | ~$0.05 per vCPU-hour, ~$0.005 per GB-hour (approximate Sydney rate) | [AWS Fargate pricing](https://aws.amazon.com/fargate/pricing/) |
| AWS WAF | $5 per web ACL + $1 per rule per month + $0.60 per million requests | [AWS WAF pricing](https://aws.amazon.com/waf/pricing/) |
| KMS key | $1 per key per month | [AWS KMS pricing](https://aws.amazon.com/kms/pricing/) |
| AWS Config | $0.003 per configuration item recorded | [AWS Config pricing](https://aws.amazon.com/config/pricing/) |
| Security Hub | $0.001 per check (first 100,000), 30-day free trial | [Security Hub pricing](https://aws.amazon.com/security-hub/cspm/pricing) |

## Common commands

| Task | Where | Command |
|---|---|---|
| Deploy Solution B | `envs/poc/` | see [runbooks/deploy.md](../runbooks/deploy.md) |
| Tear down Solution B | `envs/poc/` | see [runbooks/teardown.md](../runbooks/teardown.md) |
| Deploy Solution A | `solution-a/` | see [runbooks/solution-a.md](../runbooks/solution-a.md) |
| Format everything | `infrastructure/` | `terraform fmt -recursive` |
| Run a module's tests | `modules/<name>/` | `terraform init` then `terraform test` |

Module tests use mocked providers, so they need no AWS credentials.

## Why it's built this way

| Practice | Source |
|---|---|
| One account per environment, organised into Security, Infrastructure and Workloads OUs | [AWS Security Reference Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/welcome.html), [Organizing your AWS environment](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/organizing-your-aws-environment.html) |
| Security services run by a delegated Security account, not the management account | AWS Security Reference Architecture |
| Guardrails as deny-list SCPs | [AWS Organizations SCP examples](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples.html) |
| Temporary credentials only (Identity Center for people, OIDC for CI) | [IAM security best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html) |
| Small modules with a README, `variables.tf` and `outputs.tf`; formatted with `terraform fmt` | [Terraform style guide](https://developer.hashicorp.com/terraform/language/style), [Standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure) |
| Mapping to recognised frameworks | [ASD Essential Eight](https://www.cyber.gov.au/resources-business-and-government/essential-cybersecurity/essential-eight), [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services), [NIST CSF](https://www.nist.gov/cyberframework), [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) |

## Design decisions

- [ADR 0001](../docs/02-landing-zone-design/adr/0001-deferred-landing-zone-design.md):
  what's deliberately deferred, and when to do it
- [ADR 0002](../docs/02-landing-zone-design/adr/0002-codebase-structure-for-readability.md):
  why the code is organised this way
- [ADR 0003](../docs/02-landing-zone-design/adr/0003-two-solutions-mvp-and-full-landing-zone.md):
  why there are two solutions, and how B is kept unchanged
