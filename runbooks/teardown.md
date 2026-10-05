# Runbook: tear down and redeploy

**When:** cleaning up the shared account, or proving the deployment is
repeatable.

Run this locally, not from CI: the deploy role would delete itself mid-run.

## Tear down

```powershell
cd infrastructure/envs/poc
terraform plan -destroy -out destroy.tfplan
terraform apply destroy.tfplan
```

Everything is removed except:

- the state bucket (owned by `bootstrap/`, not this config)
- the KMS key, which AWS holds for 7 days before deleting

## Redeploy (repeatability check)

```powershell
terraform plan -out deploy.tfplan   # same resource count as the first deploy
terraform apply deploy.tfplan
terraform plan -detailed-exitcode   # exit code 0 = no drift
```
