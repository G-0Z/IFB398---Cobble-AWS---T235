# Governance, risks and ethics

Who decides what, how the project's risks are tracked, and the ethical
lines the team works within. The security threats to the platform itself
are analysed in [deliverable 6](../deliverables/threat-model.md); this page
holds the project's **live risk register**, which covers both those risks
and the risks to delivering the project.

## Governance

### Who decides

| Decision | Who | Recorded in |
|---|---|---|
| Scope, priorities, acceptance of the handover | The Cyber Security Centre (Wayne, acting product owner) | [Meetings](phase-1-meetings.md), [feedback register](design-iterations.md#feedback-register) |
| Solution A or B, the AWS account and budget (G0); database licence, recovery targets, backup location, domain and applicable laws (G1) | The Centre, at the Phase 2 decision points | [Phase 2 plan](phase-2-plan.md#decision-points) |
| The A$100 a month funding ceiling for Phase 2 | The Centre, during Sprint 2 | [Phase 2 plan](phase-2-plan.md#funding) |
| Technical design within the agreed scope | The team; lasting decisions get a decision record | [Decision records](../decisions/README.md) |
| Sprint goals, the board, who does what | The team; Max runs the sprints | [How we work](way-of-working.md), [sprint record](phase-1-sprints.md) |
| Whether a change merges | One teammate's approving review | The pull request |
| Assessment | The QUT teaching team | |

### Change control

- **Every change goes through a pull request** with one approving review,
  enforced by a ruleset on `main`, and CI on every pull request
  ([version control](../standards/version-control.md)).
- **AWS changes only through code.** A console change is drift, and the next
  deployment run shows it.
- **A change is done** only when it has been deployed, torn down and
  redeployed from code, with the run recorded as evidence
  ([testing and validation](../standards/testing-and-validation.md#when-a-change-is-done)).

### Access

- The AWS organisation is the team's own: Max's account is the management
  account ([ADR 0012](../decisions/0012-own-aws-organization.md)).
- People sign in through IAM Identity Center with MFA, in three groups with
  three permission sets (platform admins, developers, auditors).
- **Known exception:** the team's IAM users remain in a shared
  full-administrator group (PoC-Admins) with access keys. They're on the
  risk register (R13) and removed in Phase 2's first milestone (M1).
- GitHub Actions uses short-lived OIDC roles; no AWS keys are stored in
  GitHub.

### Cost

- Budget alerts on every deployment: US$1 for Solution B, US$5 for the
  demo, US$100 to US$300 a month for dev, staging and prod.
- Everything that costs money is torn down after each demo
  ([ADR 0010](../decisions/0010-keep-accounts-between-demos.md)); nothing is
  running between demos.

### Confidentiality and intellectual property

- The NDA and IP assignment paperwork was raised with the Centre at the first
  client meeting (Week 6).
- The repository is private. Files holding account IDs, emails or personal
  details are git-ignored, and screenshots are redacted before they're
  committed.
- Cobble's own code isn't in this repository and hasn't been changed.

### Use of AI

The team used Claude (Anthropic) to help format and review documents, and to
assist with the Terraform, since nobody on the team had used Terraform
before. The model is never a source: every fact, date and status comes from
this repository, the minutes or the AWS console, and AI-assisted work goes
through the same pull request review as everything else. Each member states
their own use of AI in their individual report.

## Risk register

Scored as likelihood × impact, each from 1 to 5, using the scale in
[deliverable 6](../deliverables/threat-model.md#3-risk-scoring): 1–4 Low,
5–9 Medium, 10–16 High, 17–25 Critical.

- **R01 to R09** are Tim's risk management plan (19 October 2026), carried
  over with their scores. Two statuses are updated: R06 is closed, and R09
  is now tied to G0.
- **R10 to R17** were added from the Phase 2 plan and the Phase 1 report.
  Their scores are **proposed**, for the team to confirm at the next risk
  review.

| ID | Risk | Type | L | I | Rating | Owner | Treatment | Status |
|---|---|---|---:|---:|---|---|---|---|
| R01 | Cross-tenant data exposure (threat T1) | Security | 3 | 5 | High | Application / Security | Reduce: tenant validation, isolation controls, testing. Platform side proven in M2 with a stand-in module; Cobble's own code needs the Centre's developers | Open |
| R02 | Privileged AWS account compromise (T2) | Security | 3 | 5 | High | Platform team | Reduce: MFA, SSO, least privilege, short-lived roles; narrow admin roles and a break-glass role in M1 | Open |
| R03 | Unauthorised API access | Security | 3 | 5 | High | Application / Platform | Reduce: authentication, WAF, request validation, rate limiting. API Gateway isn't in Phase 2 | Open |
| R04 | A Terraform change causes an incorrect infrastructure change | Delivery | 3 | 4 | High | Platform team | Reduce: pull request review, plan review, CI validation, mocked tests | Open |
| R05 | AWS costs exceed estimates | Cost | 3 | 3 | Medium | Project team | Reduce: budgets, alerts, low-cost design, teardown after demos | Open |
| R06 | Prototype can't be completed within Phase 1 | Delivery | 3 | 4 | High | Project team | Reduce: prioritise core functionality, track on the board | **Closed**: landing zone and dev built and torn down four times in Weeks 12–13 |
| R07 | Loss of service or a failed deployment | Operations | 3 | 4 | High | Platform team | Reduce: environment separation, health checks, circuit-breaker rollback | Open |
| R08 | Backup or restore failure (T9) | Operations | 3 | 5 | High | Platform team | Reduce: automated backups; copy to a separate backup account and two timed restores in M4 | Open |
| R09 | Delayed access, credentials or partner input | Delivery | 3 | 3 | Medium | Project team | Reduce: raise dependencies early; ask for G0 before Semester 1 | Open, see R10 |
| R10 | The Centre's G0 decision or AWS account arrives late | Delivery | 3 | 4 | High | Max | Reduce: ask for G0 before Week 1; everything redeploys from code, so no build time is lost waiting | Open (proposed score) |
| R11 | The A$100 a month funding ceiling isn't agreed | Cost | 3 | 3 | Medium | Jacob (cost model) | Accept with fallback: run each test in a same-day session, then tear down | Open (proposed score) |
| R12 | The build depends on one person | Delivery | 3 | 4 | High | Max | Reduce: every teammate runs the deploy and teardown runbooks; each milestone has a lead and a reviewer | Open (proposed score) |
| R13 | Shared full-admin IAM users with access keys in the team's account | Security | 3 | 5 | High | Max | Avoid: delete the group and keys in M1; use Identity Center only | Open (proposed score) |
| R14 | Closed accounts count against the 10-account limit until about mid-January 2027 | Delivery | 2 | 3 | Medium | Max | Reduce: keep accounts between runs; remove only what costs money ([ADR 0010](../decisions/0010-keep-accounts-between-demos.md)) | Open (proposed score) |
| R15 | Team availability around exams | Delivery | 3 | 3 | Medium | Tim | Reduce: build work ends in Week 10; Week 11 is handover only | Open (proposed score) |
| R16 | Cobble's software isn't supplied by Week 4 | Scope | 3 | 2 | Medium | Max | Accept: moving a real module stays stretch work; the stand-in module proves every milestone | Open (proposed score) |
| R17 | Client meetings don't happen on the agreed fortnightly cadence | Delivery | 3 | 3 | Medium | Max | Reduce: book the Phase 2 meetings with Wayne in advance, aligned to G0, G1 and sprint reviews | Open (proposed score) |

The full analysis behind R01 to R09 (assets, likelihood and impact
definitions, key threat areas) and the 13 platform threats it maps to are in
[deliverable 6](../deliverables/threat-model.md).

### How the register is run

- **Owner:** Tim keeps the register.
- **Review:** at every sprint review, and whenever the architecture changes,
  a new AWS service is added, or a deployment exposes something new.
- **High and Critical risks** need an owner and a treatment before the part
  they affect is called ready.
- **Treatments:** avoid (change the design), reduce (add controls), transfer
  (to a responsible party or service), or accept (with a reason and a
  trigger to review it).
- Changes to a High risk are recorded in this file through a pull request,
  so the history is in Git.

## Ethics

**Privacy and tenant data.** No real tenant data is used, in either phase.
The platform is tested with a stock container, a stand-in module and test
data. If Cobble later holds personal information, the Privacy Act requires a
suspected breach to be assessed within 30 days and reported where serious
harm is likely. If a tenant is critical infrastructure, SOCI may require
incidents to be reported within 12 or 72 hours. Which laws apply is the
Centre's decision at G1; the platform's support for them is in
[deliverable 7](../deliverables/compliance-mapping.md).

**Honest assurance.** Calling a control working when it only exists in code
could lead the Centre to trust an untested platform. So every claim carries a
status: demonstrated, configured, designed or enforced. Gaps are written
down, not hidden: in each deliverable, the scan findings register, and this
register.

**Testing only what we're allowed to.** Every test, including trying to
break the guardrails, runs in accounts the team owns. Nothing is tested
against the Centre's DigitalOcean platform or any third party. Phase 2 tests
run in the Centre's AWS environment only once they've provided it at G0.

**Confidentiality.** The Centre's material stays private: the repository is
private, settings files with account details are git-ignored, and evidence
is redacted before it's committed or shared.

**Cost responsibility.** The AWS account is a team member's own, so nothing
is left running: budgets alert on any spend, and everything that costs money
is torn down after each demo.

**Fair contribution.** Roles and ownership are recorded in
[how we work](way-of-working.md), and the build is being spread beyond one
person (R12).

**Transparency about AI.** AI assistance is disclosed (above), and every AI-assisted
change is reviewed like any other.
