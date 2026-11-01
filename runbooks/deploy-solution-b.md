# Runbook: deploy and tear down Solution B

Builds Solution B, the secure single-account platform (48 resources in about
5 minutes), then removes it again.

| | |
|---|---|
| **When** | Before a demo or assessment, or to test a change |
| **Cost** | Nearly nothing, as long as you [tear it down](#tear-down) afterwards |
| **Settings** | All in `infrastructure/solution-b/poc.auto.tfvars`, loaded automatically. Nothing to fill in. Change a setting by pull request |

## Before you start

- Terraform 1.10 or later, and the AWS CLI
- The state bucket exists. It already does in the team's account; otherwise see [bootstrap.md](bootstrap.md)
- Signed in to AWS (below)

## Sign in

Use single sign-on (IAM Identity Center):

```powershell
aws configure sso                       # once; name the profile cobble-poc
aws sso login --profile cobble-poc      # at the start of each session
$env:AWS_PROFILE = "cobble-poc"
aws sts get-caller-identity             # Account must be 669591255093
```

The older IAM users (with MFA) still work through `aws configure`, but
they're being retired.

## Deploy

```powershell
cd infrastructure/solution-b
terraform init
terraform plan -out deploy.tfplan   # read what it will do before going ahead
terraform apply deploy.tfplan       # 48 resources into an empty account
terraform plan -detailed-exitcode   # exit code 0 = what's running matches the code
```

> [!TIP]
> **To show a web page,** set `enable_demo_app = true` in `poc.auto.tfvars`
> and deploy. That adds a load balancer and one small web server (16 more
> resources), and `terraform output demo_app_url` gives the address. It costs
> about A$1.90 a day, so switch it off again after the demo.

## Tear down

Run this from your own computer, not from GitHub: GitHub's deploy role would
delete itself partway through.

```powershell
cd infrastructure/solution-b
terraform plan -destroy -out destroy.tfplan
terraform apply destroy.tfplan
```

Everything is removed except:

- the state bucket (it belongs to `bootstrap/`, not to Solution B)
- the encryption key, which AWS holds for 7 days before deleting it

Tearing down also deletes the audit trail and its logs, so there's no audit
record of the teardown itself. That's an accepted trade-off for a demo
platform. Solution A keeps its audit trail in a separate account, where it
survives.

## Redeploy: the repeatability check

```powershell
terraform plan -out deploy.tfplan   # should show 48 to add, the same as the first deploy
terraform apply deploy.tfplan
terraform plan -detailed-exitcode   # exit code 0
```

Ideally a teammate who didn't write the code runs this, following only this
runbook. Record the result in the
[evidence log](../docs/Evidence/README.md#evidence-log).

## If something goes wrong

| Error | Cause | Fix |
|---|---|---|
| `AWS account ID not allowed` | Signed in to the wrong account | Check `aws sts get-caller-identity` and switch profile |
| GuardDuty detector already exists | AWS allows one per account and region, and something else already turned it on (for example, Solution A's landing zone) | Set `enable_guardduty = false` in `poc.auto.tfvars` |
| OIDC provider already exists | AWS allows one GitHub sign-in provider per account | `terraform import module.github_deploy.aws_iam_openid_connect_provider.github <provider-arn>` |
| `terraform init` fails on the backend | The state bucket is missing or named differently | Run [bootstrap.md](bootstrap.md) and check `backend.tf` |
| `ExpiredToken` or single sign-on errors | Your sign-in session expired | `aws sso login --profile cobble-poc` |
