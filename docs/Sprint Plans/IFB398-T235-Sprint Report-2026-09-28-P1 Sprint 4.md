# IFB398-T235 Sprint Report

## Phase 1 Sprint 4: Terraform PoC, Solutions A and B

IFB398 Capstone · Team T235 · P608 Cobbled AWS Platform Configuration

Sprint 4 turned the design into working Terraform: a tested proof of concept, then Solution A and Solution B, compared in a written recommendation on 6 October.

| Item | Detail |
| --- | --- |
| Sprint | P1 S4 (2 weeks) |
| Dates | 28 September to 11 October 2026 (Weeks 10 to 11) |
| Sprint goal | Terraform PoC, Solutions A and B |
| Status | Completed |
| Team | Khai Do, Max Gosling, Jacob Hardcastle, Timothy Hartmann |
| Meetings | Team Meeting 6 (30 Sep, sprint planning); Team Meeting 7 (7 Oct, sprint review) |

### Tracker items

| Issue | Item | Owner | Status | Start to target |
| --- | --- | --- | --- | --- |
| #23 | Medium Fidelity / Framework | Jacob Hardcastle | Done | 6 to 8 Oct |

### Repository activity

| Date (2026) | Activity |
| --- | --- |
| 28 Sep | Landing zone proof of concept added in Terraform (deliverable 4), with test suites for five modules; repository folders aligned with the deliverables (PRs #15 to #19) |
| 28 Sep | tfsec findings fixed (VPC flow logs, S3 access logging, CloudTrail to CloudWatch); state locking moved to S3 native lock files |
| 6 Oct | Solution A (full landing zone) and Solution B (MVP) added; repository split into root configurations and modules, with runbooks (PR #21) |
| 6 Oct | tfsec run on each root configuration; deployment document refactored by Khai |
| 6 Oct | Solution A vs B comparison written, recommending Solution B now and Solution A as the target |
| 7 Oct | Security review findings closed; Solution A checked in CI; naming conventions guide added (PR #31) |

### Sprint review

- Solution B deployed and tested (43 resources); Solution A validated with 71 automated tests and 0 open tfsec findings.
- Medium fidelity framework completed (Jacob).
- Known gaps recorded: Solution B’s interim IAM users and shared admin group, and four Solution A items for Phase 2.
- Next sprint: deploy the landing zone, run a demo and build the presentation deck.

*Source: GitHub project "Team Planning" (Sprint field, items, start and target dates) and the IFB398---Cobble-AWS---T235 repository history, read on 24 October 2026.*
