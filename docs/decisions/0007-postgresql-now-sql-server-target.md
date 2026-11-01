# ADR 0007: PostgreSQL in the prototype; SQL Server as the target

- **Status:** Accepted, amended 2026-10-21 and in the Phase 1 report
- **Date:** Sprint 4 (28 September to 11 October 2026); amended at
  [team meeting 9](../project/phase-1-meetings.md#week-13-team-meeting-9)
- **Deciders:** T235

## Context

The Implementation Guide's database is RDS for SQL Server. Licensed SQL
Server costs far more per hour on the small sizes the prototype uses, and its
standby copy needs Standard or Enterprise edition. No Cobble database exists
yet to tie the design to an engine, and the Centre hasn't confirmed an edition.

## Decision

The prototype runs RDS PostgreSQL, built by
[`postgres-database`](../../infrastructure/modules/postgres-database/). Every
control the Guide asks for is built the same way it would be for SQL Server:
private subnets with no route out, encryption with the environment's key,
enforced encrypted connections, a managed password, backups and a standby copy.

On 21 October 2026 the team agreed that the report presents SQL Server as
Cobble's database. The Phase 1 report then made the swap stretch work: the
PostgreSQL module is replaced by a SQL Server one once the Centre chooses a
licence at G1 ([Phase 2 plan](../project/phase-2-plan.md#decision-points)).
It isn't one of the Phase 2 milestones.

## Consequences

- The demo costs a fraction of what SQL Server would.
- Moving to SQL Server replaces one building block; the network, keys,
  secrets and backups around it stay.
- The prototype's database proves the controls, not the engine.

**Revisit when** the Centre confirms the SQL Server edition.
