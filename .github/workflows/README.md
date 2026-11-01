# GitHub Actions workflows

Two workflows check the Terraform. Neither can change anything in AWS: CI
never signs in to AWS, and the drift check only uses a read-only role.
Deploys are run by hand from the [runbooks](../../runbooks/README.md).

| Workflow | Runs | Signs in to AWS? | Fails when |
|---|---|---|---|
| [`ci.yml`](ci.yml) | Every pull request to `main`; every push to `main` or a `*-dev` branch | No | Code is unformatted or invalid, a test fails, Trivy finds anything, or a module README is out of date |
| [`drift.yml`](drift.yml) | Nightly at 04:00 Brisbane time, or by hand | Yes, with each environment's read-only plan role (OIDC) | Something in AWS no longer matches the code |

How these fit with the rest of the testing is in the
[testing and validation standard](../../docs/standards/testing-and-validation.md).

## CI (`ci.yml`)

| Job | What it does | Scope | If it fails |
|---|---|---|---|
| **Terraform format** | `terraform fmt -check -recursive` | All of `infrastructure/` | Run `terraform fmt -recursive` in `infrastructure/` and push |
| **Terraform validate** | `terraform init -backend=false`, then `terraform validate` | All 7 root configs | Fix the error it names |
| **Terraform module tests** | `terraform test` against `tests/*.tftest.hcl`, with a mocked AWS | All 9 modules and `solution-a/workload` | Run `terraform init -backend=false; terraform test` in that folder |
| **Trivy security scan** | `trivy config` for Terraform misconfigurations, any severity | All 7 root configs, following their module calls | Fix it, or add a `#trivy:ignore` comment with the reason and a row in the [scan findings register](../../docs/deliverables/security-controls.md#scan-findings-register) |
| **Module READMEs** | `terraform-docs --output-check` on every module | All 9 modules | Run `terraform-docs -c ../.terraform-docs.yml .` in that module and push |
| **CI passed** | Passes only if every job above passed | | Fix the job that failed |

How it's set up:

- **Read-only.** The workflow's token can only read the repository
  (`permissions: contents: read`), and it has no AWS credentials.
- **Pinned.** Every action is pinned to a commit hash, with the release in a
  comment, so a moved tag can't change what runs. Terraform is pinned to
  `1.16.2`, the version the lock files were made with, and terraform-docs is
  downloaded at `v0.24.0` and checked against its published checksum.
- **Every result is real.** Matrix jobs use `fail-fast: false`, so one
  failing folder doesn't hide the others.
- **One summary check.** The **CI passed** job fails if any other job failed
  or was cancelled, so a ruleset can require that single check. Today the
  `main` ruleset requires one approving review but no checks; adding **CI
  passed** as a required check is the next step once this workflow is on
  `main`. Until then, reviewers check that CI is green before approving.

## Drift detection (`drift.yml`)

For each of dev, staging and prod, it signs in with that environment's
read-only plan role and runs `terraform plan -detailed-exitcode` on
Solution A's workload. Exit code 2 means AWS has changed outside Terraform:
the job fails, and GitHub emails the repository's watchers.

| Setting | Value |
|---|---|
| Schedule | `0 18 * * *` (04:00 Brisbane), plus a manual **Run workflow** button |
| Concurrency | One run per environment at a time, so a manual run waits for the nightly one instead of racing it for the state lock |
| Permissions | `contents: read`, `id-token: write` (to sign in with OIDC) |
| Terraform | `1.16.2`, as in CI |

**No environment is enrolled yet**, so every run skips all three. An
environment is checked only once it stays deployed and has its plan role
stored as a repository variable. The demo and Solution B are never checked:
they're torn down between demos, so they'd always show as drift.

### Enrol an environment

1. Deploy it with GitHub deploys on (`enable_github_deploy = true`, the
   default outside the demo), following
   [deploy-solution-a.md](../../runbooks/deploy-solution-a.md).
2. In GitHub, go to **Settings > Secrets and variables > Actions >
   Variables** and add `SOLUTION_A_<ENV>_PLAN_ROLE_ARN` (`<ENV>` is `DEV`,
   `STAGING` or `PROD`), set to the workload's `github_plan_role_arn` output.
3. Run the workflow by hand once (**Actions > Drift detection > Run
   workflow**, on `main`). It should pass. A failure means someone changed AWS
   outside Terraform: re-apply, or put the change into code.

## Adding or changing a workflow

- Pin every new action to a full commit hash, with the release as a comment.
- Give the workflow only the permissions it needs, at the top of the file.
- A new root config or module must be added to the matrices in `ci.yml`
  (validate and Trivy for a root config; tests for a module), or it won't be
  checked.
