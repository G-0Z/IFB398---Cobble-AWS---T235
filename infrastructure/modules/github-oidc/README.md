# GitHub access (`github-oidc`)

**What it builds:** lets GitHub Actions work in one AWS account without any
stored passwords or keys. GitHub proves who it is with a short-lived token,
and AWS hands back temporary access to one of two roles.

**Used by:** both solutions: Solution B's account and each Solution A
environment.

## The two roles

| Role | Who can use it | What it can do |
|---|---|---|
| `<name>-terraform-plan` | Runs on pull requests and on `main` in this repository. Today only the nightly drift check would use it: CI doesn't sign in to AWS | Look at everything, read Terraform's records. It **can't** read the contents of buckets or logs, so a pull request can never reach tenant data |
| `<name>-terraform-apply` | Only a run on `main` in the named GitHub environment. Staging and prod are meant to require a reviewer there, but no GitHub environments or deploy workflow exist yet, so nothing uses this role today | Make changes in this one account. In Solution A, the organisation's guardrails still apply |

In Solution A the guardrails also stop the apply role creating or changing
the Config recorder or delivery channel, or deleting flow logs. Only
`OrganizationAccountAccessRole` can, so those parts are deployed with it
today.

It also creates the GitHub sign-in provider that lets AWS trust GitHub's
tokens. An account can only have one, which is why the Solution A demo
(sharing Solution B's account) switches this module off.

## Further reading

- [Configuring OpenID Connect in AWS (GitHub Docs)](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [IAM best practice: use temporary credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [GitHub environments with required reviewers](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment)

## Usage

How it's called in [`solution-a/workload/main.tf`](../../solution-a/workload/main.tf):

```hcl
module "github_deploy" {
  count  = var.enable_github_deploy ? 1 : 0
  source = "../../modules/github-oidc"

  name               = local.name
  github_org         = var.github_org
  github_repo        = var.github_repo
  github_environment = var.environment
  state_bucket_name  = var.state_bucket_name
  state_key          = local.state_key
}
```

## Reference

Generated from the module's code by [terraform-docs](https://terraform-docs.io/), so it's always
complete. Don't edit it by hand: run `terraform-docs -c ../.terraform-docs.yml .`
in this folder after changing a variable or output.

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.10 |
| aws | ~> 5.0 |
| tls | ~> 4.0 |

### Providers

| Name | Version |
| ---- | ------- |
| aws | ~> 5.0 |
| tls | ~> 4.0 |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| github\_environment | GitHub environment that must approve an apply, e.g. "dev" or "prod". Set required reviewers on it in the repo settings. | `string` | n/a | yes |
| github\_org | GitHub organisation or user that owns the repo. | `string` | n/a | yes |
| github\_repo | GitHub repository name. | `string` | n/a | yes |
| name | Prefix for the role names, e.g. "cobble-dev". Roles are called <name>-terraform-plan and <name>-terraform-apply. | `string` | n/a | yes |
| state\_bucket\_name | Terraform state bucket (created by infrastructure/bootstrap). | `string` | n/a | yes |
| state\_key | This environment's state file inside the bucket, e.g. "solution-a/workload/terraform.tfstate". | `string` | n/a | yes |

### Outputs

| Name | Description |
| ---- | ----------- |
| apply\_role\_arn | Role for approved applies. Put it in the workflow's role-to-assume for the GitHub environment. |
| plan\_role\_arn | Role for pull request plans. Put it in the workflow's role-to-assume for pull\_request runs. |
<!-- END_TF_DOCS -->
