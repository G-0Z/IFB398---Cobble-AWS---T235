# File layout

> **Standards:** [Overview](README.md) · [Directory structure](directory-structure.md) · **File layout** · [Naming](naming.md) · [State](state.md) · [Modules](modules.md) · [Variables and outputs](variables-and-outputs.md) · [Version control](version-control.md) · [Documentation](documentation.md) · [Testing and validation](testing-and-validation.md)

Every Terraform folder uses the same file names
([HashiCorp's standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)),
so you always know where to look.

## Standard files

| File | Holds | In |
|---|---|---|
| `main.tf` | The resources and module calls. Start reading here | Every folder |
| `variables.tf` | Inputs (`variable` blocks) | Every folder |
| `outputs.tf` | Values handed to whoever calls this (`output` blocks) | Every folder |
| `versions.tf` | Required Terraform and provider versions | Every folder |
| `providers.tf` | Provider settings: region, allowed account, assumed role, default tags | Root configs only |
| `backend.tf` | Where state is stored | Root configs only |
| `README.md` | What the folder builds and why | Every folder |
| `tests/<name>.tftest.hcl` | Automated tests, run with `terraform test` | Modules, and `solution-a/workload` |

## Splitting a long `main.tf`

When `main.tf` gets long, split it **by concern**, and name the file after
the AWS service or idea it contains. `main.tf` then reads as a table of
contents.

| File | Contains | Example location |
|---|---|---|
| `kms.tf` | Encryption keys and their policies | `security-baseline/`, `solution-a/workload/` |
| `cloudtrail.tf` | Audit logging | `security-baseline/`, `landing-zone/2-security/` |
| `guardduty.tf`, `detection.tf` | Threat detection and posture checks | `security-baseline/`, `landing-zone/2-security/` |
| `iam.tf` | Roles and policies | `container-service/` |
| `security-groups.tf` | Firewall rules between components | `container-service/` |
| `load-balancer.tf`, `ecs.tf`, `waf.tf` | One AWS service each | `container-service/` |
| `nat.tf`, `endpoints.tf`, `flow-logs.tf`, `database-subnets.tf` | Optional network features | `network/` |
| `accounts.tf`, `organization.tf`, `guardrails.tf`, `identity-center.tf` | Organisation setup | `landing-zone/1-organization/` |
| `alerts.tf`, `log-archive.tf` | Alerting and locked audit-log storage | `landing-zone/2-security/` |

Rule of thumb: one AWS service, or one optional feature, per file. Don't
split by resource type (`buckets.tf`, `roles.tf`) across unrelated purposes.

## Other files

| Pattern | Meaning |
|---|---|
| `*.auto.tfvars` | The values for a root config. Terraform loads these automatically. **Edit this to change a setting** |
| `<env>.tfvars` | One environment's values for `solution-a/workload/`, passed with `-var-file` |
| `*.example` | A template to copy and fill in, such as `settings.auto.tfvars.example`. The filled-in copy holds account IDs and emails, so it's git-ignored |
| `policies/*.json` | A service control policy as plain JSON |
| `policies/*.json.tftpl` | A policy with placeholders Terraform fills in, such as the allowed regions |
| `.terraform.lock.hcl` | Pinned provider versions. Generated; don't edit it. Committed in every root config, git-ignored in modules |

## Inside a file

- Run `terraform fmt`; CI fails on unformatted code.
- Order inside a block: `count` or `for_each` first, then arguments, then
  nested blocks, then `tags`, then `lifecycle` and `depends_on` last.
- A comment says **why**, not what: the reason for an exception, a Guide
  section, or a trade-off. Every deliberate scanner exception has one (see
  [Testing and validation](testing-and-validation.md#scanner-exceptions)).

---

[↑ Back to the top](#file-layout) · ← [Directory structure](directory-structure.md) · Next: [Naming →](naming.md)
