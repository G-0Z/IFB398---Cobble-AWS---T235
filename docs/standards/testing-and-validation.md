# Testing and validation

> **Standards:** [Overview](README.md) · [Directory structure](directory-structure.md) · [File layout](file-layout.md) · [Naming](naming.md) · [State](state.md) · [Modules](modules.md) · [Variables and outputs](variables-and-outputs.md) · [Version control](version-control.md) · [Documentation](documentation.md) · **Testing and validation**

Every change is checked in layers, from cheapest to most real:

| Layer | Catches | Runs | Needs AWS? |
|---|---|---|---|
| Format and validate | Syntax, typos, unformatted code | Locally and in CI | No |
| Module tests | A module building the wrong thing (a public database, a missing control) | Locally and in CI | No, mocked |
| Trivy | Known misconfigurations, any severity | Locally and in CI | No |
| Checkov and manual review | What Trivy misses; what a permission *means* | By hand, for large changes | No |
| Generated READMEs | Docs out of step with the code | Locally and in CI | No |
| Deploy, tear down, redeploy | Anything only AWS can tell you | By hand, with the runbooks | Yes |
| Drift check | Changes made outside Terraform | Nightly, once an environment is enrolled | Yes, read-only |

## Before you push

```powershell
# In infrastructure/: CI fails on unformatted code
terraform fmt -recursive

# In each root config you touched
terraform init -backend=false; terraform validate

# In each module you touched (mocked AWS, no sign-in needed)
terraform init -backend=false; terraform test

# In each module whose variables or outputs changed
terraform-docs -c ../.terraform-docs.yml .

# From the repo root, per root config: CI fails on any finding
trivy config --ignorefile .trivyignore.yaml infrastructure/<root-config>
```

CI runs the same checks on every pull request; what each job does, and how
to fix it, is in the [workflows README](../../.github/workflows/README.md).

## Module tests

- Every module has `tests/<name>.tftest.hcl`. `solution-a/workload` has one
  too, because its composition is where environments differ.
- Tests use `mock_provider`, so they need no credentials, cost nothing and
  never touch a real account. Most run `command = apply` against the mock
  (a few use `plan`) and assert the **shape** of what would be built.
- Test the controls, not the arithmetic: that the database isn't public,
  that a bucket blocks public access, that a role can't read data, that the
  defaults create nothing extra.
- **Every new `enable_<feature>` switch** gets a test proving that leaving it
  off creates nothing new ([Modules](modules.md#switching-features-on)).
- A bug that reached AWS gets a test that would have caught it.

## Scanner exceptions

Fix a finding if you can. If it's a deliberate trade-off:

1. Add an inline comment on the resource, with the reason:
   `#trivy:ignore:AWS-0089 -- access-log buckets can't log to themselves`.
   Older exceptions use `#tfsec:ignore`, which Trivy also honours.
2. Add a row to the
   [scan findings register](../deliverables/security-controls.md#scan-findings-register)
   with the decision.

`.trivyignore.yaml` is only for an exception that can't go inline; there
are none today.

## When a change is done

A change that deploys is done when:

1. It has been **deployed, torn down and redeployed** from code.
2. A final `terraform plan -detailed-exitcode` **exits 0**: nothing differs
   from the code.
3. The run is **recorded** in the [evidence log](../deliverables/evidence.md#evidence-log),
   with the log files saved.
4. CI is green and a teammate has approved the pull request.
5. The docs and runbooks that describe it are updated.

A change that doesn't deploy (docs, tests, a refactor with no plan diff)
needs only 4 and 5, plus a plan showing no changes where it could have
mattered.

## Drift

Re-running a deployment while it's up should report **0 changes**; anything
else is drift and gets fixed in code, never by clicking. The nightly
[drift workflow](../../.github/workflows/README.md#drift-detection-driftyml)
does this automatically for environments that stay deployed, once they're
enrolled.

---

[↑ Back to the top](#testing-and-validation) · ← [Documentation](documentation.md) · [Overview ↺](README.md)
