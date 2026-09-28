# ADR 0001: Branch protection gap on GitHub Free

## Status

Accepted

## Context

`main` is meant to be protected — nobody pushes directly, every change goes
through a PR with at least one review. GitHub's branch protection rules can
enforce this automatically, but several of the strictest options (required
reviewers on a private repo, required status checks before merge in all
configurations) are gated behind GitHub Team/Enterprise plans. This repo
runs on GitHub Free, under a student account.

## Decision

Treat "no one pushes to `main` directly, every change goes through a
reviewed PR" as a **team convention**, documented in `CONTRIBUTING.md`, not
something GitHub itself blocks. Whatever branch protection GitHub Free does
let us configure (e.g. requiring PRs, requiring CI to run) should still be
turned on — this ADR is about the gap that's left over, not an excuse to
skip the free parts.

## Consequences

- Direct pushes to `main` are *possible*, not *prevented*. A team member
  bypassing the convention (accidentally or otherwise) won't be blocked by
  GitHub.
- This makes the convention only as strong as the team's discipline. Code
  review in this project is a norm to uphold, not a guarantee the platform
  enforces.
- If the team ever moves to a paid GitHub tier (or a different host with
  stronger free-tier protections), revisit this and turn on full
  enforcement — it should be strictly better than the status quo, not a
  new decision to debate.
