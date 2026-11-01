# ADR 0001: Ship a working single-config PoC; defer the full landing-zone layout

> [!NOTE]
> Kept as written on 6 October 2026. Most of the deferred design (D1, D2, D3, D5, D6 roles, D10) was then built as Solution A ([ADR 0003](0003-two-solutions-mvp-and-full-landing-zone.md)). `infrastructure/envs/poc/` was renamed `infrastructure/solution-b/` on 14 October 2026. Identity Center is now the supported sign-in; the team's IAM users and their access keys remain until Phase 2 milestone M1 (D10).

- **Status:** Accepted
- **Date:** 2026-10-06
- **Deciders:** T235 (Max Gosling, with team review)

## Context

The Terraform PoC (deliverable 4) deploys everything from one root config,
`infrastructure/envs/poc/`: CloudTrail, GuardDuty, the GitHub OIDC deploy
role, the KMS key, the budget, the VPC and the data bucket. A design review
against the *Cobbled AWS Platform Engineering Implementation Guide v1.0*
found that this works but doesn't match the Guide's target layout:

- The Guide (§3, §15.1) separates long-lived account and organisation
  resources (`foundation/`) from per-environment workloads
  (`environments/{dev|test|prod}/`). Here they share one lifecycle, so
  tearing down the PoC also deletes the audit trail of that teardown.
- The Guide (§3.2) requires IAM Identity Center and prohibits routine IAM
  users and long-lived keys. The PoC account uses IAM users.
- The account's root email is a team member's personal address.

The team's constraints are that the PoC must work this semester, cost as close
to zero as possible, and still be defensible against the Guide.

## Decision

Keep the single root config and make it work, with only the cheap fixes that
close real risks or match mandatory Guide requirements:

1. The OIDC deploy role trusts `main` only, not pull requests, because it
   holds `iam:*`.
2. Provider `default_tags` follow the Guide's required tags (`Application`,
   `Environment`, `ManagedBy`, `Owner`, `CostCentre`, `DataClass`,
   `Criticality`). `Plane` and `Module` are omitted: there are no application
   workloads yet.
3. A committed `poc.auto.tfvars` provides every input, and `allowed_account_ids`
   stops an apply against the wrong account.
4. Near-zero cost: the PoC is deployed only around demos and torn down
   afterwards, with a USD 1/month budget so any real spend alerts. All
   Guide-required controls (KMS CMK, CloudTrail, GuardDuty) stay in.
5. Human access moves to the org: the org takes over root email and billing,
   and provides IAM Identity Center. IAM users stay, with MFA, only until then.

Everything below was designed during the review but is **deferred**. Each item
lists the trigger that should prompt doing it.

## Deferred design

| # | Design | Why it's deferred | Trigger to do it |
|---|---|---|---|
| D1 | **Split account and environment layers.** `foundation/<account>/bootstrap/` (state bucket) and `foundation/<account>/baseline/` (CloudTrail, GuardDuty, OIDC + CI roles, budget, its own KMS key and access-log bucket) are long-lived. `environments/<env>/` holds only the workload (network, data, its own KMS key and access-log bucket) and can be torn down freely. Nothing crosses between layers. | Biggest structural change; not needed for the PoC to work. | Before the audit trail must survive teardowns (e.g. evidence for deliverables 3 and 7), or before a second environment exists. |
| D2 | **Naming via `name_prefix`.** Modules take one `name_prefix` (`cobble-poc`, `cobble-baseline`) instead of `project_name`, giving names like `cobble-poc-access-logs-<account>`. Fixes the doubled log-group path `/cobble/cobble/...`. | Only required once D1 puts two copies of a module in one account (names would collide). | With D1. |
| D3 | **Single-purpose modules.** Split `security-baseline` into `kms-key`, `log-bucket`, `cloudtrail`, `guardduty`; rename `oidc-deploy-role` to `github-oidc` (it will create two roles). Roots compose them directly; no composite module. | Only pays off when both layers reuse `kms-key` and `log-bucket`. | With D1. |
| D4 | **Bootstrap self-hosting.** After the first apply, migrate bootstrap's local state into its own bucket (`bootstrap/terraform.tfstate`). | Today one person holds the local state file; recoverable by `terraform import` (see `runbooks/bootstrap.md`). | When anyone other than the current holder needs to change bootstrap, or at hand-over. |
| D5 | **Partial backend config.** `backend "s3" {}` plus a committed `backend.hcl` per root, `terraform init -backend-config=backend.hcl`. State keys `bootstrap/`, `baseline/`, `envs/<env>/`. | With one environment, the hardcoded `backend.tf` is clearer. | When a second environment or account is added. |
| D6 | **CI plan and apply.** A read-only plan role trusted by pull requests (state read on `envs/*`, lock-file write only), and an apply role trusted by `main` plus a GitHub `environment` with reviewers (any of the 4 members, 1 approval, self-review blocked). Apply re-plans on `main` and applies that exact saved plan. Baseline and bootstrap stay human-applied. The apply role's policy lives in the baseline, so widening CI's rights needs a human apply. | The PoC is applied by hand a few times per semester; automating it adds roles and review overhead. | When deploys become frequent, or a second person regularly deploys. |
| D7 | **Dynamic CI matrix.** A setup job globs `foundation/*/*`, `environments/*`, `modules/*` instead of hardcoded lists. | The matrix is small and rarely changes. | With D1 (directory count roughly doubles). |
| D8 | **Pin module versions.** Environments reference modules by git tag (`?ref=network-v1.2.0`) instead of relative paths. | One environment, so there's nothing to keep apart. | When a second environment exists. |
| D9 | **Decommission runbook.** Order: destroy environments, empty and destroy baseline, migrate bootstrap state back to local, destroy bootstrap, then hand the account back or close it. Trail and state buckets get `prevent_destroy`, removed only as a runbook step. | Only meaningful once D1 creates a protected layer. | With D1, and in any case before the account is handed over or closed at the end of the capstone. |
| D10 | **Root and identity hand-over.** Root email to an org-controlled address with MFA; billing under the org's payer; IAM Identity Center permission sets (`platform-admin`, `read-only`) per Guide §3.2; delete all IAM users. If the org enables GuardDuty or an organization CloudTrail centrally, remove those from this repo. | Needs the org to act. | Requested from the org on 2026-10-06; do as soon as they respond. |

## Consequences

- **Good:** a deployable PoC (`terraform plan` shows 43 resources and no
  conflicts) with the Guide's required controls and tags, and near-zero
  running cost.
- **Accepted:** teardown deletes CloudTrail and its logs (D1); interim IAM
  users breach Guide §3.2 until the org responds (D10); one shared KMS key
  for audit and data (D1).
- **Hand-over:** a successor team gets the target design and a trigger for each
  item, without inheriting half-built infrastructure.
