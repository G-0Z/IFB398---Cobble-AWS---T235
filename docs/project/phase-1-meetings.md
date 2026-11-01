# Phase 1 meetings (IFB398, Semester 2 2026)

Every team meeting and client meeting in Phase 1, grouped by sprint to match
the [sprint record](phase-1-sprints.md).

| Meeting | Where | How often |
|---|---|---|
| Team meeting | Discord | Weekly, on Wednesdays: the first in a sprint plans it, the second reviews it |
| Client meeting with Wayne (Cyber Security Centre) | Zoom | At least fortnightly once agreed in Week 9, weekly only if needed |

All four members (Khai Do, Max Gosling, Jacob Hardcastle, Timothy Hartmann)
attended every meeting. Each meeting below lists its actions, with an owner
where the minutes name one ("Team" where they don't), and the next meeting.

| Sprint | QUT week | Meeting | Key outcome |
|---|---|---|---|
| 1 | 6 | [Team meeting 1](#week-6-team-meeting-1): review | Repository and CI in place. GitHub Free can't enforce branch protection on a private repository |
| 1 | 6 | [Client meeting 1](#week-6-client-meeting-1) | Raised scope, the AWS account and budget, NDA and IP paperwork, and repository visibility |
| 2 | 7 | [Team meeting 2](#week-7-team-meeting-2): planning | ECS vs EKS, pricing and the diagram planned |
| 2 | 8 | [Team meeting 3](#week-8-team-meeting-3): review | Comparisons and diagram ready for Wayne |
| 3 | 9 | [Client meeting 2](#week-9-client-meeting-2) | **Wayne's requests:** implementable recommendations, issues and solutions written down, 1 and 3 month options, a two-semester schedule, a web firewall |
| 3 | 9 | [Team meeting 4](#week-9-team-meeting-4): planning | Deliverables added as issues #6 to #13. Own AWS account. Work split into Solutions A and B |
| 3 | Break | [Team meeting 5](#mid-semester-break-team-meeting-5): review | Cost and technology selection report drafted |
| 4 | 10 | [Team meeting 6](#week-10-team-meeting-6): planning | Max builds the Terraform; Jacob, Khai and Tim lead the written deliverables |
| 4 | 11 | [Team meeting 7](#week-11-team-meeting-7): review | Solutions A and B added; comparison written; security review findings closed |
| 5 | 12 | [Team meeting 8](#week-12-team-meeting-8): planning | Repository restructured. Sprint 5 owners set |
| 5 | 13 | [Team meeting 9](#week-13-team-meeting-9): review | Landing zone deployed and recorded. SQL Server chosen as the database the report presents |
| 6 | | No meetings recorded yet | |

---

## Sprint 1 (Weeks 5–6)

### Week 6: team meeting 1

Wednesday · sprint review.

* The repository is set up, with a folder structure for the deliverables and
  a README. CI runs `terraform validate` and tfsec on `main` and each
  member's dev branch. The pull request workflow and branch ruleset were
  tested in Week 5.
* **Issue:** GitHub Free doesn't enforce branch protection on private
  repositories. The options are a public repository (which needs the
  Centre's approval under the NDA), a paid plan, or a documented team
  convention.
* Prepared for the client meeting the next day: scope, the AWS account and
  budget, the NDA and IP paperwork, and repository visibility.

**Actions**

| Action | Owner | Due | Outcome |
|---|---|---|---|
| Raise scope, the AWS account and budget, the NDA and IP paperwork, and repository visibility with Wayne | Team | Client meeting 1 | Raised |
| Choose how to handle branch protection | Team | Sprint 2 | A team rule that every change needs a review; later enforced by a ruleset after the move to GitHub Pro |
| Research AWS services and pricing (Sprint 2) | Team | Team meeting 3 | Done |

**Next meeting:** client meeting 1, the next day (Week 6, Zoom).

### Week 6: client meeting 1

Thursday, Zoom · Wayne and all four members · first meeting with the
industry partner.

* **Raised:** project scope and deliverables; an AWS account and budget;
  the NDA and IP assignment paperwork; repository visibility, given the NDA
  and IP terms.
* **Outcomes:** not written up. The actions went onto the backlog at team
  meeting 2, and the next client meeting was set for Week 9.

**Actions**

| Action | Owner | Due | Outcome |
|---|---|---|---|
| Add the meeting's actions to the backlog | Team | Team meeting 2 | Done |
| Book the next client meeting | Team | Team meeting 2 | Set for Week 9 |

**Next meeting:** team meeting 2 (Week 7, Discord). Next client meeting: Week 9.

---

## Sprint 2 (Weeks 7–8)

### Week 7: team meeting 2

Wednesday · sprint planning.

* Actions from client meeting 1 added to the backlog.
* **Planned:** compare Amazon ECS and EKS for hosting Cobble's containers,
  compare pricing across the candidate AWS services, and update the
  architecture diagram for client review.
* Next client meeting set for Week 9.

**Actions**

| Action | Owner | Due | Outcome |
|---|---|---|---|
| Compare Amazon ECS and EKS for hosting Cobble's containers | Team | Team meeting 3 | Done; ECS on Fargate chosen ([ADR 0005](../decisions/0005-ecs-fargate-not-eks.md)) |
| Compare pricing across the candidate AWS services | Team | Team meeting 3 | Done |
| Update the architecture diagram for client review | Team | Team meeting 3 | Done |

**Next meeting:** team meeting 3 (Week 8, Discord).

### Week 8: team meeting 3

Wednesday · sprint review.

* The ECS vs EKS comparison, the pricing comparison and the updated
  architecture diagram are ready.
* **Agreed:** present all three to Wayne in Week 9.

**Actions**

| Action | Owner | Due | Outcome |
|---|---|---|---|
| Present the ECS vs EKS comparison, pricing and diagram to Wayne | Team | Client meeting 2 | Presented |
| Sprint 3: follow up the client meeting, secure an AWS account, scope the deliverables | Team | Team meeting 5 | Done |

**Next meeting:** client meeting 2 (Week 9, Monday, Zoom), then team meeting 4 (Week 9, Discord).

---

## Sprint 3 (Week 9 and the mid-semester break)

### Week 9: client meeting 2

Monday, Zoom · Wayne and all four members · design review.

* **Discussed:** Cobble's development environment stays on DigitalOcean
  until it's ready to move to AWS, and the app can load from GitHub. Once
  in production, each client pays for its own storage. Wayne reviewed the
  ECS vs EKS and pricing comparisons; the architecture diagram had no web
  firewall.
* **Wayne asked for:** recommendations that can actually be implemented;
  issues and their solutions written down; 1 month and 3 month options; a
  schedule covering this semester and next.
* **Agreed:** client meetings at least fortnightly, weekly only if needed.
* **Follow-up:** every request was answered in the Solution A vs B
  comparison (Week 11). The
  [feedback register](design-iterations.md#feedback-register) tracks each
  one to where it can be seen today.

**Actions**

| Action | Owner | Due | Outcome |
|---|---|---|---|
| Turn Wayne's requests into tracked sub-issues | Max | Team meeting 4 | Done |
| Make the recommendations implementable | Team | Week 11 | Solution B deployed and tested; Solution A written and tested as Terraform |
| Write down the issues and their solutions | Team | Week 11 | Known gaps and scanner findings recorded with planned fixes |
| Set out 1 month and 3 month options | Max | Week 11 | In the Solution A vs B comparison |
| Produce a schedule covering this semester and next | Max | Week 11 | Phase 1 and Phase 2 plans |
| Add a web firewall to the architecture | Max | Week 11 | WAF added to staging and prod ([ADR 0008](../decisions/0008-load-balancer-and-waf.md)) |

**Next meeting:** team meeting 4 (Week 9, Wednesday, Discord). Next client meeting: at least fortnightly, as agreed. No further client meeting is recorded in Phase 1; meeting Wayne on the agreed schedule is an improvement the team has set for Phase 2.

### Week 9: team meeting 4

Wednesday · sprint planning.

* Debrief of client meeting 2.
* Deliverables 1 to 8 added to the tracker as issues #6 to #13; the intro
  to tutor document updated and closed (#5).
* **Decided:** AWS Educate only offers training labs, so Max sets up a
  personal AWS account with AWS Organizations for the proof of concept
  ([ADR 0012](../decisions/0012-own-aws-organization.md)).
* **Decided:** the unit requires two solutions, so the work is split into
  Solution A (full landing zone) and Solution B (minimum viable product).

**Actions**

| Action | Owner | Due | Outcome |
|---|---|---|---|
| Set up a personal AWS account with AWS Organizations for the proof of concept | Max | Team meeting 5 | Done |
| Give each deliverable issue an owner | Team | Team meeting 5 | Done |
| Draft the cost and technology selection report | Team | Team meeting 5 | Drafted |

**Next meeting:** team meeting 5 (mid-semester break, Discord).

### Mid-semester break: team meeting 5

Wednesday · sprint review.

* Deliverables tracked as issues with owners; the AWS account is ready for
  the proof of concept.
* Cost and technology selection report drafted, as a companion to the
  Engineering Implementation Guide v1.0.

**Actions**

| Action | Owner | Due | Outcome |
|---|---|---|---|
| Sprint 4: build the Terraform proof of concept and Solutions A and B | Team (split at team meeting 6) | Team meeting 7 | Done |

**Next meeting:** team meeting 6 (Week 10, Discord).

---

## Sprint 4 (Weeks 10–11)

### Week 10: team meeting 6

Wednesday · sprint planning.

* The proof of concept started at the start of the week: landing zone Terraform with
  tests for five modules, tfsec findings fixed, folders aligned with the
  deliverables.
* **Work split:** Max builds the Terraform. Jacob, Khai and Tim lead the
  written deliverables; Jacob takes the medium fidelity framework.
* **Planned:** add Solution A and Solution B, and write the comparison with
  costs and 1 month and 3 month options.

**Actions**

| Action | Owner | Due | Outcome |
|---|---|---|---|
| Build the Terraform proof of concept; add Solutions A and B | Max | Team meeting 7 | Done |
| Write the Solution A vs B comparison, with costs and 1 and 3 month options | Max | Team meeting 7 | Done, the day before the meeting |
| Medium fidelity framework | Jacob | Team meeting 7 | Done |
| Lead the written deliverables | Jacob, Khai, Tim | Ongoing | Under way |

**Next meeting:** team meeting 7 (Week 11, Discord).

### Week 11: team meeting 7

Wednesday · sprint review.

* Solution B deployed and tested (43 resources); Solution A validated with
  71 automated tests and 0 open tfsec findings.
* The Solution A vs B comparison was completed the day before, recommending
  Solution B now and Solution A as the target. Security review findings
  were closed the same day.
* Medium fidelity framework completed (Jacob); deployment document
  refactored (Khai).

**Actions**

| Action | Owner | Due | Outcome |
|---|---|---|---|
| Sprint 5: deploy the landing zone, run a demo and build the deck | Team (owners set at team meeting 8) | Team meeting 9 | Done |

**Next meeting:** team meeting 8 (Week 12, Discord).

---

## Sprint 5 (Weeks 12–13)

### Week 12: team meeting 8

Wednesday · sprint planning.

* The repository was restructured so both solutions deploy and redeploy
  cleanly ([ADR 0004](../decisions/0004-one-workload-per-environment.md));
  prices are now in AUD.
* Reviewed the Assessment 3 instructions: Part 1 is 8 to 10 pages written
  as a team; Part 2 is 1 to 2 pages per member.

**Actions**

| Action | Owner | Due | Outcome |
|---|---|---|---|
| Deploy the landing zone and run a demo | Max | Team meeting 9 | Done |
| SOCI clean-up of the proof of concept | Max | Team meeting 9 | Done |
| High fidelity framework | Jacob | Team meeting 9 | Done |
| Risk management documentation | Tim | Team meeting 9 | Done |
| Final stakeholder presentation | All four | Team meeting 9 | Deck built and cut to 14 minutes; still in progress |

**Next meeting:** team meeting 9 (Week 13, Discord).

### Week 13: team meeting 9

Wednesday · sprint review.

* The landing zone was deployed in a dev demo in Week 12, with fixes,
  evidence and a runbook. The second full run is saved as the Solution A
  demo ([evidence](../deliverables/evidence.md)).
* The deck was built in Week 12 and cut to 14 minutes with a script; the
  final presentation stays in progress.
* **Completed:** SOCI clean-up (Max), high fidelity framework (Jacob),
  threat model and risk management documentation (Tim).
* A first draft of the Phase 2 plan added to the tracker (P2.0 to P2.9),
  since replaced by the milestone plan in the [Phase 2 plan](phase-2-plan.md).
* **Decided:** the report presents SQL Server as Cobble's database, with the
  prototype's PostgreSQL swapped later; it's now stretch work once the
  Centre chooses a licence ([ADR 0007](../decisions/0007-postgresql-now-sql-server-target.md)).

**Actions**

| Action | Owner | Due | Outcome |
|---|---|---|---|
| Finalise the deliverables | Team | Sprint 6 | Five deliverable items closed early |
| Finish the final stakeholder presentation (#13) | All four | Sprint 6 | Open |
| Merge Jacob's open pull request (#53) | Team | Sprint 6 | Open |
| Write the Phase 1 report | Team | Sprint 6 | In progress |

**Next meeting:** none recorded yet in Sprint 6.

---

## Sprint 6 (study and exam period)

No meetings recorded yet.
