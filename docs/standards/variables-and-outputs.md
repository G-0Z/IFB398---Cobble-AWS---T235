# Variables and outputs

> **Standards:** [Overview](README.md) · [Directory structure](directory-structure.md) · [File layout](file-layout.md) · [Naming](naming.md) · [State](state.md) · [Modules](modules.md) · **Variables and outputs** · [Version control](version-control.md) · [Documentation](documentation.md) · [Testing and validation](testing-and-validation.md)

Names follow [Naming](naming.md#variables-and-outputs). These are the other
rules.

## Variables

**Every variable has a `description` and a `type`.** All 159 do. The
description is what appears in the module's generated reference, so write it
for someone choosing a value: what it does, the allowed values, and the
consequence of getting it wrong. For example (simplified from
`modules/network/variables.tf`):

```hcl
variable "nat_gateway_mode" {
  description = <<-EOT
    How private subnets reach the internet (outbound only):
      "none"       - no internet access at all (cheapest; Solution B)
      "single"     - one NAT gateway shared by every AZ (dev and staging)
      "one_per_az" - one NAT gateway per AZ (production)
  EOT
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "single", "one_per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be \"none\", \"single\" or \"one_per_az\"."
  }
}
```

**Validate what can be checked early.** Use a `validation` block for a fixed
set of options, a format (a 12-digit account ID, an email address), or a rule
between two variables (`max_count >= desired_count`). A bad value should fail
at `plan`, not halfway through an `apply`.

**Defaults:**

- **In a module,** default an optional input to the safe, cheap choice, so a
  caller that doesn't set it gets what Solution B needs. Required inputs have
  no default.
- **In a root config,** a default is the safe, common value, and each
  `*.tfvars` file sets only what differs: the workload defaults
  `read_only_root_filesystem = true` and `criticality = "Low"`, and
  `demo.tfvars` and `prod.tfvars` override them. A value with no safe default
  (an account ID, an IP range, the container image) has none, so a missing
  value fails at `plan` instead of silently taking the wrong one. Solution B
  keeps almost everything in `poc.auto.tfvars`, so there's one place to look.

**Values that come from another layer** (account IDs, the registry URL, the
Config bucket) are marked `REPLACE:` in the committed `.tfvars` and filled in
from that layer's outputs.

## Secrets

- **No secret is ever a Terraform variable or output.** The database password
  is created and rotated by RDS in Secrets Manager; containers get it as a
  Secrets Manager reference, never as a value. That's why nothing in the code
  is marked `sensitive`: nothing needs to be.
- If a secret ever has to pass through Terraform, mark it `sensitive = true`
  and remember it's still written to state in plain text.
- Account IDs and emails aren't secrets, but they are private: they live in
  git-ignored `settings.auto.tfvars` files, never in committed ones.

## Outputs

**Every output has a `description`.** All 61 do.

- Output what a caller or the next layer needs (IDs, ARNs, URLs), named by
  the same endings as variables.
- Don't output whole resources or secrets.
- A root config's outputs are what you copy into the next layer's settings,
  or what a runbook tells you to check; the runbooks name them.

---

[↑ Back to the top](#variables-and-outputs) · ← [Modules](modules.md) · Next: [Version control →](version-control.md)
