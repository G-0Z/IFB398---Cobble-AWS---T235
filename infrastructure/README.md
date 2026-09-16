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
| `main.tf` | Wires the five modules together |
| `variables.tf` | Everything configurable, see descriptions inline |
| `modules/oidc-deploy-role/` | GitHub Actions OIDC trust, so CI can deploy without stored AWS keys |
| `modules/logging/` | CloudTrail, KMS key, GuardDuty |
| `modules/storage/` | Encrypted platform data bucket |
| `modules/networking/` | VPC, public/private subnets, no NAT gateway (cost) |
| `modules/budget/` | AWS Budgets alert at 80%/100% of $25/month |

## Known simplifications (documented, not oversights)

- Single AWS account, single region. Target design uses per-environment accounts.
- Deploy role IAM policy is scoped by service, not per-resource ARN.
- No NAT gateway, private subnets have no internet egress yet.

Full reasoning for each is in the inline comments and in `adr/0003-poc-scope-vs-target-architecture.md`.