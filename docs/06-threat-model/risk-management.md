# Risk Management Plan

- **Status:** Final
- **Date:** 2026-10-19
- **Author:** Timothy Hartmann
- **Reviewed by:** T235

## 1. Purpose

This document defines how risks identified throughout the Cobbled AWS project will be recorded, assessed, treated and reviewed. It builds on the Threat Model and Risk Assessment by assigning ownership, mitigation actions and contingency responses to significant technical, security and project risks.

## 2. Risk Management Approach

Risks are identified through architecture reviews, threat modelling, prototype testing, project planning and discussions with the Industry Partner.

Each risk is recorded with:

- Likelihood
- Impact
- Overall risk rating
- Risk owner
- Mitigation actions
- Contingency actions
- Current status

Risks should be reviewed when the architecture changes, new AWS services are introduced, significant prototype issues are discovered, or before major Phase 2 deployment milestones.

## 3. 

Likelihood and impact use the same 1–5 scoring model defined in the Threat Model and Risk Assessment.

Risk score:

`Likelihood × Impact`

| Score | Rating |
|---:|---|
| 1–4 | Low |
| 5–9 | Medium |
| 10–16 | High |
| 17–25 | Critical |

## 4. Risk Register

| ID | Risk | Likelihood | Impact | Rating | Owner | Mitigation | Contingency | Status |
|---|---|---:|---:|---|---|---|---|---|
| R01 | Cross-tenant data exposure | 3 | 5 | High | Application / Security | Tenant validation, isolation controls, testing | Disable affected service and investigate access paths | Open |
| R02 | Privileged AWS account compromise | 3 | 5 | High | Platform Team | MFA, SSO, least privilege, short-lived roles | Revoke access, rotate credentials, review CloudTrail | Open |
| R03 | Unauthorised API access | 3 | 5 | High | Application / Platform | Authentication, WAF, request validation, rate limiting | Restrict endpoint, investigate logs and redeploy controls | Open |
| R04 | Terraform configuration causes incorrect infrastructure change | 3 | 4 | High | Platform Team | PR review, Terraform plan review, CI validation | Roll back configuration and redeploy last known-good state | Open |
| R05 | AWS costs exceed estimates | 3 | 3 | Medium | Project Team | Budgets, alerts, low-cost PoC design | Tear down non-essential resources and review sizing | Open |
| R06 | Prototype cannot be completed within Phase 1 | 3 | 4 | High | Project Team | Prioritise core functionality and track GitHub tasks | Reduce prototype scope and document deferred work for Phase 2 | Open |
| R07 | Loss of service or failed deployment | 3 | 4 | High | Platform Team | Environment separation, health checks, testing | Roll back to previous working deployment | Open |
| R08 | Backup or restore failure | 3 | 5 | High | Platform Team | Automated backups and restore testing | Rebuild from available state/data and escalate recovery gap | Open |
| R09 | Delayed access, credentials or Industry Partner input | 3 | 3 | Medium | Project Team | Raise dependencies early and use Discord/meetings | Re-sequence independent project work | Open |

## 5. Risk Ownership and Treatment

High and critical risks should have an identified owner and mitigation action before the affected component is considered production-ready.

Risk treatment may include:

- **Avoid** – change the design to remove the risk
- **Reduce** – implement controls that lower likelihood or impact
- **Transfer** – rely on an external service or responsible party where appropriate
- **Accept** – document and consciously accept residual risk where further treatment is not practical

Accepted risks should include a reason and, where appropriate, a trigger for future review.

## 6. Risk Review Process

The risk register should be reviewed:

- During major architecture changes
- Following prototype testing
- Before production deployment
- When new security issues are identified
- Following significant incidents or failed deployments
- At major Phase 2 milestones

Changes to high or critical risks should be documented in the repository.

## 7. Phase 2 Priorities

During Phase 2, the team should prioritise:

1. Validation of tenant isolation
2. Finalisation of privileged access controls
3. Testing of API protection
4. Backup and restore validation
5. Review of Terraform deployment controls
6. Validation of monitoring and incident-response capability
7. Reassessment of risks after the application is deployed

## 8. Relationship to Threat Model and Risk Assessment

The Threat Model and Risk Assessment identifies cloud security threats and evaluates their initial and residual risk.

This Risk Management Plan defines how those risks, together with broader technical and project risks, are owned, treated, monitored and reviewed throughout the project lifecycle.

The two documents should therefore be maintained together: the Threat Model provides the detailed security analysis, while this plan provides the ongoing process for managing the resulting risks.

## 9. Risk Escalation

Critical risks, or high risks that cannot be adequately mitigated by the project team, should be raised with the industry Partner and relevant project stakeholers.

Risks that meterially affect project scope, cost, security or delivery timeframes should be reviewed before the affected work continues. 