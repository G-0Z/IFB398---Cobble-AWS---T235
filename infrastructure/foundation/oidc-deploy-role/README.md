## Purpose

Lets GitHub Actions deploy to AWS without any stored long-lived AWS keys
in the repo or in GitHub Secrets. Uses OIDC federation.

## Resources created

- `aws_iam_openid_connect_provider` (GitHub's OIDC provider — one per AWS
  account; if it already exists, `terraform import` it instead of applying)
- `aws_iam_role` (trust restricted to `github_org/github_repo`'s main branch
  + pull requests, via the `token.actions.githubusercontent.com:sub` claim)
- `aws_iam_role_policy` (scoped to the services this PoC touches)

## Inputs

| Name | Description | Default |
|---|---|---|
| `project_name` | Naming prefix | none, required |
| `github_org` | GitHub org/user that owns the repo | none, required (root config defaults to `G-0Z`) |
| `github_repo` | Repo name | none, required (root config defaults to `IFB398---Cobble-AWS---T235`) |

## Outputs

| Name | Description |
|---|---|
| `role_arn` | ARN GitHub Actions assumes to deploy |

## Notes

Permissions are scoped by *service*, not resource ARN. Tightening this
is a documented next step, not done yet.