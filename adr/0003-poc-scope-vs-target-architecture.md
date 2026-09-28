# ADR 0003: PoC scope vs. target architecture

## Status

Accepted

## Context

Deliverable 4 asks for "a small but working prototype or scaffold... to
demonstrate repeatable deployment of core platform infrastructure" — not a
production-ready build of the full Cobble AWS platform described in the
Cobbled AWS Platform Engineering Implementation Guide (multi-account
landing zone, ECS/Fargate, RDS SQL Server, API Gateway, per-module
infrastructure, etc.). Building the full target architecture is out of
scope for a single-semester student capstone; the value is in proving the
landing-zone patterns work and are automated, not in operating a real
multi-tenant SaaS platform.

This ADR is where the deliberate gaps between "what the PoC deploys" and
"what the target architecture describes" get written down, so they read as
documented tradeoffs instead of oversights when someone (a teammate, a
marker, a future team) reads the Terraform.

## Decision

The PoC (`infrastructure/`) intentionally simplifies the target
architecture in these ways:

- **Single AWS account, single region** (`ap-southeast-2`). The target
  design uses separate accounts per environment/purpose (management, log
  archive, security tooling, dev, test, prod, DR — see the guide's section
  3). One shared student account is enough to prove the automation works.
- **The GitHub Actions deploy role's IAM policy is scoped by service, not
  by resource ARN** (`foundation/oidc-deploy-role`). It grants broad
  `service:*` actions across the services this PoC touches (EC2, S3, IAM,
  CloudTrail, GuardDuty, Budgets, KMS, CloudWatch Logs), rather than
  per-resource-ARN least privilege. Tightening this to specific resource
  ARNs is real follow-up work, not something to copy into a production
  deploy role unexamined.
- **No NAT gateway.** Private subnets (`network/`) have no internet route.
  Fine while nothing is deployed into them; add a NAT gateway (or a NAT
  instance, cheaper for a student budget) when compute actually needs
  outbound access from a private subnet.
- **One shared KMS key** for CloudTrail, VPC flow logs, and the platform
  data bucket (`foundation/logging`), instead of separate keys per
  environment/data class as the guide recommends (section 10.2).
- **A single S3 bucket stands in for the RDS-based data tier** (`data/`).
  No database in this PoC — provisioning and securing RDS for SQL Server is
  a substantial piece of work on its own and isn't needed to prove the
  landing-zone automation.
- **`force_destroy = true` on the PoC's S3 buckets** (trail, platform data,
  access logs). The PoC needs to demonstrate clean `terraform destroy` /
  `terraform apply` cycles, not just a one-way deploy; a bucket that
  refuses to delete because it has objects in it defeats that. Not a
  setting to carry into a bucket holding real, unrecoverable data.
- **`edge/`, `platform/`, `modules/{plane}/{code}/` and `environments/`
  are empty scaffolding**, not missed deliverables. They exist so the
  folder layout already matches the target architecture's shape
  (`infrastructure/README.md` has the full mapping), but nothing in the
  PoC needs CloudFront/WAF/API Gateway, ECS/EKS, or a real Cobble
  application module deployed.

## Consequences

- Someone extending this PoC toward the real target architecture has a
  single place (this ADR) that says which gaps are "known and accepted for
  now" versus which ones would be a genuine step backward if copied
  forward unexamined — the IAM policy scoping and shared KMS key
  especially.
- Security scanning (tfsec) is configured to flag genuinely fixable gaps
  (VPC flow logs, S3 access logging, CloudTrail→CloudWatch — all fixed) and
  to suppress, with an inline comment citing this ADR, the specific
  findings that are PoC-scope tradeoffs rather than real gaps (the wildcard
  IAM policy, public subnets' public IPs). A suppression without that
  reasoning is a bug waiting to be found later; one that points back here
  is a documented decision.
- Anyone reviewing the Terraform for this project should read "PoC" as a
  scope statement, not a quality bar — the parts that are built (identity,
  logging, budget, networking, storage) follow the same security practices
  (least-privilege where practical, encryption at rest, no public
  exposure, audit logging) the target architecture calls for; what's
  different is what's *included*, not how carefully the included parts are
  built.
