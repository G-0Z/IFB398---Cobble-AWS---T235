# Naming conventions

How things are named in this repo and in AWS. Read it when you need to
name something new, or work out what an existing name means. Most readers
only need the short version.

**Short version:** folders and files are `kebab-case`, Terraform names are
`snake_case`, AWS resource names are `cobble-<environment>-<thing>`, and a
name says *what the thing is*, not how it's built.

## Contents

1. [Folders](#1-folders)
2. [Files](#2-files)
3. [Terraform names (labels)](#3-terraform-names-labels)
4. [Variables and outputs](#4-variables-and-outputs)
5. [AWS resource names](#5-aws-resource-names)
6. [Tags](#6-tags)
7. [Docs, runbooks and branches](#7-docs-runbooks-and-branches)
8. [Decoding a name: worked examples](#8-decoding-a-name-worked-examples)

---

## 1. Folders

| Pattern | Meaning | Example |
|---|---|---|
| `infrastructure/modules/<what-it-builds>/` | A **module**: a reusable building block. Never run Terraform here directly (except `terraform test`). | `modules/postgres-database/` |
| `infrastructure/solution-b/` | The **root config** for Solution B. You run `terraform apply` here. | `solution-b/` |
| `infrastructure/solution-a/workload/` | The **root config** for one Solution A environment; the environment is chosen by its `.tfvars` | `workload/` |
| `infrastructure/solution-a/workload/<env>.tfvars` | One values file per environment | `demo.tfvars`, `prod.tfvars` |
| `infrastructure/solution-a/landing-zone/<n>-<step>/` | A landing-zone **root config**. The number is the order you run them in. | `landing-zone/2-security/` |
| `infrastructure/solution-a/landing-zone/identity/` | People and groups; run before step 1 | `identity/` |
| `docs/<nn>-<deliverable>/` | One folder per capstone deliverable; the number matches the brief | `docs/06-threat-model/` |

Solution B has three everyday names, **Solution B**, **the MVP** and **the
PoC**, and they all mean `solution-b/` (called `envs/poc/` until October 2026;
its state key `poc/terraform.tfstate` kept the old name).

Module folder names are nouns for **what gets built**, so the name answers
"what does this module give me?" (`postgres-database`, `container-service`).
The list of modules, and which solution uses each, is in
[`infrastructure/modules/README.md`](../infrastructure/modules/README.md).

**Renaming a folder is almost never safe.** Root configs are tied to their
state key, CI matrices and module `source` paths; see
[runbooks/README.md](../runbooks/README.md#deploying-into-a-different-aws-account).

## 2. Files

Every Terraform folder uses the same standard file names
([HashiCorp's standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)),
so you always know where to look:

| File | Holds |
|---|---|
| `main.tf` | The resources and module calls. Start reading here. |
| `variables.tf` | Inputs (`variable` blocks) |
| `outputs.tf` | Values handed to whoever calls this (`output` blocks) |
| `versions.tf` | Required Terraform and provider versions |
| `providers.tf` | AWS provider settings: region, allowed account, default tags (root configs only) |
| `backend.tf` | Where Terraform state is stored (root configs only) |
| `README.md` | What the folder builds and why |

When `main.tf` gets long, it's split **by concern**, and the file is named
after the AWS service or idea it contains:

| File | Contains | Example location |
|---|---|---|
| `kms.tf` | Encryption keys and their policies | `security-baseline/`, `solution-a/workload/` |
| `cloudtrail.tf` | Audit logging | `security-baseline/`, `solution-a/landing-zone/2-security/` |
| `guardduty.tf`, `detection.tf` | Threat detection and posture checks | `security-baseline/`, `solution-a/landing-zone/2-security/` |
| `iam.tf` | Roles and policies | `container-service/` |
| `security-groups.tf` | Firewall rules between components | `container-service/` |
| `load-balancer.tf`, `ecs.tf`, `waf.tf` | One AWS service each | `container-service/` |
| `nat.tf`, `endpoints.tf`, `flow-logs.tf`, `database-subnets.tf` | Optional network features | `network/` |
| `accounts.tf`, `organization.tf`, `guardrails.tf`, `identity-center.tf` | Organisation setup | `solution-a/landing-zone/1-organization/` |
| `alerts.tf`, `log-archive.tf` | Alerting and locked audit-log storage | `solution-a/landing-zone/2-security/` |

Other file types:

| Pattern | Meaning |
|---|---|
| `*.auto.tfvars` | The actual values for a root config. Terraform loads these automatically. **This is the file to edit to change a setting.** |
| `*.example` | A template to copy and fill in, e.g. `settings.auto.tfvars.example` → `settings.auto.tfvars`. The real copy holds account IDs and emails, so for Solution A steps it's **git-ignored** and never committed. Solution B's `poc.auto.tfvars` and the workload's `<env>.tfvars` files are the deliberate exceptions (committed, no secrets). |
| `policies/*.json` | A service control policy (SCP) as plain JSON |
| `policies/*.json.tftpl` | An SCP with placeholders that Terraform fills in (e.g. the allowed regions) |
| `tests/<module_name>.tftest.hcl` | Automated tests for a module, run with `terraform test` |
| `.terraform.lock.hcl` | Pinned provider versions. Generated; don't edit it. **Committed in every root config, git-ignored in modules** (a module's lock file is never used by the configs that call it). |

## 3. Terraform names (labels)

A label is the second name in a block, e.g. `network` in `module "network"`.
It's only used inside Terraform, never shown in AWS. Labels are always
`snake_case`.

### Resources and data sources

| Rule | Example | Why |
|---|---|---|
| Use `this` when a module has only one resource of that type | `aws_kms_key.this`, `aws_vpc.this` | The type already says what it is; `aws_vpc.vpc` would say it twice |
| Use `current` for data sources that describe "where am I running" | `data.aws_caller_identity.current`, `data.aws_region.current` | Reads as "the current account / region" |
| Otherwise, name it by its **role** | `aws_subnet.public`, `aws_subnet.private`, `aws_iam_role.plan`, `aws_iam_role.apply` | Tells two resources of the same type apart |
| Security group rules name the traffic: outbound rules `<from>_to_<to>`, inbound rules `<to>_from_<from>` | `load_balancer_to_tasks`, `tasks_from_load_balancer` | You can read the firewall rule from its name |
| Never repeat the resource type in the label | `aws_s3_bucket.access_logs`, not `aws_s3_bucket.access_logs_bucket` | |

### Module calls

Name a module call after **what it is in this context**, not after the
module folder. The same module can be called several times with different
labels:

```hcl
module "trail_bucket" {         # the bucket CloudTrail writes to
  source = "../s3-bucket"
}

module "platform_data_bucket" { # the bucket the platform stores data in
  source = "../s3-bucket"
}
```

### Locals

`snake_case`, named for the value they hold. Two locals appear in many
places:

| Local | Holds |
|---|---|
| `local.name` | The name prefix for this environment, e.g. `cobble-dev` |
| `local.account_id` | The AWS account ID Terraform is running in |

## 4. Variables and outputs

`snake_case`. The **ending** of the name tells you what kind of value it is:

| Ending | Holds | Example |
|---|---|---|
| `_arn` | An AWS ARN (a full resource identifier) | `kms_key_arn`, `certificate_arn` |
| `_id` / `_ids` | One / a list of AWS IDs | `vpc_id`, `private_subnet_ids`, `account_id` |
| `_name` | A resource name | `bucket_name`, `state_bucket_name` |
| `_cidr` / `_cidrs` | One / a list of IP ranges | `vpc_cidr`, `public_subnet_cidrs` |
| `_days` | A number of days | `log_retention_days`, `audit_log_retention_days` |
| `_email` | An email address | `alert_email`, `security_alert_email` |
| `_url` | A web address | `app_url`, `container_registry_url` |
| `_json` | A policy as a JSON string | `bucket_policy_json`, `task_role_policy_json` |
| `_mode` | One of a fixed set of options | `nat_gateway_mode` (`none`, `single`, `one_per_az`) |

On/off switches (booleans):

| Pattern | Meaning | Example |
|---|---|---|
| `enable_<feature>` | Turns a feature on or off. New optional features default to `false`, so adding one for Solution A never changes Solution B. A few protections that are normally wanted default to `true` and are switched off only where they'd clash (`enable_guardduty`, `enable_management_guardduty`, `enable_github_deploy`) | `enable_waf`, `enable_demo_app`, `enable_guardduty` |
| A plain statement | Describes the protection that's on when `true` | `protect_from_deletion`, `force_destroy`, `read_only_root_filesystem` |

The naming prefix comes in three forms; check the module's README for which
one it takes:

| Input | Meaning | Modules |
|---|---|---|
| `project_name` | Just the project, `cobble`. The module adds what it needs. | `network`, `security-baseline` |
| `name` | A full prefix the caller has already built, e.g. `cobble-dev` | `account-baseline`, `container-service`, `github-oidc` |
| `identifier` | Same as `name`, using the word RDS uses | `postgres-database` |

Outputs follow the same endings, so `module.network.vpc_id` is clearly an
ID and `app_url` is clearly a web address.

## 5. AWS resource names

These are the names you see in the AWS console. They're `kebab-case` and
start with the project and environment, so you can tell at a glance which
environment owns something:

```
cobble-<environment>-<thing>
   │        │          └─ what it is: alb, tasks, waf, db, monthly-cost ...
   │        └─ demo, dev, staging, prod (Solution B uses no environment part)
   └─ always "cobble"
```

| AWS resource | Pattern | Example |
|---|---|---|
| Most resources | `<prefix>-<thing>` | `cobble-dev-alb`, `cobble-dev-tasks`, `cobble-prod-waf` |
| IAM roles | `<prefix>-<what it's for>` | `cobble-dev-task-execution`, `cobble-dev-terraform-plan`, `cobble-dev-terraform-apply` |
| S3 buckets | `<prefix>-<purpose>-<account-id>` | `cobble-dev-data-123456789012`, `cobble-tfstate-123456789012` |
| CloudWatch log groups | `/<prefix>/<source>` | `/cobble/cloudtrail`, `/cobble/vpc-flow-logs`, `/cobble-dev/app` |
| KMS key aliases | `alias/<prefix>` or `alias/<prefix>-<purpose>` | `alias/cobble-dev`, `alias/cobble-logs` |
| Budgets | `<prefix>-monthly-cost` | `cobble-prod-monthly-cost` |
| Database security group | `<prefix>-db` | `cobble-prod-db` |
| Database admin user | `cobble_admin` | |
| Container registry | `cobble-module` | |

Bucket names end in the account ID because S3 bucket names must be unique
across **all** AWS customers. The database user is `cobble_admin` with an
underscore because PostgreSQL doesn't allow hyphens there.

Solution A organisation names:

| Thing | Pattern | Examples |
|---|---|---|
| AWS accounts | `cobble-<purpose>` | `cobble-security`, `cobble-shared-services`, `cobble-dev`, `cobble-staging`, `cobble-prod` |
| Organisational units | `PascalCase`, following the AWS Security Reference Architecture | `Security`, `Infrastructure`, `Workloads`, `NonProduction`, `Production` |
| Identity Center groups (who people are) | `cobble-<team>` | `cobble-platform-admins`, `cobble-developers`, `cobble-auditors` |
| Permission sets (what a role can do) | `Cobble<Role>` | `CobblePlatformAdmin`, `CobbleDeveloper`, `CobbleReadOnly` |

## 6. Tags

Every resource gets these tags automatically from `default_tags` in each
`providers.tf`, as required by the client's *Cobbled AWS Platform
Engineering Implementation Guide*. Tag keys are `PascalCase`.

| Tag | Meaning | Example values |
|---|---|---|
| `Application` | The application, named as in the Implementation Guide | `Cobbled` |
| `Environment` | Which environment | `poc`, `demo`, `dev`, `staging`, `prod` |
| `ManagedBy` | How it was created. `IaC` means "change it in Terraform, not in the console". | `IaC` |
| `Owner` | Who is responsible | `Cyber Security Centre` |
| `CostCentre` | Who pays | `Cobble` |
| `DataClass` | How sensitive the data is | `Internal` |
| `Criticality` | How bad an outage is | `Low`, `Medium`, `High` |

## 7. Docs, runbooks and branches

| Thing | Pattern | Example |
|---|---|---|
| Design decisions | A numbered paragraph under [Key decisions](02-landing-zone-design/README.md#key-decisions): the decision, why, and when to revisit it | Decision 5: PostgreSQL for now |
| Runbooks | `runbooks/<action>[-<target>].md`. No target means Solution B (the first runbooks written); new ones always name a target. List every runbook in [`runbooks/README.md`](../runbooks/README.md) | `deploy.md`, `deploy-solution-a.md`, `demo-solution-a.md` |
| A deliverable's main page | `docs/<nn>-<deliverable>/README.md`, so GitHub shows it when the folder is opened | `docs/06-threat-model/README.md` |
| Personal branches | `<Firstname>-dev`, merged to `main` by pull request | `Khai-dev`, `max-dev` |

## 8. Decoding a name: worked examples

| You see | Read it as | Defined in |
|---|---|---|
| `module.app.aws_lb.this` | The load balancer (`aws_lb`), the only one (`this`), in the workload's app (`app` → `container-service`) | `modules/container-service/load-balancer.tf` |
| `cobble-staging-terraform-plan` (IAM role) | The read-only role GitHub Actions uses to run `terraform plan` in staging | `modules/github-oidc/main.tf` |
| `/cobble/vpc-flow-logs` (log group) | Network traffic logs for Solution B | `modules/network/flow-logs.tf` → `modules/log-delivery/` |
| `enable_waf = true` | Turn on the optional web firewall | `modules/container-service/waf.tf` |
| `aws_vpc_security_group_egress_rule.load_balancer_to_tasks` | Firewall rule: the load balancer may reach the app containers | `modules/container-service/security-groups.tf` |
