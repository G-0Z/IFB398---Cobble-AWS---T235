# Terraform standards

> **Standards:** **Overview** · [Directory structure](directory-structure.md) · [File layout](file-layout.md) · [Naming](naming.md) · [State](state.md) · [Modules](modules.md) · [Variables and outputs](variables-and-outputs.md) · [Version control](version-control.md) · [Documentation](documentation.md) · [Testing and validation](testing-and-validation.md)

The rules every change to this repository follows. The
[engineering handbook](../handbook/README.md) explains how the platform
*is* built; these pages say how to *keep building it* the same way. Each
page is short, says what to do, and gives the reason.

## Why have standards

- **Consistency.** Every folder looks the same, so anyone can find their
  way around a part they didn't write.
- **Safety.** Some mistakes in Terraform are expensive to undo: a changed
  state key, a committed secret, a console change. The rules exist to stop
  those before they happen.
- **Reviewability.** A reviewer can check a pull request against a written
  rule instead of a personal preference.
- **Handover.** The Cyber Security Centre, or the next team, inherits the
  rules along with the code.

## Scope

This repository's Terraform on AWS: the two solutions, the nine modules,
the CI workflows, and the docs that describe them. The rules come from how
this codebase was actually built and the decisions recorded in
[`docs/decisions/`](../decisions/README.md). HashiCorp's
[style guide](https://developer.hashicorp.com/terraform/language/style) and
[standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
are the baseline.

## The standards

| Page | Covers |
|---|---|
| [Directory structure](directory-structure.md) | Where things go: root configs, modules, settings, docs |
| [File layout](file-layout.md) | The standard file names, and how a long `main.tf` is split |
| [Naming](naming.md) | Folders, Terraform labels, AWS resource names, tags, branches |
| [State](state.md) | The state bucket, fixed keys, locking, and guarding against the wrong account |
| [Modules](modules.md) | When to write a module, how to make one, and how features are switched on |
| [Variables and outputs](variables-and-outputs.md) | Descriptions, types, validation, defaults, secrets |
| [Version control](version-control.md) | Branches, pull requests, reviews, and what never gets committed |
| [Documentation](documentation.md) | READMEs, generated references, decision records, evidence |
| [Testing and validation](testing-and-validation.md) | Local checks, CI, scanners, drift, and when a change is done |

## The short version

- Folders and files are `kebab-case`, Terraform names `snake_case`, AWS
  names `cobble-<environment>-<thing>`. A name says what the thing is.
- **Never change a state key.** Never commit a filled-in settings file, a
  plan or a state file. Never change AWS in the console.
- New optional module features are `enable_<feature>` switches that default
  to off, so a change for Solution A never alters Solution B.
- Every variable and output has a description; every module has tests and
  a README whose reference section is generated.
- A change is done when it has been deployed, torn down and redeployed from
  code, and a final plan shows no differences.

## How they're enforced

| Enforced by | Rules |
|---|---|
| **CI** ([workflows](../../.github/workflows/README.md)) | Formatting, validation, module tests, Trivy findings, generated module READMEs |
| **The `main` ruleset** | Every change goes through a pull request with one approving review |
| **Review** | Everything else on these pages. The [pull request template](../../.github/pull_request_template.md) lists what a reviewer checks |

Changing a standard is a pull request like any other. A change with lasting
consequences also gets a [decision record](../decisions/README.md).

---

[↑ Back to the top](#terraform-standards) · Next: [Directory structure →](directory-structure.md)
