# ADR 0004: One workload folder, one settings file per environment

- **Status:** Accepted
- **Date:** 2026-10-14
- **Deciders:** T235 (Max Gosling, with team review)

## Context

Solution A first had a folder per environment (dev, staging, prod), each
calling the same composite module. The copies drifted: a fix made in one
folder had to be remembered in the others, and a reader couldn't tell which
differences between environments were intended.

## Options

| Option | Verdict |
|---|---|
| A folder per environment | Rejected: the copies had already drifted |
| One root config, chosen by a settings file per environment | Chosen |
| Terraform workspaces | Rejected: the environment would be invisible in folder and file names, which makes the wrong-account mistake easier |

## Decision

[`infrastructure/solution-a/workload/`](../../infrastructure/solution-a/workload/)
is one root config. Each environment is one values file (`demo.tfvars`,
`dev.tfvars`, `staging.tfvars`, `prod.tfvars`) and its own state key
(`solution-a/workload/<env>/terraform.tfstate`), passed to `terraform init`.
`demo.tfvars` deploys the workload into Solution B's account for a few hours,
so both solutions can be shown in the console.

## Consequences

- Environments can only differ where a variable lets them: size, the standby
  database copy and the web firewall.
- A fix lands in every environment at once.
- Choosing the wrong `-backend-config` key points Terraform at the wrong
  state. The runbooks and [`lz-dev.ps1`](../../infrastructure/solution-a/lz-dev.ps1)
  pass it explicitly, and each provider has `allowed_account_ids`.

**Revisit if** environments start to differ in structure, not just size.
