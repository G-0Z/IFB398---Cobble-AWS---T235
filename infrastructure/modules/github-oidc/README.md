# `github-oidc` module

**In one sentence:** lets GitHub Actions deploy one AWS account with no
stored keys: a read-only role for pull requests and an apply role that only
an approved deployment can use.

**Used by:** Solution A (each workload environment). Solution B keeps its
single role in `oidc-deploy-role`, unchanged.

## What it creates

| Resource | Who can use it | What it can do |
|---|---|---|
| GitHub OIDC provider | - | Lets AWS trust GitHub's short-lived tokens |
| `<name>-terraform-plan` role | Pull requests in the repo | Read everything (AWS `ReadOnlyAccess`), read state, take the state lock |
| `<name>-terraform-apply` role | Runs in the GitHub environment (with required reviewers) | Administer this one account; still bound by organisation SCPs |

## Inputs

| Name | Meaning |
|---|---|
| `name` | Prefix for role names |
| `github_org`, `github_repo` | The repo allowed to deploy |
| `github_environment` | GitHub environment whose approval unlocks apply |
| `state_bucket_name`, `state_key` | Where this environment's state lives |

## Outputs

`plan_role_arn`, `apply_role_arn`

## Best practice

- [Configuring OpenID Connect in AWS (GitHub Docs)](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [IAM best practice: use temporary credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [GitHub environments with required reviewers](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment)
