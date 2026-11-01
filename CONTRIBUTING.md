# Contributing

How changes get into this repository. It's short because most rules are
enforced by CI; the ones that aren't are listed here.

## Workflow

1. Work on your personal branch, `<Firstname>-dev` (for example `Khai-dev`).
2. Open a pull request to `main`. CI runs on it automatically.
3. Get one approving review. GitHub Free can't make CI checks mandatory on
   a private repository, so **reviewers check that CI is green before
   approving**.
4. Merge.

## Before you push

```powershell
# In infrastructure/: CI fails on unformatted code
terraform fmt -recursive

# In each root config you touched
terraform init -backend=false; terraform validate

# In each module you touched (mocked AWS, no sign-in needed)
terraform init -backend=false; terraform test

# From the repo root, per root config: CI fails on any finding
trivy config --ignorefile .trivyignore.yaml infrastructure/<root-config>
```

A deliberate Trivy exception goes next to the code as a `#trivy:ignore`
comment with the reason, and gets a row in the
[scan findings register](docs/03-security-controls/scan-findings.md).

## Rules CI can't check

- **Never change a `key` in a `backend.tf`.** Terraform finds what it
  already built through that key; a new one makes it think nothing exists.
- **Never commit** a filled-in `settings.auto.tfvars`, `users.csv`, a
  `*.tfplan` or a `*.tfstate`. They hold account IDs, emails or secrets.
  `.gitignore` covers them; don't force-add them.
- **Change AWS through code, never the console.** A console change is
  drift and the nightly check will flag it.
- **New module features are `enable_<feature>` switches that default to
  off**, so a change for Solution A never alters what Solution B builds.
- **Redact evidence** before committing screenshots: account IDs,
  organisation IDs, emails and ARNs.
- **A change is done** when it has been deployed, torn down and redeployed
  from code, a final `terraform plan -detailed-exitcode` exits 0, and the
  run is recorded in the [evidence log](docs/Evidence/README.md#evidence-log).

## Naming

Folders and files `kebab-case`, Terraform names `snake_case`, AWS resources
`cobble-<environment>-<thing>`. Everything else, with examples, is in
[naming conventions](docs/naming-conventions.md).
