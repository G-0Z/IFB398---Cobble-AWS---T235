# Directory structure

> **Standards:** [Overview](README.md) · **Directory structure** · [File layout](file-layout.md) · [Naming](naming.md) · [State](state.md) · [Modules](modules.md) · [Variables and outputs](variables-and-outputs.md) · [Version control](version-control.md) · [Documentation](documentation.md) · [Testing and validation](testing-and-validation.md)

## The layout

```
.
├── infrastructure/
│   ├── bootstrap/                 state bucket; run once per account
│   ├── solution-b/                Solution B: one root config
│   ├── solution-a/
│   │   ├── lz-dev.ps1             one-command demo
│   │   ├── workload/              one environment; demo / dev / staging / prod.tfvars
│   │   └── landing-zone/
│   │       ├── identity/          people and groups
│   │       ├── 1-organization/    organisation, accounts, guardrails
│   │       ├── 2-security/        Security account
│   │       └── 3-shared-services/ container registry
│   ├── modules/                   building blocks; never applied directly
│   │   └── .terraform-docs.yml    generates each module README's reference
│   └── README.md                  what the code builds, control map, costs
├── runbooks/                      step-by-step deploy, demo, teardown
├── docs/
│   ├── handbook/                  how the platform works, and the glossary
│   ├── standards/                 these rules
│   ├── deliverables/              the capstone deliverables
│   ├── decisions/                 architecture decision records
│   ├── project/                   definition, way of working, sprints, meetings, plans
│   └── media/                     diagrams and screenshots
└── .github/                       CI, drift check, templates
```

## Rules

**Two kinds of Terraform folder, never mixed.**

| Kind | Where | You run | Has |
|---|---|---|---|
| **Root config** | `bootstrap/`, `solution-b/`, `solution-a/workload/`, `solution-a/landing-zone/*/` | `terraform apply` | Its own `backend.tf`, `providers.tf`, state key and committed lock file |
| **Module** | `modules/<name>/` | Only `terraform test` | No backend, no provider blocks, no lock file in Git |

Why: a root config owns state and credentials; a module owns neither, so it
can be reused anywhere.

**One root config per lifecycle.** Things that live and die together share a
root config; things with different lifecycles get their own. The landing
zone is split into numbered steps because the organisation outlives the
security services, and both outlive an environment. (See
[State](state.md#layered-root-configs).)

**One workload, many environments.** Solution A's environments are one root
config, chosen by a values file and a state key
([ADR 0004](../decisions/0004-one-workload-per-environment.md)). Don't copy
the folder per environment.

**Settings live beside the root config they configure.** `*.tfvars` and
`settings.auto.tfvars` files sit in the root config's folder, not in a
shared `environments/` folder, so the runbooks and `lz-dev.ps1` always know
where to look.

**Landing-zone folders are numbered in the order they're applied.**
`identity/` comes first and isn't numbered.

**Every folder has a README.** See [Documentation](documentation.md).

**Renaming a root config is almost never safe.** It's tied to its state key,
the CI matrices and module `source` paths. If you must, follow
[runbooks/README.md](../../runbooks/README.md#deploying-into-a-different-aws-account)
and move the state first.

## Adding something

| Adding | Put it in | Also |
|---|---|---|
| A building block used by more than one root config | `modules/<what-it-builds>/` | Add it to the test matrix in `ci.yml`, write tests, generate its README |
| A new environment | A new `<env>.tfvars` in `solution-a/workload/` | Its own state key at `terraform init`; a drift-check variable if it stays deployed |
| A new landing-zone step | `landing-zone/<n>-<step>/` | A backend key, a README, and the validate and Trivy matrices in `ci.yml` |
| A runbook | `runbooks/<action>-<target>.md` | List it in `runbooks/README.md` |

---

[↑ Back to the top](#directory-structure) · ← [Overview](README.md) · Next: [File layout →](file-layout.md)
