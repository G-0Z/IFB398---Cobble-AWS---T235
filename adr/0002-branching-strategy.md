# ADR 0002: One long-lived branch per person

## Status

Accepted

## Context

Five people are working in the same repo, across documentation (`docs/`,
`adr/`), infrastructure code (`infrastructure/`) and eventually other
deliverables. We need a branching model simple enough that a small student
team won't fight the tooling, while still keeping `main` reviewable and
protecting it from half-finished work (see ADR 0001 for the limits of what
GitHub Free actually enforces here).

## Decision

Each team member works on their own long-lived branch, named `<name>-dev`
(e.g. `max-dev`, `Jacob-dev`, `Khai-dev`, `Nilansh-dev`, `Tim-dev`). Changes
land on `main` only via a PR from that branch, with at least one review.
There are no shared short-lived feature branches — if two people are
touching the same area, they coordinate directly rather than branching off
each other's `-dev` branch.

## Consequences

- Simple mental model: "my branch" always means the same thing, no picking
  a new branch name per task.
- A person's `-dev` branch can drift from `main` for a while between PRs;
  merge/rebase from `main` periodically rather than letting it drift too far,
  especially before starting infrastructure work that other PRs might also
  be touching (e.g. `infrastructure/` module wiring).
- This doesn't scale well past a handful of people or long project
  lifetimes — fine for a single-semester capstone team of five, not a
  pattern to carry into a larger or longer-running project without
  revisiting.
