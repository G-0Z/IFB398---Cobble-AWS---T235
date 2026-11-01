# How the design evolved, and the feedback behind it

How we got from the project brief to the two solutions in this repository:
what we tried, what we heard from the Cyber Security Centre and the teaching
team, and what each piece of feedback changed. Every change links to its
evidence. The decisions themselves, with what would make us revisit them,
are in [deliverable 2's key decisions](../deliverables/landing-zone-design.md#key-decisions).

**In short:** we started with a diagram and a research question (ECS or
Kubernetes?). Wayne's review on 14 September turned "a design" into
"something the Centre can implement", and our tutor asked us to prove we
could build it in Phase 1, not just describe it. So we built two solutions
from one set of Terraform modules, deployed the landing zone into real AWS
accounts on 17 to 19 October, and let each failure reshape the design. All
the feedback we received is in the [register](#feedback-register) below,
with what we did about it.

## Contents

1. [The journey at a glance](#the-journey-at-a-glance)
2. [Feedback register](#feedback-register)
3. [What changed, and why](#what-changed-and-why)
4. [What's still open](#whats-still-open)

---

## The journey at a glance

Dates are 2026. The sprint record and meeting minutes have the detail:
[Phase 1 sprint record](phase-1-sprints.md), [meeting minutes](phase-1-meetings.md).

| When | What happened | What it changed |
|---|---|---|
| 16 to 18 Aug (before kick-off) | Repository, folder structure and automatic checks set up; pull request workflow tested | GitHub Free can't enforce branch protection on a private repository, so review became a team rule and the gap is written down ([scan findings](../deliverables/security-controls.md#scan-findings-register)) |
| 27 Aug | First client meeting with Wayne | We raised scope, the AWS account and budget, NDA and IP paperwork, and repository visibility |
| 31 Aug to 13 Sep (Sprint 2) | Research: ECS against EKS, and prices across AWS services. First architecture diagram | ECS on Fargate chosen for a small team ([decision 3](../deliverables/landing-zone-design.md#key-decisions)) |
| 14 Sep | Second client meeting: Wayne reviews the design | Five requests that reshaped the project (rows F1 to F7 below) |
| Week 9 | Tutor meeting | Asked us to show project management and design, and to **demonstrate in Phase 1** that we can deliver Phase 2 (rows F9 to F13) |
| 16 Sep | Deliverables 1 to 8 added as issues #6 to #13 | AWS Educate only offers training labs, so we set up our own AWS account with AWS Organizations. The unit requires two solutions, so the work split into Solution A and Solution B |
| 28 Sep (Sprint 4) | Terraform proof of concept, with automated tests for five modules | Mocked tests catch mistakes with no AWS account and no cost, so every module got tests |
| 6 Oct | Solutions A and B built from one set of shared modules. Comparison written, with 1 month and 3 month options. Web firewall added to staging and production | Wayne's requests answered in writing; the diagram gained its web firewall |
| 7 Oct | Our own manual security review | Found five problems no scanner reported. All five fixed ([scan findings](../deliverables/security-controls.md#found-by-manual-review-7-oct-2026)) |
| 14 Oct | Repository restructured: one configurable workload builds every environment. Trivy replaced tfsec. Prices shown in AUD | Environments can only differ where they're meant to (size, standby database, web firewall) |
| 17 Oct | First real deployment of the landing zone and dev | Account enrolment and permission ordering failed until fixed, and closing the accounts afterwards used up the organisation's account limit ([evidence log](../deliverables/evidence.md#evidence-log)) |
| 18 Oct | `lz-dev.ps1` brings everything that costs money up and down with one command. Second run recorded | Accounts now stay between demos. Re-running found drift in two settings, now fixed. Up in 13 minutes, down in 10 |
| 19 to 20 Oct | Threat model and risk management plan completed (Tim). Presentation built and cut to time | Three High risks named as Phase 2 priorities ([deliverable 6](../deliverables/threat-model.md)) |
| 21 Oct | Team decision on the database | The report presents SQL Server as Cobble's database; swapping the prototype's PostgreSQL for it is stretch work once the Centre chooses a licence (G1) |
| 24 Oct | Cost claims checked against official prices | Assumptions written down; the estimate of about A$790 a month held |

## Feedback register

Every piece of feedback we received, what we did about it, and where to
see the result. "Done" means the change exists and can be checked; it
doesn't mean the control has run live (that's in the
[status diagram](../deliverables/reference-architecture.md#what-has-been-tested)).

### From the Cyber Security Centre (Wayne)

| # | When | What Wayne asked for or told us | What we did | Where to see it | Status |
|---|---|---|---|---|---|
| F1 | 14 Sep | Recommendations that can actually be implemented | Built both solutions as code rather than only describing them. Solution B deploys in one command; Solution A's landing zone and dev environment were deployed into a real AWS organisation on 17 to 19 October | [Evidence](../deliverables/evidence.md), [runbooks](../../runbooks/README.md) | Done |
| F2 | 14 Sep | Issues and their solutions written down | A register of every scanner finding and what we decided; a gaps table in every deliverable; a log of what broke in each deployment and how we fixed it; this page | [Scan findings](../deliverables/security-controls.md#scan-findings-register), [landing zone gaps](../deliverables/landing-zone-design.md#gaps), [evidence log](../deliverables/evidence.md#evidence-log) | Done |
| F3 | 14 Sep | An implementation timeframe with 1 month and 3 month options | Set out week by week in the Solution A and B comparison (6 October), then updated for what Phase 1 has already proven | [Phase 2 plan](phase-2-plan.md#implementation-options-1-month-or-3-months) | Done |
| F4 | 14 Sep | A schedule covering this semester and next | Phase 1 run as six two-week sprints; Phase 2 planned as five milestone sprints and a close week, with two client decision points | [Phase 1 sprint record](phase-1-sprints.md), [Phase 2 plan](phase-2-plan.md#schedule), [Figure](../media/diagrams/phase-2-plan.png) | Done |
| F5 | 14 Sep | The architecture diagram had no web firewall | AWS WAF added in front of the load balancer in staging and production, with managed rules and a rate limit | [`waf.tf`](../../infrastructure/modules/container-service/waf.tf), [status diagram](../deliverables/reference-architecture.md#what-has-been-tested) | Done (in code; not yet run live) |
| F6 | 14 Sep | Cobble's development stays on DigitalOcean until it's ready, and the app can load from GitHub | Moving Cobble is out of scope. Phase 2 rebuilds the platform in the Centre's AWS environment and proves it with a stand-in module; moving a real module is stretch work if the Centre supplies its software by Week 4 | [Phase 2 plan](phase-2-plan.md) | Planned |
| F7 | 14 Sep | In production, each client pays for its own storage | Not designed yet. Phase 2's M2 gives each tenant its own storage boundary, which is where measuring and charging storage per tenant would start | [Threat T1 next steps](../deliverables/threat-model.md#what-would-reduce-the-high-risks) | Open (after Phase 2) |
| F8 | 14 Sep | Meet at least fortnightly, weekly only if needed | Adopted, so the rest of the time went into building and writing | [Client meeting 2 minutes](phase-1-meetings.md#week-9-client-meeting-2) | Done |

### From the teaching team

| # | When | What we were asked for | What we did | Where to see it | Status |
|---|---|---|---|---|---|
| F9 | Week 9 | Show how the project is managed | Every deliverable is an issue on the project board, split into sub-issues with dates, a P0 to P2 priority and an owner. Six sprints with a report each; minutes for every meeting | [How we work](way-of-working.md) | Done |
| F10 | Week 9 | Show the design | Reference architecture, landing zone design and seven recorded decisions, plus a diagram marking what has actually been tested | [Deliverable 1](../deliverables/reference-architecture.md), [deliverable 2](../deliverables/landing-zone-design.md) | Done |
| F11 | Week 9 | Demonstrate a core competency in Phase 1, to show we can complete Phase 2 | Deployed the landing zone and a dev environment into AWS, four times, with logs, screenshots and a recording. Every change runs through automated tests and a security scanner | [Evidence](../deliverables/evidence.md) | Done |
| F12 | Week 9 | Research and its outcomes, and how we'd implement it in Phase 2 | Research report with 15 questions and 14 prioritised recommendations; a Phase 2 plan with decision points, milestones and dated sprints | [Phase 2 plan](phase-2-plan.md) | Done |
| F13 | Week 9 | Follow up with Wayne for access to Cobble's modules | Requested ahead of Phase 2. Phase 2 proves the platform with a stand-in module either way; a real module is stretch work if the software arrives by Week 4 | [Decision points](phase-2-plan.md#decision-points) | In progress |
| F14 | Unit requirement | Deliver two solutions: a full solution and a minimum viable product | Solution A (full landing zone) and Solution B (MVP), built from the same modules so B is a working slice of A | [Key decision 1](../deliverables/landing-zone-design.md#key-decisions) | Done |

### From our own reviews and test runs

| # | When | What we found | What we did | Where to see it | Status |
|---|---|---|---|---|---|
| F15 | 7 Oct | A manual review found five problems the scanners couldn't see, including GitHub's read-only role being able to read stored data | All five fixed; the read-only role now can't read buckets or logs | [Scan findings](../deliverables/security-controls.md#found-by-manual-review-7-oct-2026) | Done |
| F16 | 14 Oct | tfsec has been folded into Trivy by its maintainers | Switched the automatic scan to Trivy, with Checkov by hand as a second opinion | [`ci.yml`](../../.github/workflows/ci.yml) | Done |
| F17 | 17 Oct | Closed AWS accounts still count against the organisation's limit for 90 days | Accounts, sign-in and guardrails now stay between demos; only what costs money is torn down | [Quickstart](../../runbooks/demo-landing-zone-quickstart.md) | Done |
| F18 | 18 Oct | Running the deployment again while it was up showed two settings drifting from the code | Both fixed; the next run reported no changes | [Evidence log](../deliverables/evidence.md#evidence-log) | Done |
| F19 | 19 to 20 Oct | The threat model and the detailed risk assessment rate residual risk at different points in time | Explained side by side, with the same three priorities | [Deliverable 6](../deliverables/threat-model.md#how-this-page-relates-to-the-detailed-risk-assessment) | Done |
| F20 | 24 Oct | Some cost estimates went further than the evidence | Every price re-checked against AWS's published prices, and the assumptions written down. The total held at about A$790 a month with everything running | [What it costs](../../infrastructure/README.md#what-it-costs) | Done |

## What changed, and why

| Area | First idea | Where we ended up | What changed our mind |
|---|---|---|---|
| Where Cobble's containers run | ECS or Kubernetes (EKS), undecided | ECS on Fargate | Sprint 2 research and the Implementation Guide (§7): no servers or cluster upgrades for a small team |
| The front door | A load balancer, with no web firewall on the diagram | Load balancer with AWS WAF in staging and prod; CloudFront and API Gateway once there's a domain | Wayne's review (F5); [decision 6](../deliverables/landing-zone-design.md#key-decisions) |
| Which AWS account | A client account or AWS Educate | Our own AWS Organization for Phase 1; the Centre's accounts in Phase 2 | AWS Educate only offers training labs; access to the Centre's environment is a Phase 2 step |
| How many solutions | One design | Two solutions from one codebase | The unit requires a full solution and an MVP (F14); one codebase stops them drifting apart |
| How environments are built | A separate folder per environment | One workload, configured by a settings file per environment | The 14 October restructure: copies drifted |
| Tearing down | Destroy everything, accounts included | Keep the free parts (accounts, sign-in, guardrails); remove only what costs money | The account limit (F17) |
| Checking the code | tfsec on every change | Trivy on every change, Checkov by hand, and a manual review | tfsec's retirement (F16); the manual review's five finds (F15) |
| The database | RDS for SQL Server, from the Implementation Guide | PostgreSQL in the prototype; SQL Server presented as the target, swapped once the Centre chooses a licence | Licensed SQL Server costs far more at small sizes, and its standby copy needs Standard or Enterprise edition ([decision 5](../deliverables/landing-zone-design.md#key-decisions)); team decision on 21 October |
| Security accounts | Separate Log Archive and Security Tooling accounts (AWS reference design) | One Security account doing both | Halves the fixed cost with the same separation from workloads ([decision 4](../deliverables/landing-zone-design.md#key-decisions)) |
| Proof | A design on paper | Deployed, recorded and repeatable | The tutor's request to demonstrate core competency in Phase 1 (F11) |

## What's still open

The biggest open items are the three High risks: tenant isolation (T1),
broad administrator access (T2) and backups that sit in the same account as
the data (T9). Each has a next step in the
[threat model](../deliverables/threat-model.md#what-would-reduce-the-high-risks)
and a sprint in the [Phase 2 plan](phase-2-plan.md#schedule). The
decisions only the Centre can make (database edition, budget, recovery
targets and region) are listed under
[open decisions](../deliverables/landing-zone-design.md#open-decisions).
