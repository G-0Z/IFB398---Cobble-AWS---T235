# Runbook: tear down and redeploy

**When:** after every demo or assessment (the PoC targets near-zero spend, so
it isn't left running), or to prove the deployment is repeatable.

Run this locally, not from CI: the deploy role would delete itself mid-run.
Sign in first as described in [deploy.md](deploy.md#sign-in).

## Tear down

```powershell
cd infrastructure/envs/poc
terraform plan -destroy -out destroy.tfplan
terraform apply destroy.tfplan
```

Everything is removed except:

- the state bucket (owned by `bootstrap/`, not this config)
- the KMS key, which AWS holds for 7 days before deleting

Teardown also deletes the CloudTrail trail and its log bucket, so the audit
record of the teardown itself goes with it. That's an accepted PoC trade-off;
the fix (a separate, long-lived account layer) is recorded in
[ADR 0001](../docs/02-landing-zone-design/adr/0001-deferred-landing-zone-design.md).

## Redeploy (repeatability check)

```powershell
terraform plan -out deploy.tfplan   # 43 to add, same as the first deploy
terraform apply deploy.tfplan
terraform plan -detailed-exitcode   # exit code 0 = no drift
```

Ideally a teammate who didn't write the config runs this, following only
these runbooks.
