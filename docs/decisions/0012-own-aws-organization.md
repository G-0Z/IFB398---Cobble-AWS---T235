# ADR 0012: Build Phase 1 in the team's own AWS organisation

- **Status:** Accepted
- **Date:** 2026-09-16 ([team meeting 4](../project/phase-1-meetings.md#week-9-team-meeting-4))
- **Deciders:** T235

## Context

The prototype needed a real AWS environment. AWS Educate only offers
training labs, and the Cyber Security Centre's accounts weren't available
for Phase 1.

## Decision

Max set up a personal AWS account with AWS Organizations, which became the
organisation's management account. Solution A's member accounts (security,
dev, staging, prod and shared services) are created inside it. Team members
sign in through IAM Identity Center.

## Consequences

- Real deployments, guardrails and organisation-wide services in Phase 1,
  not only designs.
- Every account ID and email is specific to this organisation, so they live
  in settings files kept off GitHub. The steps for deploying into another
  organisation are in the
  [runbooks](../../runbooks/README.md#deploying-into-a-different-aws-account).
- The Centre has to provide an account before Phase 2 can deploy into their
  environment: at G0, before Week 1. Milestone M1 then redeploys the
  platform there ([Phase 2 plan](../project/phase-2-plan.md#decision-points)).

**Revisit** at G0, when the Centre chooses Solution A or B and provides the
account.
