# Runbook: deploy the PoC

**When:** first deploy, or after any change to `infrastructure/`.

## Prerequisites

- State bucket exists (see [bootstrap.md](bootstrap.md))
- AWS CLI configured with your IAM user (`aws sts get-caller-identity` works)
- `terraform.tfvars` in `infrastructure/envs/poc/`, copied from
  `terraform.tfvars.example`

## Steps

```powershell
cd infrastructure/envs/poc
terraform init
terraform plan -out deploy.tfplan   # read it before applying
terraform apply deploy.tfplan
```

## Check

```powershell
terraform plan -detailed-exitcode   # exit code 0 = no drift
```

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| GuardDuty detector already exists | Only one per account/region | `terraform import module.security_baseline.aws_guardduty_detector.this <detector-id>` |
| OIDC provider already exists | Only one GitHub provider per account | `terraform import module.oidc_deploy_role.aws_iam_openid_connect_provider.github <provider-arn>` |
| Backend init fails | State bucket missing or name mismatch | Run [bootstrap.md](bootstrap.md), check `backend.tf` |
