# Capstone deliverables

> [!TIP]
> **New to the project?** Read the [engineering handbook](handbook/README.md)
> first. It explains the platform end to end without assuming you know the
> brief; this page is the index of the formal deliverables behind it.

The project brief asks for eight deliverables. Most have a numbered folder
here. Deliverable 4 is the code itself, in
[`infrastructure/`](../infrastructure/README.md), so its page holds the
evidence that the code works.

| # | Deliverable | What it answers | Status |
|---|---|---|---|
| 1 | [Reference architecture](01-reference-architecture/README.md) | How is Cobble hosted in AWS? | Drafted, with a [diagram of what has been tested](01-reference-architecture/README.md#what-has-been-tested) |
| 2 | [Landing zone design](02-landing-zone-design/README.md) | Which accounts exist, who can do what, and which rules can't be broken? Also lists the key design decisions | Drafted |
| 3 | [Security controls](03-security-controls/README.md) | Which controls protect the platform, and where are they built? | Drafted, with a [scan findings register](03-security-controls/scan-findings.md) |
| 4 | [Infrastructure as code: evidence](Evidence/README.md) | Does the code deploy and redeploy reliably? | Both solutions deploy and tear down. Landing zone demo recorded 18 Oct 2026, with logs and screenshots |
| 5 | [Deployment and operations](05-deployment-operations/README.md) | How is the platform deployed, monitored, patched, backed up and supported? | Drafted |
| 6 | [Threat model](06-threat-model/README.md) | What could go wrong, and how much risk is left? | Drafted, with a detailed [risk assessment](06-threat-model/threat-model-and-risk-assessment.md) and [risk management plan](06-threat-model/risk-management.md) |
| 7 | [Compliance mapping](07-compliance-mapping/README.md) | How does the design line up with NIST CSF, Essential Eight and ISO 27001? | Drafted |
| 8 | [Presentation](Presentation/README.md) | What do we tell stakeholders, and what do we demo? | 19-slide deck and speaking script (20 Oct 2026) |

## Project records

How the team planned and ran the work.

| Record | What's in it |
|---|---|
| [Design iterations](design-iterations.md) | How the design evolved, every piece of feedback we received, and what each one changed |
| [Sprint plan](Sprint%20Plans/IFB398-T235-Sprint%20Plan-Phase%201%20and%202.md) | Every Phase 1 and Phase 2 sprint, with dates, goals and status |
| [Sprint reports](Sprint%20Plans/README.md) | One per Phase 1 sprint: the tracker items, who owned them, and what got done |
| [Meeting minutes](Meeting%20Minutes/README.md) | Every weekly team meeting, and both client meetings with Wayne |
| [Project board](https://github.com/users/G-0Z/projects/2) | Every deliverable as an issue, broken into sub-issues, with dates and a P0 to P2 priority |

## Reference pages

| Page | Use it to |
|---|---|
| [Engineering handbook](handbook/README.md) | Understand the architecture, code, operations and security from scratch |
| [Phase 2 roadmap](phase-2-roadmap.md) | See the options the Centre chooses from, the sign-off gates and the Semester 1 2027 sprints |
| [Glossary](glossary.md) | Look up a term |
| [Naming conventions](naming-conventions.md) | Name a folder, file or AWS resource |
| [Frameworks and standards](frameworks-and-standards.md) | See which frameworks the design follows, and where |

## How we describe status

The deliverables answer two different questions, so they use two sets of
words. The [glossary](glossary.md#how-finished-a-control-is) has the full
definitions.

| Question | Words used |
|---|---|
| Has it actually run in AWS? | **Demonstrated** (deployed and seen working, in the runs of 17 to 18 October 2026), **configured** (in the code, but not yet run live) or **not yet built** |
| How strong is the control? | **Designed** (written down only), **configured** (built by the code; an administrator could still change it) or **enforced** (built, and a guardrail stops anyone turning it off) |
