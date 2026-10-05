# Infrastructure

Terraform for the Cobble AWS PoC (Capstone deliverable 4).

```
infrastructure/
├── bootstrap/         Root config. Creates the state bucket. Run once, local state.
├── envs/
│   └── poc/           Root config. Wires the modules together. Remote state.
└── modules/           Reusable building blocks, each with its own README and tests.
    ├── security-baseline/   KMS key, CloudTrail, GuardDuty, access-log bucket
    ├── oidc-deploy-role/    GitHub OIDC provider and CI deploy role
    ├── budget/              Monthly cost budget with 80% and 100% alerts
    ├── network/             VPC, public and private subnets, flow logs
    └── data/                Encrypted platform data bucket
```

**Root configs** are where you run `terraform init/plan/apply`.
**Modules** are never applied directly; `envs/poc/main.tf` calls them.

## How the modules connect

| Module | Uses outputs from |
|---|---|
| `security-baseline` | nothing |
| `oidc-deploy-role` | nothing |
| `budget` | nothing |
| `network` | `security-baseline` (KMS key for flow logs) |
| `data` | `security-baseline` (KMS key, access-log bucket) |

## Common commands

| Task | Where | Command |
|---|---|---|
| Deploy | `envs/poc/` | see [runbooks/deploy.md](../runbooks/deploy.md) |
| Tear down | `envs/poc/` | see [runbooks/teardown.md](../runbooks/teardown.md) |
| Format everything | `infrastructure/` | `terraform fmt -recursive` |
| Run a module's tests | `modules/<name>/` | `terraform init` then `terraform test` |

Module tests use mocked providers, so they need no AWS credentials.
