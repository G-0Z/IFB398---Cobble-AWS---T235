# Runbook: tear down and redeploy Solution B

**What it does:** removes Solution B, and optionally rebuilds it to prove
the deployment is repeatable.

**When:** after every demo or assessment (Solution B isn't left running), or
whenever you want to show it redeploys identically.

Run this from your own computer, not from GitHub: GitHub's deploy role would
delete itself partway through. Sign in first as in
[deploy.md](deploy.md#sign-in).

## Tear down

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
terraform plan -detailed-exitcode   # exit code 0 means what's running matches the code
```

Ideally a teammate who didn't write the code runs this, following only these
runbooks. Record the result in the
[evidence log](../docs/04-iac-evidence/README.md#evidence-log).
