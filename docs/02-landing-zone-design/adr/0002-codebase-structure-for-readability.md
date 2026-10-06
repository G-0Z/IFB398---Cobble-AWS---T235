# ADR 0002: Restructure the Terraform for readability, without changing what it deploys

**Status:** Accepted
**Date:** 2026-10-06
**Deciders:** Max Gosling (PoC engineer), one peer reviewer per the project plan

## Context

The project plan makes the Terraform PoC something other people must read,
not just run:

- Four teammates own written deliverables that describe the PoC (security
  controls, threat model, compliance mapping, field name definitions).
- Wayne (Cyber Security Centre) takes long-term ownership of the account and
  architecture.
- Risk R4: the documents must not drift from the code, so every control has to
  point to the Terraform that implements it.
- Risk R5: knowledge is concentrated in one person.

An architecture review of the code (43 resources, 5 modules) found that it is
harder to read than its size suggests:

- **The same S3 bucket hardening is written out in full three times**
  (CloudTrail bucket, platform data bucket, state bucket), with no single
  place that says "this is how we build a bucket".
- **The same "service writes to an encrypted CloudWatch log group" setup is
  written twice** (CloudTrail and VPC flow logs), including an identical
  security-scanner exception.
- **`budget` and `data` are shallow modules.** Each wraps a single concept
  whose inputs the root config already declares and passes straight through.
  Changing the budget limit touched 5 files.
- **Every value is stated twice:** root variable defaults repeat
  `poc.auto.tfvars`, and the budget module adds a third copy.
- **Log group names come out as `/cobble/cobble/...`.**
- **Two test files point to README notes that don't exist.**

Constraints: the PoC must keep deploying and destroying cleanly with one
command each (acceptance criterion), CI must stay green (validate, tests,
tfsec), and ADR 0001 has already deferred the larger layout changes.

## Decision

Option B below: consolidate within the current layout. Every change is a
**pure restructure**. The resources deployed, their settings and their count
(43) stay the same. The only visible change is the corrected log group names.

## Options Considered

### Option A: Documentation only

Add a reader's guide and a control map; leave the code as is.

| Dimension | Assessment |
|-----------|------------|
| Complexity | Low |
| Cost | None |
| Scalability | Duplication grows with every new bucket or log stream |
| Team familiarity | High: nothing changes |

**Pros:** zero risk to the working deployment.
**Cons:** a reader still has to compare three near-identical bucket blocks to
find out whether they really are identical, and the 5-file budget change
stays.

### Option B: Consolidate within the current layout (chosen)

- Add two small **building-block modules**, each written once:
  - `s3-bucket`: a hardened bucket (versioning, SSE-KMS, public access
    blocked, access logging, optional bucket policy).
  - `log-delivery`: an encrypted log group, plus the role a service uses to
    write to it.
- Delete the shallow `budget` and `data` modules. Their contents move into
  `envs/poc/main.tf`, which becomes a readable table of contents.
- Keep values in one place: `poc.auto.tfvars`, with no root defaults.
- Fix log group names, remove unused variables, fix broken test references.
- Add a control map to `infrastructure/README.md` that marks each control as
  designed, configured or enforced, as the project plan requires.

| Dimension | Assessment |
|-----------|------------|
| Complexity | Medium: modules move, the deployment doesn't |
| Cost | None (no new resources) |
| Scalability | New buckets and log streams are a 6-line module call |
| Team familiarity | Same layout and module names; two new small modules |

**Pros:** each concept has one home. The root config reads top to bottom as
the list of what gets deployed. There are fewer files to keep in sync. The
building blocks are tested once.
**Cons:** a reader follows one extra hop to see what a bucket contains. Nothing
is deployed yet, so moving resources between modules needs no state
migration.

### Option C: Adopt the Guide's full layout now

Implement ADR 0001 D1–D3: `foundation/` and `environments/` roots, separate
keys and log buckets per layer, single-purpose modules.

| Dimension | Assessment |
|-----------|------------|
| Complexity | High: new roots, cross-layer ordering, more runbooks |
| Cost | About US$1/month more (a second KMS key) |
| Scalability | Best: matches Guide §15.1 and supports more environments |
| Team familiarity | Low: doubles the number of roots to learn |

**Pros:** closest to the target architecture.
**Cons:** reopens ADR 0001 without new information. It makes the PoC harder
to understand in the short term, which is the opposite of this ADR's goal.

## Trade-off Analysis

The goal is that a teammate or Wayne can open the repo and quickly find what is
deployed and where each control lives. Option A addresses *where* but leaves
the duplication that makes the code slow to verify. Option C serves the
long-term shape, at the cost of readability now. Option B gets most of
the readability for moderate effort, changes nothing in AWS, and leaves C's
layout open: the two building blocks are what C's layers would be built from.

Two exceptions to "build every bucket with `s3-bucket`" are deliberate:

- **The state bucket (`bootstrap/`)** stays self-contained. It is already
  deployed, and it must never change because a shared module changed.
- **The access-log bucket** stays hand-written. It is the logging
  destination, so it can't log to itself, and AWS doesn't let it use KMS. Both
  are exceptions that `s3-bucket` deliberately doesn't allow.

## Consequences

- **Easier:**
  - Finding what's deployed: read `envs/poc/main.tf`.
  - Changing a value: edit `poc.auto.tfvars` only.
  - Adding a hardened bucket or log stream: one short module call.
  - Mapping controls to code for deliverables 3 and 7: see the control map.
- **Harder:** one extra hop when inspecting a bucket's settings.
- **Revisit:**
  - When ADR 0001 D1–D3 is triggered, build the new layers from `s3-bucket` and
    `log-delivery`.
  - If the repo moves to `Cyber-Safety-Centre/2701-T235-AWS-Platform`
    (project plan), update `github_org`/`github_repo` in `poc.auto.tfvars`, or
    the deploy role's trust policy won't match.

## Action Items

1. [x] Add `modules/s3-bucket` and `modules/log-delivery`, with tests
2. [x] Use them in `security-baseline`, `network` and `envs/poc`
3. [x] Delete `modules/budget` and `modules/data`; inline them in `envs/poc/main.tf`
4. [x] Remove root variable defaults; `poc.auto.tfvars` is the single source
5. [x] Fix log group names, the unused bootstrap variable, and stale test comments
6. [x] Update the CI test matrix, READMEs, and the control map
7. [ ] Peer review (project plan: one approving review per Terraform change)
8. [ ] Field name definitions (deliverable owned by Max): build from the
   control map and each module's README
