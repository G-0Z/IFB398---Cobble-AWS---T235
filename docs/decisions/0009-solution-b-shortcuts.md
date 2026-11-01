# ADR 0009: Solution B accepts some shortcuts to stay near A$0

- **Status:** Accepted
- **Date:** 2026-10-06 (shortcuts first accepted in [ADR 0001](0001-deferred-landing-zone-design.md))
- **Deciders:** T235

## Context

Solution B, the minimum viable platform, has to be shown working at any
time for almost nothing. Several of the Guide's controls cost money every
hour they exist, whether or not anything runs.

## Decision

Solution B accepts these shortcuts. Solution A shows the full answer to each one.

| Solution B | Solution A |
|---|---|
| Everything in one account | Six accounts, so a mistake in dev can't reach prod |
| No NAT gateway (about A$62 a month), so the private network has no outbound internet | A NAT gateway, one per zone in prod |
| The audit trail is deleted on teardown | Audit logs in the Security account, locked against deletion |
| One encryption key for everything | A key per account |
| IAM users with MFA | Single sign-on through IAM Identity Center |

## Consequences

- Solution B deploys 48 resources in about 5 minutes and costs about A$0
  between demos.
- None of Solution B's controls is *enforced*, because enforcement needs an
  organisation's guardrails ([control map](../../infrastructure/README.md#control-map)).

**Revisit** if Solution B is ever left running long-term.
