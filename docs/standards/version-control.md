# Version control

> **Standards:** [Overview](README.md) · [Directory structure](directory-structure.md) · [File layout](file-layout.md) · [Naming](naming.md) · [State](state.md) · [Modules](modules.md) · [Variables and outputs](variables-and-outputs.md) · **Version control** · [Documentation](documentation.md) · [Testing and validation](testing-and-validation.md)

## Workflow

1. **Start from an issue** on the [project board](https://github.com/users/G-0Z/projects/2),
   or create one from a template (task, bug or documentation request).
2. **Work on your personal branch,** `<Firstname>-dev` (for example
   `Khai-dev`), kept up to date with `main`.
3. **Open a pull request to `main`.** The
   [template](../../.github/pull_request_template.md) carries the definition
   of done. CI runs automatically ([workflows](../../.github/workflows/README.md)).
4. **Get one approving review.** A ruleset on `main` enforces it, blocks
   force-pushes and deletion, and dismisses an approval when new commits are
   pushed. It doesn't require the CI checks yet, so **the reviewer checks CI is
   green before approving.**
5. **Merge.** Nobody pushes to `main` directly.

## What a reviewer checks

- CI is green, including the **Module READMEs** job.
- The plan output is attached for anything that deploys, and it changes only
  what the pull request says it does.
- Nothing on the never-commit list below.
- No backend `key` changed.
- Docs, runbooks and the [control map](../../infrastructure/README.md#control-map)
  are updated if behaviour or commands changed.

## Never commit

| File | Why | Covered by `.gitignore` |
|---|---|---|
| A filled-in `settings.auto.tfvars` (Solution A) | Real account IDs and emails | Yes |
| `users.csv` | People's names and emails | Yes |
| `*.tfstate`, `*.tfstate.*` | Everything Terraform knows, including secrets | Yes |
| `*.tfplan`, `tfplan` | Saved plans can contain secret values | Yes |
| `.terraform/` | Downloaded providers and modules | Yes |
| A module's `.terraform.lock.hcl` | Never used by callers | Yes |
| Videos (`*.mp4`) | Too big for GitHub | Yes |
| Unredacted screenshots | Account IDs, organisation IDs, emails, ARNs | No: redact before committing |

Don't force-add an ignored file. If something sensitive is committed, tell
the team straight away: deleting it in a new commit doesn't remove it from
history.

## Do commit

- Each root config's `.terraform.lock.hcl`, so everyone and CI use the same
  provider versions.
- Solution B's `poc.auto.tfvars` and the workload's `<env>.tfvars`: they
  hold no secrets, and committing them keeps settings reviewable.
- The `.example` template for every git-ignored settings file.

## Commits and history

- One logical change per commit, with a message that says what changed and
  why in the first line.
- Change AWS through code, never in the console. A console change is drift;
  the next deployment run shows it, as will the nightly check once an
  environment is enrolled.
- A decision with lasting consequences gets a
  [decision record](../decisions/README.md); a release-worthy change gets a
  line in the [changelog](../../CHANGELOG.md).

## Dependencies

[Dependabot](../../.github/dependabot.yml) watches GitHub Actions and the
Terraform providers for security updates. Routine version bumps are off;
Terraform and providers are bumped deliberately, with the lock files and the
`1.16.2` pin in both workflows updated together.

---

[↑ Back to the top](#version-control) · ← [Variables and outputs](variables-and-outputs.md) · Next: [Documentation →](documentation.md)
