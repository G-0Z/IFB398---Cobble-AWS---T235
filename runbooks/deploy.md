# Runbook: deploy the PoC

**When:** before a demo or assessment, or to test a change to
`infrastructure/`. The PoC targets near-zero spend, so it stays deployed only
while it's needed. Tear it down afterwards with [teardown.md](teardown.md).

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.10 and
  the [AWS CLI](https://aws.amazon.com/cli/)
- State bucket exists (see [bootstrap.md](bootstrap.md); already done for the
  PoC account)
- Signed in to AWS, see below

No tfvars file to create: inputs live in the committed
`infrastructure/envs/poc/poc.auto.tfvars`, which Terraform loads
automatically. Change values there, in a PR.

## Sign in

**Target (once the org has set up IAM Identity Center):**

```powershell
aws configure sso                       # once; name the profile cobble-poc
aws sso login --profile cobble-poc      # each session
$env:AWS_PROFILE = "cobble-poc"
```

**Until then (interim):** your IAM user, with MFA turned on, via
`aws configure`. These IAM users are deleted once SSO works.

Either way, confirm before deploying:

```powershell
aws sts get-caller-identity   # Account must be 669591255093
```

## Steps

```powershell
cd infrastructure/envs/poc
terraform init
terraform plan -out deploy.tfplan   # read it before applying
terraform apply deploy.tfplan
```

A first deploy into an empty account creates 43 resources.

**Demo app (optional):** to show the MVP serving a web page, set
`enable_demo_app = true` in `poc.auto.tfvars` (in a PR) and deploy. That adds
16 resources (a load balancer, one small container and their firewall
rules), and `terraform output demo_app_url` gives the address. It costs
roughly US$1.30 a day while on, so set it back to `false` or tear down after
the demo.

## Check

```powershell
terraform plan -detailed-exitcode   # exit code 0 = no drift
```

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `AWS account ID not allowed` | Signed in to the wrong account | Re-check `aws sts get-caller-identity`, switch profile |
| GuardDuty detector already exists | Only one per account/region, possibly enabled by the org | If the org manages GuardDuty, remove it from this config; otherwise `terraform import module.security_baseline.aws_guardduty_detector.this <detector-id>` |
| OIDC provider already exists | Only one GitHub provider per account | `terraform import module.oidc_deploy_role.aws_iam_openid_connect_provider.github <provider-arn>` |
| Backend init fails | State bucket missing or name mismatch | Run [bootstrap.md](bootstrap.md), check `backend.tf` |
| `ExpiredToken` / SSO errors | SSO session expired | `aws sso login --profile cobble-poc` |
