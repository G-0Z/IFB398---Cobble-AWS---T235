# How the team works

Team T235 runs two-week sprints, tracked on a GitHub project board. Each
sprint opens with planning at the weekly team meeting and closes with a
review at the next one. Client meetings with Wayne were agreed at least
fortnightly from Week 9, so the rest of the time goes into building and
writing. Two were held in Phase 1; holding to the agreed cadence is a
Phase 2 improvement.

## Roles

| Person | GitHub | Primary ownership |
|---|---|---|
| Max Gosling | [@G-0Z](https://github.com/G-0Z) | Project manager and build lead: Terraform, the demo, the sprint plan and the issues register |
| Khai Do | [@tdo212](https://github.com/tdo212) | Operations lead: deployment, monitoring, backup and the support model |
| Jacob Hardcastle | [@JacobHardcastle](https://github.com/JacobHardcastle) | Definition lead: the brief, requirements, scope and client meetings |
| Timothy Hartmann | [@TimHartmann98](https://github.com/TimHartmann98) | Design lead: landing zone, security controls and the risk register |
| Wayne (Cyber Security Centre) | | Client: priorities, feedback, and the decisions at G0 and G1 in Phase 2 |

In Scrum terms, Max is the Scrum master (he runs the sprints and the board),
Wayne acts as product owner for the Centre, and all four members are the
development team. Who decides what, and the risk register, are in
[governance, risks and ethics](governance-risks-ethics.md). Roles are
primary ownership, not silos. From Week 10, Max built the
Terraform and Jacob, Khai and Tim led the written deliverables
([team meeting 6](phase-1-meetings.md#week-10-team-meeting-6)).

## Cadence

Two-week Scrum sprints, each with a sprint goal, a sprint backlog on the
board, and a review at the end.

| Event | When | Where | Output |
|---|---|---|---|
| Sprint planning | First team meeting of each sprint | Discord | Sprint goal; items on the board with owners and dates |
| Team meeting | Weekly | Discord | Progress, blockers, re-plan; [minutes](phase-1-meetings.md) |
| Sprint review | Team meeting at the end of each sprint | Discord | The increment against the goal; recorded in the [sprint record](phase-1-sprints.md) |
| Retrospective | Covered in the sprint review in Phase 1; straight after it in Phase 2 | Discord | What the team changes next sprint; recorded in the sprint record |
| Client meeting | At least fortnightly, weekly only if needed | Zoom, with Wayne | Feedback and decisions, recorded in the [feedback register](design-iterations.md#feedback-register) |

## Board

The GitHub project **Team Planning** holds every piece of work:

- Each of the eight deliverables is an issue (#6 to #13), split into
  sub-issues.
- Every item has a sprint, start and target dates, an owner, a P0 to P2
  priority and a status (Todo, In progress or Done).
- Phase 2 items carry the `phase 2` label. The plan has two client decision
  points, G0 and G1 ([Phase 2 plan](phase-2-plan.md#decision-points)).

New issues use a template: a **task** (with a "done when") or a **bug**
(what happened, and how to reproduce it).

## Definition of done

A change to the infrastructure is done when:

- it has been deployed, torn down and redeployed from code
- a final `terraform plan -detailed-exitcode` exits 0
- the run is recorded in the [evidence log](../deliverables/evidence.md#evidence-log)
- CI is green: format, validate, module tests and the Trivy scan
- one teammate has reviewed and approved the pull request
- the docs and runbooks that describe it are updated

The pull request template carries this checklist.

## Source control

- `main` always works. Each member works on a personal branch,
  `<Firstname>-dev`, and opens a pull request to `main`.
- One approving review is needed to merge, enforced by a GitHub ruleset on
  `main` (the repository moved to GitHub Pro for this). The ruleset doesn't
  require the CI checks, so reviewers check that CI is green before
  approving.
- AWS is changed through code only. A console change is drift, and the
  nightly check flags it.
- Decisions with lasting consequences get a
  [decision record](../decisions/README.md).
- Commands and the rules CI can't check are in
  [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Communication

| Channel | Use |
|---|---|
| Discord | Weekly team meetings (voice) and day-to-day questions |
| GitHub issues, project board and pull requests | Anything that needs tracking, review or a decision |
| Zoom | Client meetings with Wayne: feedback, decisions and sign-off |
