# ADR 0011: Trivy on every change; Checkov and a manual review as second opinions

- **Status:** Accepted
- **Date:** 2026-10-14
- **Deciders:** T235 (Max Gosling)

## Context

From 16 August 2026 (Week 4), every change was scanned by tfsec. Its maintainers
have since folded it into Trivy. Separately, a manual security review on 7
October found five problems no scanner reported
([scan findings](../deliverables/security-controls.md#found-by-manual-review-7-oct-2026)).

## Decision

- CI runs Trivy on every root config, on pull requests to `main` and pushes
  to `main` and `*-dev` branches, and fails on any finding ([`ci.yml`](../../.github/workflows/ci.yml)).
- A deliberate exception is a `#trivy:ignore` comment next to the code,
  giving the reason (older exceptions keep `#tfsec:ignore`, which Trivy
  honours), plus a row in the
  [scan findings register](../deliverables/security-controls.md#scan-findings-register).
- Checkov runs by hand as a second opinion, and a manual review goes with
  every large change.

## Consequences

- One maintained scanner, with every exception explained next to the code
  it applies to.
- Scanners only see configuration. Problems in what a permission *means*,
  such as a read-only role being able to read data, still need a person to
  find them.

**Revisit** if Trivy stops covering Terraform or the AWS provider.
