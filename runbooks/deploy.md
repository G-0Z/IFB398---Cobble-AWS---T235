# Runbook: deploy Solution B

**What it does:** builds Solution B, the secure single-account platform: 48
resources in about 5 minutes.

**When:** before a demo or assessment, or to test a change. Solution B is
meant to cost nearly nothing, so tear it down afterwards with
[teardown.md](teardown.md).

## Before you start

- Terraform 1.10 or later, and the AWS CLI
- The state bucket exists. It already does in the team's account; otherwise see [bootstrap.md](bootstrap.md)
- Signed in to AWS (below)

There's nothing to fill in. Every setting is in
`infrastructure/solution-b/poc.auto.tfvars`, which Terraform loads
automatically. To change a setting, edit that file in a pull request.

## Sign in

Use single sign-on (IAM Identity Center):

```powershell
aws configure sso                       # once; name the profile cobble-poc
aws sso login --profile cobble-poc      # at the start of each session
$env:AWS_PROFILE = "cobble-poc"
```

The older IAM users (with MFA) still work through `aws configure`, but
they're being retired: use single sign-on where you can.

Either way, check you're in the right account before deploying:

```powershell
aws sts get-caller-identity   # Account must be 669591255093
```

## Deploy

```powershell
cd infrastructure/solution-b
terraform init
terraform plan -out deploy.tfplan   # read what it will do before going ahead
terraform apply deploy.tfplan
```

A first deploy into an empty account creates 48 resources.

### Optional: the demo web page

To show Solution B serving a web page, set `enable_demo_app = true` in
`poc.auto.tfvars` and deploy. That adds a load balancer and one small web
server (16 more resources), and `terraform output demo_app_url` gives the
address. It costs about US$1.30 a day while it's on, so switch it back off
or tear down after the demo.

## Check

```powershell
terraform plan -detailed-exitcode   # exit code 0 means what's running matches the code
```

## If something goes wrong

| Error | Cause | Fix |
|---|---|---|
| `AWS account ID not allowed` | Signed in to the wrong account | Check `aws sts get-caller-identity` and switch profile |
| GuardDuty detector already exists | AWS allows one per account and region, and something else already turned it on (for example, Solution A's landing zone) | Set `enable_guardduty = false` in `poc.auto.tfvars` |
| OIDC provider already exists | AWS allows one GitHub sign-in provider per account | `terraform import module.github_deploy.aws_iam_openid_connect_provider.github <provider-arn>` |
| `terraform init` fails on the backend | The state bucket is missing or named differently | Run [bootstrap.md](bootstrap.md) and check `backend.tf` |
| `ExpiredToken` or single sign-on errors | Your sign-in session expired | `aws sso login --profile cobble-poc` |
