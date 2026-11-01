# State

> **Standards:** [Overview](README.md) · [Directory structure](directory-structure.md) · [File layout](file-layout.md) · [Naming](naming.md) · **State** · [Modules](modules.md) · [Variables and outputs](variables-and-outputs.md) · [Version control](version-control.md) · [Documentation](documentation.md) · [Testing and validation](testing-and-validation.md)

State is Terraform's record of what it built. Lose it or point it at the
wrong place, and Terraform will try to build everything again on top of
what's already there.

## Rules

**One state bucket, created by `bootstrap/`.** It's versioned, encrypted,
public access blocked, and not force-destroyable. Bootstrap keeps its own
state locally, because a bucket can't be created by the run that stores
state in it ([runbooks/bootstrap.md](../../runbooks/bootstrap.md)).

**Every root config has one fixed key. Never change it.**

| Root config | State key |
|---|---|
| `solution-b` | `poc/terraform.tfstate` (the folder's old name, kept on purpose) |
| `solution-a/workload` | `solution-a/workload/<environment>/terraform.tfstate`, chosen at `terraform init` with `-backend-config="key=…"` |
| `landing-zone/<step>` | `solution-a/landing-zone/<step>/terraform.tfstate` |

A new key makes Terraform believe nothing exists. To move state, use
`terraform init -migrate-state` deliberately, never by editing `backend.tf`.

**Locking is on.** Every backend sets `use_lockfile = true` (S3's native lock
file, Terraform 1.10+). Don't add DynamoDB locking, and don't
`force-unlock` while someone else might be running.

**The bucket name is written out in every `backend.tf`**, because Terraform
doesn't allow variables there. Deploying into another account means changing
it in each; [runbooks/README.md](../../runbooks/README.md#deploying-into-a-different-aws-account)
lists every place.

**State never leaves the bucket.** No `*.tfstate` and no saved plan
(`*.tfplan`) is ever committed: both can contain secrets. `.gitignore`
covers them.

## Layered root configs

The landing zone is split into root configs by **lifecycle and privilege**,
applied in order, so each layer can be torn down without touching the ones
beneath it:

| Layer | Root config | Lives | Torn down between demos? |
|---|---|---|---|
| People | `identity` | Permanently | No |
| Organisation, accounts, guardrails | `1-organization` | Permanently; accounts have `prevent_destroy` | No |
| Security services | `2-security` | While anything runs | Yes |
| Shared services | `3-shared-services` | While environments run | Yes |
| An environment | `workload` + `<env>.tfvars` | Its own lifetime | Yes |

A higher layer reads what it needs from a lower one through outputs copied
into its settings (account IDs, the Config bucket and key). It never manages
a lower layer's resources. Why: tearing down an environment can't delete the
audit trail of that teardown, and the accounts survive every demo
([ADR 0010](../decisions/0010-keep-accounts-between-demos.md)).

## Guarding against the wrong account

Every root config's `providers.tf`:

- **Pins the account** with `allowed_account_ids`, so a wrong profile can't
  deploy dev into prod.
- **Assumes a role when it needs one.** Everything runs from the management
  account. `workload` reaches its environment's account through
  `assume_role_name`; `2-security` and `3-shared-services` assume
  `OrganizationAccountAccessRole` in their providers; `identity` and
  `1-organization` run in the management account directly.
- **Tags everything** with the required [tags](naming.md#tags).

Before any `apply`, check `aws sts get-caller-identity` shows the account you
expect. `lz-dev.ps1` refuses to run otherwise.

## Plans that delete things

Read every plan before applying it. A plan that **destroys or replaces**
something long-lived (an account, the audit bucket, the state bucket) is
stopped and discussed, not applied. `lz-dev.ps1 up` refuses any organisation
plan that would delete anything.

---

[↑ Back to the top](#state) · ← [Naming](naming.md) · Next: [Modules →](modules.md)
