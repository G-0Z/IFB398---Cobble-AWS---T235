## Purpose

Lets GitHub Actions deploy to AWS without any stored long-lived AWS keys
in the repo or in GitHub Secrets. Uses OIDC federation.

## Resources created

- `aws_iam_openid_connect_provider` (GitHub's OIDC provider)
- `aws_iam_role` (trust restricted to this repo's main branch + PRs)
- `aws_iam_role_policy` (scoped to the services this PoC touches)

## Inputs

| Name | Description | Default |
|---|---|---|
| `project_name` | Naming prefix | none, required |
| `github_org` | GitHub org that owns the repo | `Cyber-Safety-Centre` |
| `github_repo` | Repo name | `2701-T235-AWS-Platform` |

## Outputs

| Name | Description |
|---|---|
| `role_arn` | ARN GitHub Actions assumes to deploy |

## Notes

Permissions are scoped by *service*, not resource ARN. Tightening this
is a documented next step, not done yet.