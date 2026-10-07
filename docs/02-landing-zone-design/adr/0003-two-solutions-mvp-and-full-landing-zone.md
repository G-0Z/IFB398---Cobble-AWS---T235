# ADR 0003: Deliver two solutions, an MVP (B) and a full landing zone (A), from one set of modules

**Status:** Proposed (for team and client review)
**Date:** 2026-10-06
**Deciders:** Max Gosling (PoC engineer), team T235, Wayne (Cyber Security Centre)

## Context

The unit asks for two solutions: one fully coded and one minimum viable
product (MVP). The client asked for recommendations that are implementable,
with a timeframe (for example 1 month against 3 months) and this semester's
and next semester's schedule (client meeting, 15 Sep 2026).

What already existed:

- A working, deployed single-account PoC (`infrastructure/envs/poc`,
  43 resources) with tests and CI (ADR 0002).
- ADR 0001, which designed the full landing zone (items D1 to D10) but
  deferred it, with a trigger for each item.

Constraints:

- The PoC must keep deploying and tearing down exactly as it does now
  (acceptance criterion; teammates' documents describe it).
- The full design can't be deployed yet: it needs the client's AWS
  organisation and a budget for six accounts.
- Readers include non-specialists (client, markers, future students).

## Decision

- **Solution B (MVP)** is the existing PoC in `infrastructure/envs/poc`,
  unchanged, plus one optional switch (`enable_demo_app`, default `false`)
  that adds a load balancer and container so the MVP can show a web page.
- **Solution A (full)** is ADR 0001's deferred design, built as code in
  `infrastructure/solution-a/`: numbered root configs run in order
  (organisation, security, shared services, workloads), covering D1, D2, D3,
  D5, D6 (roles) and D10 (code side).
- **One set of modules** serves both. Modules gain optional features for A
  (NAT gateways, database subnets, Object Lock, lifecycle rules), all off by
  default.

## Options considered

| Option | Summary | Verdict |
|---|---|---|
| 1. B = PoC, A = full landing zone, shared modules | This decision | Chosen |
| 2. Two competing designs (e.g. ECS against EKS) | A and B as alternatives, the report picks one | Rejected: the ECS against EKS comparison is already in the cost report; it doesn't give a deployable MVP |
| 3. Separate codebases for A and B | Copy the PoC and grow it into A | Rejected: duplicated code drifts, and B would no longer be a working slice of A |
| 4. Turn the PoC itself into A | Restructure `envs/poc` into the full layout | Rejected: breaks the working, deployed MVP and every document describing it (ADR 0002, option C) |

## How Solution B is kept unchanged

| Change made for A | Why B doesn't change |
|---|---|
| `network`: NAT gateways, database subnets, S3 endpoint | All created with `count`, defaulting to 0. The existing private route table and its associations keep the same addresses and values. New tests check the defaults create nothing extra. |
| `s3-bucket`: Object Lock, lifecycle rules | Default `null` (not set), so existing buckets plan no change. New tests check the defaults. |
| `bootstrap`: organisation state access | New bucket policy only when `organization_id` is set (default `null`). |
| `envs/poc`: demo app | `count = 0` unless `enable_demo_app = true`, set to `false` in `poc.auto.tfvars`. |
| `security-baseline` and `oidc-deploy-role` | Not touched. A uses new modules (`access-log-bucket`, `github-oidc`) instead of changing them. |

The cost of this is a small amount of duplication: the access-log bucket
exists in `security-baseline` (B) and in `access-log-bucket` (A). Merging
them would mean moving B's resources between modules, which isn't worth the
risk to a deployed system.

## Where Solution A departs from ADR 0001

| ADR 0001 said | Solution A does | Why |
|---|---|---|
| D3: roots compose single-purpose modules directly, no composite module | `cobble-environment` composite module used by dev, staging and prod | Three environments would mean copying ~150 lines three times; one module keeps them identical by construction |
| D1: separate Log Archive and Security Tooling accounts (AWS SRA) | One Security account | Halves fixed security cost; splitting later is straightforward |
| D6: apply role policy defined in the baseline | Apply role uses `AdministratorAccess` in its own account | Terraform must create IAM roles, networks and databases. Guarded by GitHub environment approval, SCPs and the organisation CloudTrail. Narrowing it is Phase 2. |

## Consequences

**Easier:**

- The MVP can be demonstrated at any time for about US$1.30 a day.
- The report can describe A and B side by side, with real code for both,
  and a clear upgrade path (B's modules are A's modules).
- A future team inherits a complete, tested design instead of a plan.

**Harder:**

- More code to review: about 4,800 lines of Terraform (roughly a fifth of
  it tests) and 900 lines of documentation. Mitigated by a README in every
  module and folder, and tests for every new module.
- A is validated and tested but not deployed, so its claims are
  "configured", not "enforced" (see the control map in
  `infrastructure/README.md`).

**Revisit when:**

- The client provides the AWS organisation: deploy A step by step
  (`runbooks/deploy-solution-a.md`) and update the control map.
- The CI workflow is wired to A's plan and apply roles (ADR 0001, D6).

## Timeframe

| Option | What gets delivered | Effort |
|---|---|---|
| 1 month | Solution B deployed for demos; Solution A steps 0 to 2 (organisation, guardrails, sign-in, security services) | 1 engineer, alongside the report |
| 3 months | All of Solution A, including dev, staging and prod, CI deploys, and a restore test of backups | 1 engineer plus team review; matches next semester |
