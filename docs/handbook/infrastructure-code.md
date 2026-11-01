# Infrastructure code

> **Handbook:** [Start here](README.md) · [Architecture](architecture.md) · **Infrastructure code** · [Operations](operations.md) · [Security](security.md) · [Deliverables](deliverables.md) · [Glossary](glossary.md) · [Standards](../standards/README.md)

How the Terraform in [`infrastructure/`](../../infrastructure/README.md) is
organised, how an environment is assembled from it, where its settings and
state live, and what checks every change goes through.

## Layout

```
infrastructure/
├── bootstrap/                 The S3 bucket Terraform keeps its state in. Run once per account
├── solution-b/                Solution B: one account, one `terraform apply`
├── solution-a/
│   ├── lz-dev.ps1             One-command demo: landing zone + dev up, down, status
│   ├── workload/              One Solution A environment; chosen by demo/dev/staging/prod.tfvars
│   └── landing-zone/          The organisation around the environments, run in order:
│       ├── identity/              people and groups (Identity Center directory)
│       ├── 1-organization/        organisation, OUs, accounts, guardrails, group → role assignments
│       ├── 2-security/            Security account: locked logs, trail, detection, alerts
│       └── 3-shared-services/     Shared Services account: container registry
└── modules/                   Building blocks used by both solutions. Never applied directly
```

Two kinds of folder:

- **Root configs** are folders you run `terraform apply` in. There are
  seven: `bootstrap`, `solution-b`, `solution-a/workload`, and the four
  `landing-zone/*` steps. Each has its own state and its own `backend.tf`.
- **Modules** are reusable building blocks under `modules/`. They're only
  ever called from a root config, and only ever run directly for their
  tests.

Every folder has a README that says what it builds, what you fill in, and
which runbook to follow. Module READMEs end with a usage example and a
reference section generated from the code by terraform-docs.

## The modules

| Module | Builds | Used by |
|---|---|---|
| [`network`](../../infrastructure/modules/network/) | A VPC across two zones with public and private subnets and flow logs. Optional: NAT gateways (`none`, `single`, `one_per_az`), a database subnet layer, an S3 gateway endpoint, a locked default security group | A, B |
| [`s3-bucket`](../../infrastructure/modules/s3-bucket/) | One hardened bucket: KMS-encrypted, versioned, public access blocked, access-logged, an optional bucket policy (used for HTTPS-only on the log buckets), optional lifecycle rules | A, B |
| [`log-delivery`](../../infrastructure/modules/log-delivery/) | An encrypted CloudWatch log group plus the IAM permission a service needs to write to it | A, B |
| [`container-service`](../../infrastructure/modules/container-service/) | ECS Fargate cluster, service and task definition; ALB with health checks and HTTPS; security-group chain; task and execution roles; optional WAF and auto scaling; deployment circuit breaker | A; B's optional demo page |
| [`github-oidc`](../../infrastructure/modules/github-oidc/) | The GitHub OIDC provider and the two roles (plan, apply), scoped to this repository and one state file | A, B |
| [`postgres-database`](../../infrastructure/modules/postgres-database/) | RDS PostgreSQL in the database subnets; security group allowing only the app; forced TLS; managed admin secret; backups; optional Multi-AZ and deletion protection | A |
| [`account-baseline`](../../infrastructure/modules/account-baseline/) | Account-wide public-bucket block, EBS encryption by default, password policy, AWS Config recorder delivering to the central bucket | A |
| [`access-log-bucket`](../../infrastructure/modules/access-log-bucket/) | The bucket that receives S3 and ALB access logs for an account | A |
| [`security-baseline`](../../infrastructure/modules/security-baseline/) | Solution B's all-in-one account security: KMS key, CloudTrail with CloudWatch copy, GuardDuty, access-log bucket | B |

Modules follow HashiCorp's standard structure (`main.tf`, `variables.tf`,
`outputs.tf`, `versions.tf`, README, `tests/`). A rule the codebase keeps:
new optional features are `enable_<feature>` switches that default to off,
so adding something for Solution A never changes what Solution B builds. A
few existing protections default to on (for example `enable_guardduty`).

## How an environment is assembled

[`solution-a/workload/main.tf`](../../infrastructure/solution-a/workload/main.tf)
is written to be read top to bottom; it's the full inventory of one
environment:

1. **Account safety settings** (`account-baseline`), skipped in the demo
   because that account is shared with Solution B.
2. **Access-log bucket** for this account.
3. **Network**: three tiers, flow logs, S3 endpoint, locked default
   security group.
4. **Tenant data bucket** encrypted with this environment's key.
5. **Application** (`container-service`): the image, size and count from the
   values file; database host, port and name as environment variables;
   username and password as Secrets Manager references; a task role allowing
   only its own bucket and key; WAF, certificate, logging and deletion
   protection as the values file dictates.
6. **Database** (`postgres-database`), reachable only from the app's
   security group.
7. **GitHub deploy roles** (`github-oidc`), skipped in the demo because the
   account already has a provider from Solution B.
8. **Monthly budget** with 80% actual and 100% forecast alerts.

Plus [`kms.tf`](../../infrastructure/solution-a/workload/kms.tf) (the
environment's key) and
[`providers.tf`](../../infrastructure/solution-a/workload/providers.tf),
which pins the account, sets the region, assumes a role into the target
account when run from the management account, and stamps every resource with
the required tags.

[`solution-b/main.tf`](../../infrastructure/solution-b/main.tf) reads the
same way: `security_baseline`, `github_deploy`, `network`,
`platform_data_bucket`, the budget, and the optional `demo_app`.

## Settings

| Kind | File | Committed? |
|---|---|---|
| One environment's values | `solution-a/workload/{demo,dev,staging,prod}.tfvars` | Yes. They hold no secrets; `REPLACE:` placeholders mark the values that come from the landing zone's outputs (account IDs, registry URL, Config bucket and key) |
| Solution B's values | `solution-b/poc.auto.tfvars` | Yes, loaded automatically |
| A landing-zone step's values | `landing-zone/<step>/settings.auto.tfvars` | **No.** They hold real account IDs and email addresses. Each step ships a `.example` to copy |
| People and groups | `landing-zone/identity/users.csv` | **No.** Personal details. `users.csv.example` shows the shape |

The `.gitignore` encodes this: all `*.tfvars` are ignored, then the committed
ones are re-included, then Solution A's filled-in `settings.auto.tfvars` and
`users.csv` are excluded again. Saved plan files (`*.tfplan`) are never
committed because they can contain sensitive values.

## State

Terraform's record of what it has built lives in one S3 bucket created by
[`bootstrap/`](../../infrastructure/bootstrap/): versioned, encrypted,
public access blocked, not force-destroyable (Terraform won't delete it
while it holds state files), with native locking
(Terraform 1.10+). Bootstrap keeps its *own* state locally, because a bucket
can't be created by the run that stores state in it.

Each root config has a fixed key in that bucket:

| Root config | State key |
|---|---|
| `solution-b` | `poc/terraform.tfstate` (the folder's old name; kept on purpose) |
| `solution-a/workload` | `solution-a/workload/<environment>/terraform.tfstate`, chosen at `terraform init` with `-backend-config="key=…"` |
| `landing-zone/identity`, `1-organization`, `2-security`, `3-shared-services` | `solution-a/landing-zone/<step>/terraform.tfstate` |

**Never change a state key.** Terraform would believe nothing exists and
try to build everything again on top of what's already there.

The bucket name appears literally in every `backend.tf` because Terraform
doesn't allow variables there. Deploying into a different AWS account means
changing it in each; [runbooks/README.md](../../runbooks/README.md#deploying-into-a-different-aws-account)
lists every place.

When `organization_id` is set, bootstrap also adds a bucket policy so the
GitHub roles in Solution A's environment accounts can reach their own state
under `solution-a/workload/`.

## Provider guards and tags

Every root config's `providers.tf` does three things:

- **Pins the account.** `allowed_account_ids` makes Terraform refuse to run
  against anything but the intended account, so a wrong profile can't
  deploy dev into prod.
- **Assumes a role when needed.** Everything is run from the management
  account. `workload` reaches into its environment's account through the
  role passed as `assume_role_name` (`OrganizationAccountAccessRole`).
  `2-security` and `3-shared-services` assume `OrganizationAccountAccessRole`
  in their providers, with no setting. `identity` and `1-organization` run
  in the management account directly.
- **Tags everything.** `default_tags` applies the Implementation Guide's
  required tags to every resource: `Application`, `Environment`,
  `ManagedBy = IaC`, `Owner`, `CostCentre`, `DataClass`, `Criticality`
  ([tags standard](../standards/naming.md#tags)).

## Checks on every change

[`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) runs on every
pull request to `main` and on every push to `main` or a `*-dev` branch.
Nothing in it touches a real AWS account.

| Job | What it does | Scope |
|---|---|---|
| Terraform format | `terraform fmt -check -recursive` | All of `infrastructure/` |
| Terraform validate | `terraform init -backend=false` then `terraform validate` | All 7 root configs |
| Terraform module tests | `terraform test` against `tests/*.tftest.hcl` | All 9 modules plus `solution-a/workload` |
| Trivy security scan | `trivy config` for Terraform misconfigurations. Any finding of any severity fails the job | All 7 root configs, following module calls into `modules/` |
| Module READMEs | `terraform-docs --output-check`: each README's generated reference matches the code | All 9 modules |
| CI passed | Passes only if every job above passed, so a ruleset can require one check | |

Notes on how it's set up:

- The tests use `mock_provider`, so they need no credentials, cost nothing
  and never see a real account. They assert the shape of what a module
  would create (for example, that the database has no public access).
- Every action is pinned to a commit hash with the release in a comment, so
  a moved tag can't change what runs. The workflow's GitHub token is
  read-only.
- Terraform `1.16.2` in CI and the drift workflow matches the committed lock files; it's bumped
  deliberately. Lock files are committed per root config, not per module.
- Deliberate exceptions are inline comments with a reason: `#trivy:ignore`
  for new ones, and older `#tfsec:ignore` ones, which Trivy also honours.
  [`.trivyignore.yaml`](../../.trivyignore.yaml) is kept for any exception
  that can't go inline (none today).
- `main` requires one approving review, enforced by a GitHub ruleset. The
  ruleset doesn't require the CI checks yet (GitHub Pro could), so reviewers
  check the result before approving; this is recorded as a known gap.

Beyond CI, [Checkov](https://www.checkov.io/) is run by hand as a stricter
second opinion, and a manual review on 7 October 2026 found five issues no
scanner could see. Every finding from all three, and what was decided about
it, is in the
[scan findings register](../deliverables/security-controls.md#scan-findings-register).

## Drift detection

[`drift.yml`](../../.github/workflows/drift.yml) runs nightly at 04:00
Brisbane time. For each of dev, staging and prod it signs in with that
environment's read-only plan role via OIDC and runs
`terraform plan -detailed-exitcode`. Exit code 2 means something in AWS no
longer matches the code; the job fails, which emails the repository's
watchers. An environment is skipped until its plan role ARN is stored as a
repository variable (`SOLUTION_A_<ENV>_PLAN_ROLE_ARN`). The demo and
Solution B aren't checked because they're torn down between demos.

## Conventions

The rules for changing this code (layout, file names, naming, state,
modules, variables, version control, docs and testing) are the
[Terraform standards](../standards/README.md). The short version: folders
and files are `kebab-case`, Terraform labels `snake_case`, AWS names
`cobble-<environment>-<thing>`; never change a state key; new optional
module features default to off.

## Everyday commands

| Task | Where | Command |
|---|---|---|
| Tidy formatting | `infrastructure/` | `terraform fmt -recursive` |
| Check a folder without AWS | that folder | `terraform init -backend=false` then `terraform validate` |
| Run a module's tests | `modules/<name>/` or `solution-a/workload/` | `terraform init -backend=false` then `terraform test` |
| Scan like CI does | repo root | `trivy config --ignorefile .trivyignore.yaml infrastructure/solution-a/workload` |
| Deploy, demo, tear down | | [operations.md](operations.md) |

---

[↑ Back to the top](#infrastructure-code) · ← [Architecture](architecture.md) · Next: [Operations →](operations.md)
