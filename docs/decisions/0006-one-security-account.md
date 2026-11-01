# ADR 0006: One Security account, not two

- **Status:** Accepted
- **Date:** 2026-10-06 (first recorded in [ADR 0003](0003-two-solutions-mvp-and-full-landing-zone.md#where-solution-a-departs-from-adr-0001))
- **Deciders:** T235

## Context

The AWS Security Reference Architecture puts audit logs in a Log Archive
account and security tools in a separate Security Tooling account.
[ADR 0001](0001-deferred-landing-zone-design.md) (D1) planned the same.
Each account adds fixed cost and one more thing to run.

## Decision

One Security account does both jobs. It holds the organisation's audit trail
in a bucket locked against deletion, and is the delegated administrator for
GuardDuty, Security Hub, Config and Access Analyzer. Built by
[`landing-zone/2-security/`](../../infrastructure/solution-a/landing-zone/2-security/).

## Consequences

- About half the fixed cost of the two-account layout.
- The same separation from the workloads: nobody working in dev, staging or
  prod can reach the logs or turn off detection.
- The people who run the security tools can also read the audit logs. That's
  acceptable for a team of four, but not for a separate audit function.

**Revisit** at production scale, or if an auditor asks for the split.
