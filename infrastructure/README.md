# Terraform PoC (Deliverable 4)

Proves the landing zone design in `docs/02-landing-zone-design/` actually
deploys, repeatably, via `terraform apply`. This is **PoC scope**, not
the full target architecture, see the "Open questions" section of
`docs/01-reference-architecture/reference-architecture.md` for what's
deliberately left out (NAT gateway, multi-account split, compute) and why.

## Prerequisites

- Terraform >= 1.10 (needed for `use_lockfile` S3-native state locking)
- AWS CLI, configured with your own IAM user's access key (`aws configure`),
  never root credentials
- Your own AWS console access already set up in the shared account

## One-time setup (first person only)

The state bucket this config's backend needs doesn't exist until someone
creates it. If `bootstrap/README.md` says this is already done, skip to
**Setup** below.

1. `cd bootstrap`
2. `terraform init && terraform apply`
3. Confirm the bucket name matches `backend.tf` in this directory.

## Setup

1. Copy `terraform.tfvars.example` to `terraform.tfvars`.
2. Fill in/check `alert_email`, `github_org` and `github_repo` (ask in
   Discord if the shared alert address has changed).
3. `terraform init`
4. `terraform plan` and read it before applying anything.
5. `terraform apply`

## Redeploying / making changes

- Everyone shares the same remote state (S3, with `use_lockfile` locking),
  so `plan` before every `apply` and don't apply concurrently with someone
  else.
- After the first `apply`, `deploy_role_arn` (a Terraform output) is the
  role GitHub Actions can assume via OIDC — no long-lived AWS keys needed
  in CI for subsequent deploys.
- `terraform destroy` tears down everything this config created *except*
  the bootstrap state bucket (that's a separate config, see
  `bootstrap/README.md`) — deliberate, so destroying the PoC doesn't also
  delete the state it needs to know what to destroy.

## What's here

| File/folder | Purpose |
|---|---|
| `main.tf` | Wires the modules together |
| `variables.tf` | Everything configurable, see descriptions inline |
| `bootstrap/` | One-time state bucket, applied by hand before anything else |
| `foundation/oidc-deploy-role/` | GitHub Actions OIDC trust, so CI can deploy without stored AWS keys |
| `foundation/logging/` | CloudTrail, KMS key, GuardDuty |
| `data/` | Encrypted platform data bucket |
| `network/` | VPC, public/private subnets, no NAT gateway (cost) |
| `foundation/budget/` | AWS Budgets alert at 80%/100% of $25/month |
| `edge/`, `platform/`, `environments/` | Empty placeholders — see below |
| `modules/` | Not a Terraform module folder — reserved for future per-Cobbled-module infra, see `modules/README.md` |

## Folder layout

The folder names follow the IaC repository structure in section 15.1 of
the Cobbled AWS Platform Engineering Implementation Guide, so this PoC
grows into the same shape the target architecture uses instead of
needing a rename later.

| Folder | Target responsibility | PoC status |
|---|---|---|
| `foundation/` | Org, accounts, identity, log archive, security admin | Implemented: `oidc-deploy-role`, `logging`, `budget` |
| `network/` | VPCs, subnets, endpoints, gateways, firewall controls | Implemented: VPC + public/private subnets, no NAT |
| `data/` | RDS, subnet/parameter/option groups, backups, keys | Implemented as a plain encrypted S3 bucket (no RDS in PoC scope) |
| `edge/` | CloudFront, S3 origins, WAF, API Gateway, certificates | Empty — out of PoC scope (see ADR 0003) |
| `platform/` | ECS/EKS, internal ALB, service discovery, deployment roles | Empty — out of PoC scope (see ADR 0003) |
| `modules/{plane}/{code}/` | Per-Cobbled-module ECR/API/route/secrets/widget | Empty — no Cobbled application modules deployed by this PoC |
| `environments/{dev\|test\|prod\|dr}/` | Approved environment parameters, no plaintext secrets | Empty — PoC currently uses a single root `terraform.tfvars` |

## Known simplifications (documented, not oversights)

- Single AWS account, single region. Target design uses per-environment accounts.
- Deploy role IAM policy is scoped by service, not per-resource ARN.
- No NAT gateway, private subnets have no internet egress yet.
- One shared KMS key for CloudTrail and the platform data bucket, instead of
  separate keys per environment/data class.
- `edge/`, `platform/` and `environments/` are empty scaffolding for
  future work, not missing PoC deliverables — the PoC scope only covers
  identity, logging, budget, networking and storage.

Full reasoning for each is in the inline comments and in `adr/0003-poc-scope-vs-target-architecture.md`.