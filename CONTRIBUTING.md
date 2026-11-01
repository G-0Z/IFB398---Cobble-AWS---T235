# Contributing

How a change gets into this repository. The rules themselves are in the
[Terraform standards](docs/standards/README.md); this page is the short path
through them.

## Workflow

1. Pick an issue from the [project board](https://github.com/users/G-0Z/projects/2),
   or create one from a template (task, bug or documentation request).
2. Work on your personal branch, `<Firstname>-dev` (for example `Khai-dev`).
3. Run the checks below, then open a pull request to `main`. The template
   carries the definition of done, and CI runs automatically.
4. Get one approving review; a ruleset on `main` enforces it. The ruleset
   doesn't require the CI checks yet, so **reviewers check that CI is green
   before approving**.
5. Merge.

More: [version control](docs/standards/version-control.md),
[how the team works](docs/project/way-of-working.md).

## Before you push

```powershell
# In infrastructure/: CI fails on unformatted code
terraform fmt -recursive

# In each root config you touched
terraform init -backend=false; terraform validate

# In each module you touched (mocked AWS, no sign-in needed)
terraform init -backend=false; terraform test

# In each module whose variables or outputs changed
terraform-docs -c ../.terraform-docs.yml .

# From the repo root, per root config: CI fails on any finding
trivy config --ignorefile .trivyignore.yaml infrastructure/<root-config>
```

What each check catches, and how to fix a failure:
[testing and validation](docs/standards/testing-and-validation.md) and the
[workflows README](.github/workflows/README.md).

## The rules that matter most

- **Never change a `key` in a `backend.tf`** ([state](docs/standards/state.md)).
- **Never commit** a filled-in `settings.auto.tfvars`, `users.csv`, a plan
  or a state file ([version control](docs/standards/version-control.md#never-commit)).
- **Change AWS through code, never the console.**
- **New optional module features are `enable_<feature>` switches that
  default to off** ([modules](docs/standards/modules.md#switching-features-on)).
- **Redact screenshots** before committing them ([documentation](docs/standards/documentation.md#evidence)).
- **A change is done** when it has been deployed, torn down and redeployed
  from code, and a final plan shows no differences
  ([when a change is done](docs/standards/testing-and-validation.md#when-a-change-is-done)).

Names follow [naming](docs/standards/naming.md): folders and files
`kebab-case`, Terraform names `snake_case`, AWS resources
`cobble-<environment>-<thing>`.
