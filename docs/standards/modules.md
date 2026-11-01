# Modules

> **Standards:** [Overview](README.md) · [Directory structure](directory-structure.md) · [File layout](file-layout.md) · [Naming](naming.md) · [State](state.md) · **Modules** · [Variables and outputs](variables-and-outputs.md) · [Version control](version-control.md) · [Documentation](documentation.md) · [Testing and validation](testing-and-validation.md)

The nine modules in [`infrastructure/modules/`](../../infrastructure/modules/README.md)
are the building blocks both solutions are made from
([ADR 0003](../decisions/0003-two-solutions-mvp-and-full-landing-zone.md)).

## When to write a module

Write one when at least one of these is true:

1. **A control must always be on.** If a resource needs security settings
   that nobody should be able to skip, put it in a module that sets them
   with no way to turn them off. `s3-bucket` always encrypts, versions and
   blocks public access.
2. **It's used in more than one place.** The same thing built twice by
   hand drifts; `s3-bucket` and `log-delivery` exist because the same bucket
   and log setup had been written out three times
   ([ADR 0002](../decisions/0002-codebase-structure-for-readability.md)).
3. **It hides real complexity behind a smaller interface.** `container-service`
   turns a cluster, service, load balancer, firewall rules, roles and
   scaling into a dozen settings.

Don't write one when:

- **It wraps a single resource and passes its arguments straight through.**
  That's a shallow module: one more hop for the reader, nothing gained. The
  old `budget` and `data` modules were deleted for this reason.
- **It would only ever be called from one place**, with nothing to enforce.
  Write the resources in the root config.

## How a module is built

- **Standard files:** `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`,
  `README.md` and `tests/` ([File layout](file-layout.md)).
- **No `provider` blocks and no backend.** The caller supplies the provider;
  a module only states the versions it needs in `versions.tf`
  (`required_version = ">= 1.10"`, `aws ~> 5.0`).
- **No lock file in Git.** A module's lock file is never used by the configs
  that call it.
- **Called by relative path**, such as `source = "../../modules/network"`.
  Everything lives in one repository, so there's nothing to version yet.
  Pinning modules to Git tags is deferred until there's a second consumer
  ([ADR 0001](../decisions/0001-deferred-landing-zone-design.md), D8).
- **Tested.** Every module has `tests/<name>.tftest.hcl`, run in CI against a
  mocked AWS ([Testing and validation](testing-and-validation.md)).
- **Documented.** Its README explains it in plain English and has a
  generated reference section ([Documentation](documentation.md)).

## Building blocks and composition

| Kind | What it is | Examples |
|---|---|---|
| **Building block** | One concern, with its controls built in | `s3-bucket`, `log-delivery`, `network`, `access-log-bucket` |
| **Composite** | Several building blocks and resources for one job | `container-service`, `security-baseline`, `postgres-database` |
| **Root config** | Composes modules into something you deploy | `solution-a/workload/main.tf`, `solution-b/main.tf` |

A root config's `main.tf` should read top to bottom as the inventory of what
gets deployed. Keep composition there, not in ever-larger composite modules.

## Switching features on

**New optional features are `enable_<feature>` switches that default to
off**, so adding something for Solution A never changes what Solution B
builds. Every new optional resource uses `count` or `for_each` on that switch,
and has a test proving the default creates nothing extra.

A few existing protections default to **on** and are switched off only where
they'd clash (`enable_guardduty`, `enable_management_guardduty`,
`enable_github_deploy`). Some optional features use a mode instead of a
boolean (`nat_gateway_mode = "none" | "single" | "one_per_az"`) or a plain
statement (`restrict_default_security_group`).

## Changing a module safely

- **Know who calls it.** `grep -r 'modules/<name>' infrastructure/` before
  changing an input or output.
- **Don't change what an existing caller builds** unless that's the point of
  the change. Run `terraform plan` for Solution B and each deployed
  environment; an unexpected diff is a bug.
- **Moving a resource inside a module** changes its address. Add a `moved`
  block so Terraform moves it instead of destroying and recreating it.
- **Regenerate the README** after changing an input or output; CI checks it.

---

[↑ Back to the top](#modules) · ← [State](state.md) · Next: [Variables and outputs →](variables-and-outputs.md)
