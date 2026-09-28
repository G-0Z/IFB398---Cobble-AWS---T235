# CONTRIBUTING.md

## Branching

- `main` is the protected branch. Nobody pushes to it directly.
- Each person works on their own branch (`<name>-dev`).
- Open a PR into `main` when ready. At least one review required before merge.
- Note: GitHub Free tier means branch protection is *configured* by
  convention, not *enforced* by GitHub. See `adr/0001-branch-protection-gap.md`.
  Follow the convention anyway, it's the whole point.

## Infrastructure changes specifically

- Never run `terraform apply` against changes that haven't been through a
  PR, even though everyone currently has AWS console access. The repo is
  the source of truth, the console is not.
- CI runs `terraform fmt`/`validate`, `terraform test` (per-module, mock-based)
  and a tfsec security scan on every PR automatically. A red check means fix
  it before requesting review, not after.
- If your change adds a new AWS service or widens permissions, say so
  explicitly in the PR description, someone will need to update the IAM
  policy scoping too.

## Documentation changes

- If a decision changes something already written in `docs/`, update the
  doc in the same PR as the code change. Don't let them drift apart.
- Any decision with real tradeoffs (tool choice, scope cut, architecture
  change) gets an ADR in `adr/`, even a short one.

## Commit messages

Short, present tense, no strict format required. `Add S3 encryption to
platform bucket` is better than `fix stuff`.