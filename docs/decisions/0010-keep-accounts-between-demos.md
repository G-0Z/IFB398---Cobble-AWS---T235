# ADR 0010: Keep the accounts between demos; tear down only what costs money

- **Status:** Accepted
- **Date:** 2026-10-18
- **Deciders:** T235 (Max Gosling)

## Context

The first real deployment of the landing zone, on 17 October 2026, ended by
destroying everything, including the member accounts. AWS counts closed
accounts against the organisation's account limit for 90 days, so the
organisation ran out of accounts it could create
([evidence log](../deliverables/evidence.md#evidence-log)).

## Decision

The free parts stay: the accounts, single sign-on and the guardrails. Only
what costs money is removed: the security services and the dev environment.
[`lz-dev.ps1`](../../infrastructure/solution-a/lz-dev.ps1) does each
direction in one command. Accounts have `prevent_destroy`, and `up`
refuses any step-2 plan that would delete something.

## Consequences

- Up in about 13 minutes, down in about 10. About A$0.35 an hour while up,
  and nothing after `down`.
- Re-running `up` while up reports zero changes, which is how drift is caught.
- Handing back delegated services leaves them switched on in each account,
  so `down` cleans every member account and, since 1 November 2026, the
  management account too.

**Revisit** when the platform moves into the Centre's own accounts.
