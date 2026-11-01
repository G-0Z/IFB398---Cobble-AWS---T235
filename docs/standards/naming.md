# Naming

> **Standards:** [Overview](README.md) · [Directory structure](directory-structure.md) · [File layout](file-layout.md) · **Naming** · [State](state.md) · [Modules](modules.md) · [Variables and outputs](variables-and-outputs.md) · [Version control](version-control.md) · [Documentation](documentation.md) · [Testing and validation](testing-and-validation.md)

**Short version:** folders and files are `kebab-case`, Terraform names are
`snake_case`, AWS resource names are `cobble-<environment>-<thing>`, and a
name says *what the thing is*, not how it's built.

## Folders and files

- `kebab-case`, always: `postgres-database/`, `load-balancer.tf`,
  `deploy-solution-a.md`.
- Module folders are nouns for **what gets built**, so the name answers
  "what does this give me?": `postgres-database`, not `rds`.
- Landing-zone steps are `<n>-<step>`, numbered in the order they're
  applied: `2-security`.
- Solution B has three everyday names, **Solution B**, **the MVP** and **the
  PoC**, and all three mean `solution-b/`. It was called `envs/poc/` until
  October 2026, and its state key `poc/terraform.tfstate` kept the old name.

## Terraform names (labels)

A label is the second name in a block, such as `network` in
`module "network"`. It's only used inside Terraform. Labels are always
`snake_case`.

| Rule | Example | Why |
|---|---|---|
| Use `this` when a module has only one resource of that type | `aws_kms_key.this`, `aws_vpc.this` | The type already says what it is |
| Use `current` for "where am I running" data sources | `data.aws_caller_identity.current` | Reads as "the current account" |
| Otherwise, name it by its **role** | `aws_subnet.public`, `aws_iam_role.plan` | Tells two of the same type apart |
| Security group rules name the traffic: outbound `<from>_to_<to>`, inbound `<to>_from_<from>` | `load_balancer_to_tasks`, `tasks_from_load_balancer` | You can read the rule from its name |
| Never repeat the resource type | `aws_s3_bucket.access_logs`, not `access_logs_bucket` | |
| Name a module call after **what it is here**, not the module folder | `module "trail_bucket"` and `module "platform_data_bucket"`, both `source = "../s3-bucket"` | The same module is often called twice |

Two locals appear in many places: `local.name` (the name prefix, such as
`cobble-dev`) and `local.account_id`.

## Variables and outputs

`snake_case`. The **ending** says what kind of value it holds:

| Ending | Holds | Example |
|---|---|---|
| `_arn` | An AWS ARN | `kms_key_arn` |
| `_id` / `_ids` | One / a list of AWS IDs | `vpc_id`, `private_subnet_ids` |
| `_name` | A resource name | `state_bucket_name` |
| `_cidr` / `_cidrs` | One / a list of IP ranges | `vpc_cidr`, `public_subnet_cidrs` |
| `_days` | A number of days | `log_retention_days` |
| `_email` | An email address | `alert_email` |
| `_url` | A web address | `app_url` |
| `_json` | A policy as a JSON string | `bucket_policy_json` |
| `_mode` | One of a fixed set of options | `nat_gateway_mode` (`none`, `single`, `one_per_az`) |

Booleans: `enable_<feature>` turns a feature on or off (see
[Modules](modules.md#switching-features-on)); a plain statement describes
the protection that's on when `true` (`protect_from_deletion`,
`read_only_root_filesystem`).

The naming prefix comes in three forms; a module's README says which it
takes:

| Input | Meaning | Modules |
|---|---|---|
| `project_name` | Just the project, `cobble`. The module adds the rest | `network`, `security-baseline` |
| `name` | A full prefix the caller built, such as `cobble-dev` | `account-baseline`, `container-service`, `github-oidc` |
| `identifier` | Same as `name`, in RDS's word | `postgres-database` |

## AWS resource names

What you see in the console. `kebab-case`, starting with the project and
environment, so you can tell at a glance which environment owns something:

```
cobble-<environment>-<thing>
   │        │          └─ what it is: alb, tasks, waf, db, monthly-cost ...
   │        └─ demo, dev, staging, prod (Solution B has no environment part)
   └─ always "cobble"
```

| Resource | Pattern | Example |
|---|---|---|
| Most resources | `<prefix>-<thing>` | `cobble-dev-alb`, `cobble-prod-waf` |
| IAM roles | `<prefix>-<what it's for>` | `cobble-dev-task-execution`, `cobble-dev-terraform-plan` |
| S3 buckets | `<prefix>-<purpose>-<account-id>` | `cobble-dev-data-123456789012` |
| CloudWatch log groups | `/<prefix>/<source>` | `/cobble/vpc-flow-logs`, `/cobble-dev/app` |
| KMS key aliases | `alias/<prefix>` or `alias/<prefix>-<purpose>` | `alias/cobble-dev` |
| Budgets | `<prefix>-monthly-cost` | `cobble-prod-monthly-cost` |
| Database admin user | `cobble_admin` | Underscore, because PostgreSQL doesn't allow hyphens |
| Container registry | `cobble-module` | |

Bucket names end in the account ID because S3 names must be unique across
**all** AWS customers.

Organisation names (Solution A):

| Thing | Pattern | Examples |
|---|---|---|
| Accounts | `cobble-<purpose>` | `cobble-security`, `cobble-dev` |
| Organisational units | `PascalCase`, as in the AWS Security Reference Architecture | `Security`, `Workloads`, `Production` |
| Identity Center groups (who people are) | `cobble-<team>` | `cobble-platform-admins`, `cobble-auditors` |
| Permission sets (what a role can do) | `Cobble<Role>` | `CobblePlatformAdmin`, `CobbleReadOnly` |

## Tags

Every resource gets these from `default_tags` in each `providers.tf`, as the
Implementation Guide requires. Keys are `PascalCase`. Don't repeat them on
individual resources; a resource sets only its own extra tags, such as `Name`.

| Tag | Meaning | Example values |
|---|---|---|
| `Application` | The application, as the Guide names it | `Cobbled` |
| `Environment` | Which environment | `poc`, `demo`, `dev`, `staging`, `prod` |
| `ManagedBy` | `IaC` means "change it in Terraform, not the console" | `IaC` |
| `Owner` | Who is responsible | `Cyber Security Centre` |
| `CostCentre` | Who pays | `Cobble` |
| `DataClass` | How sensitive the data is | `Internal` |
| `Criticality` | How bad an outage is | `Low`, `Medium`, `High` |

## Docs, runbooks and branches

| Thing | Pattern | Example |
|---|---|---|
| Runbooks | `runbooks/<action>[-<target>].md`, listed in `runbooks/README.md` | `deploy-solution-a.md` |
| Decision records | `docs/decisions/<nnnn>-<decision>.md`, numbered in the order written | `0004-one-workload-per-environment.md` |
| Deliverable pages | `docs/deliverables/<deliverable>.md` | `threat-model.md` |
| Standards pages | `docs/standards/<topic>.md` | `naming.md` |
| Sprint records | `docs/project/phase-<n>-sprints.md` for a finished phase; `phase-<n>-plan.md` for the next | `phase-1-sprints.md` |
| Meetings | `docs/project/phase-<n>-meetings.md`: a section per sprint, a `### Week <n>: <team or client> meeting <n>` heading per meeting | `phase-1-meetings.md` |
| Personal branches | `<Firstname>-dev`, merged to `main` by pull request | `Khai-dev`, `max-dev` |

## Decoding a name

| You see | Read it as | Defined in |
|---|---|---|
| `module.app.aws_lb.this` | The load balancer, the only one (`this`), in the workload's app (`app` → `container-service`) | `modules/container-service/load-balancer.tf` |
| `cobble-staging-terraform-plan` | The read-only role GitHub Actions uses to run `terraform plan` in staging | `modules/github-oidc/main.tf` |
| `/cobble/vpc-flow-logs` | Network traffic logs for Solution B | `modules/network/flow-logs.tf` → `modules/log-delivery/` |
| `enable_waf = true` | Turn on the optional web firewall | `modules/container-service/waf.tf` |
| `aws_vpc_security_group_egress_rule.load_balancer_to_tasks` | Firewall rule: the load balancer may reach the app containers | `modules/container-service/security-groups.tf` |

---

[↑ Back to the top](#naming) · ← [File layout](file-layout.md) · Next: [State →](state.md)
