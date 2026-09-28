# Terraform PoC (Deliverable 4)

Proves the landing zone design in `docs/02-landing-zone-design/` actually
deploys, repeatably, via `terraform apply`. This is **PoC scope**, not
the full target architecture, see the "Open questions" section of
`docs/01-reference-architecture/reference-architecture.md` for what's
deliberately left out (NAT gateway, multi-account split, compute) and why.

## Prerequisites

- Terraform >= 1.7
- AWS CLI, configured with your own IAM user's access key (`aws configure`),
  never root credentials
- Your own AWS console access already set up in the shared account

## Setup

1. Copy `terraform.tfvars.example` to `terraform.tfvars`.
2. Fill in `alert_email` (ask in Discord if you don't have the shared address).
3. `terraform init`
4. `terraform plan` and read it before applying anything.

## What's here

| File/folder | Purpose |
|---|---|
| `main.tf` | Wires the modules together |
| `variables.tf` | Everything configurable, see descriptions inline |
| `foundation/oidc-deploy-role/` | GitHub Actions OIDC trust, so CI can deploy without stored AWS keys |
| `foundation/logging/` | CloudTrail, KMS key, GuardDuty |
| `data/` | Encrypted platform data bucket |
| `network/` | VPC, public/private subnets, no NAT gateway (cost) |
| `foundation/budget/` | AWS Budgets alert at 80%/100% of $25/month |
| `edge/`, `platform/`, `modules/`, `environments/` | Empty placeholders — see below |

## Folder layout

The folder names follow the IaC repository structure in section 15.1 of
the Cobbled AWS Platform Engineering Implementation Guide, so this PoC
grows into the same shape the target architecture uses instead of
needing a rename later.

| Folder | Target responsibility | PoC status |
|---|---|---|
| `foundation/` | Org, accounts, identity, log archive, security admin | `oidc-deploy-role` done; `logging`, `budget` empty |
| `network/` | VPCs, subnets, endpoints, gateways, firewall controls | Empty — networking module not yet rebuilt here |
| `data/` | RDS, subnet/parameter/option groups, backups, keys | Empty — only a plain S3 bucket planned for PoC |
| `edge/` | CloudFront, S3 origins, WAF, API Gateway, certificates | Empty — out of PoC scope (see ADR 0003) |
| `platform/` | ECS/EKS, internal ALB, service discovery, deployment roles | Empty — out of PoC scope (see ADR 0003) |
| `modules/{plane}/{code}/` | Per-Cobbled-module ECR/API/route/secrets/widget | Empty — no Cobbled application modules deployed by this PoC |
| `environments/{dev\|test\|prod\|dr}/` | Approved environment parameters, no plaintext secrets | Empty — PoC currently uses a single root `terraform.tfvars` |

## Known simplifications (documented, not oversights)

- Single AWS account, single region. Target design uses per-environment accounts.
- Deploy role IAM policy is scoped by service, not per-resource ARN.
- No NAT gateway, private subnets have no internet egress yet.
- `edge/`, `platform/`, `modules/` and `environments/` are empty scaffolding for
  future work, not missing PoC deliverables — the PoC scope only covers
  identity, logging, budget, networking and storage.

Full reasoning for each is in the inline comments and in `adr/0003-poc-scope-vs-target-architecture.md`.