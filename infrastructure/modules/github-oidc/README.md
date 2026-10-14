# GitHub access (`github-oidc`)

**What it builds:** lets GitHub Actions work in one AWS account without any
stored passwords or keys. GitHub proves who it is with a short-lived token,
and AWS hands back temporary access to one of two roles.

**Used by:** both solutions: Solution B's account and each Solution A
environment.

## The two roles

| Role | Who can use it | What it can do |
|---|---|---|
| `<name>-terraform-plan` | Pull requests in this repository, and the nightly drift check on `main` | Look at everything, read Terraform's records. It **can't** read the contents of buckets or logs, so a pull request can never reach tenant data |
| `<name>-terraform-apply` | Only a run of the approved GitHub environment (which needs a reviewer to click approve) | Make changes in this one account. In Solution A, the organisation's guardrails still apply |

It also creates the GitHub sign-in provider that lets AWS trust GitHub's
tokens. An account can only have one, which is why the Solution A demo
(sharing Solution B's account) switches this module off.

## Settings

| Setting | Meaning |
|---|---|
| `name` | Prefix for the role names |
| `github_org`, `github_repo` | The only repository allowed to sign in |
| `github_environment` | The GitHub environment whose approval unlocks the deploy role |
| `state_bucket_name`, `state_key` | Where this deployment's Terraform records live. The roles can only touch that file |

**Outputs:** `plan_role_arn`, `apply_role_arn`

## Further reading

- [Configuring OpenID Connect in AWS (GitHub Docs)](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [IAM best practice: use temporary credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [GitHub environments with required reviewers](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment)
