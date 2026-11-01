# The brief and the deliverables

> **Handbook:** [Start here](README.md) · [Architecture](architecture.md) · [Infrastructure code](infrastructure-code.md) · [Operations](operations.md) · [Security](security.md) · **Deliverables** · [Glossary](glossary.md) · [Standards](../standards/README.md)

What the project was asked to produce, what was delivered against each
item, and what each deliverable actually says. Read this to understand why
the repository is shaped the way it is, or to find the original write-up
behind any part of the handbook.

## The brief

The Cyber Security Centre's brief asked for "an AWS engineering and security
foundation for the Cobble Platform". Cobble is meant to be a modular,
multi-tenant platform where application modules can be deployed, governed,
monitored and secured consistently. The project was explicitly *not* about
building those modules; it was about the cloud engineering, platform
architecture, security controls and operational foundations needed to host
them safely in AWS.

The motivation stated in the brief: platforms fail less often because the
idea is poor than because the engineering foundation is weak. A secure
cloud platform needs network design, identity and access control, logging,
monitoring, deployment patterns, environment separation, backup, recovery,
cost visibility and compliance alignment from the start.

The brief asked for eight outputs, together forming "a usable engineering
and security blueprint that a future team could use as the starting point
for building the Cobble Platform in AWS":

1. AWS reference architecture
2. Secure landing zone design
3. Security control design
4. Infrastructure-as-code prototype
5. Deployment and operations model
6. Threat model and risk assessment
7. Compliance and assurance mapping
8. Final stakeholder presentation

Two things shaped how the brief was answered. The Centre supplied an
*Implementation Guide* (their target design for the platform, with a
tag scheme, runbook list and acceptance checklist), which the deliverables
measure themselves against section by section. And after the Centre's
design review in September, the direction changed from "describe a design"
to "build it and prove it works", which is why the deliverables are backed
by deployed, recorded infrastructure rather than diagrams alone.

## Deliverable by deliverable

### 1. AWS reference architecture

**Asked for:** a clear architecture showing how Cobble would be hosted in
AWS: environments, network zones, compute, database, storage, identity,
logging, monitoring, backup and security boundaries.

**Delivered:** [docs/deliverables/reference-architecture.md](../deliverables/reference-architecture.md).
A whole-platform diagram and a per-environment diagram, the three network
layers and what each can reach, a component table that names the AWS
service and the module for every concern, the security boundaries and what
protects each, and a section-by-section alignment table against the
Implementation Guide. A second copy of the diagram
([`cobble-target-architecture.png`](../media/diagrams/cobble-target-architecture.png))
is marked up to show which parts have run in AWS, which are only in code,
and which aren't built.

**What it says, in short:** one account per environment; only a load
balancer faces the internet; web servers in private subnets; the database
in a third layer with no route out; logs and findings flow to a separate
Security account. Tenancy is pooled, so tenant isolation belongs to the
application and is the biggest remaining risk.

Handbook page: [architecture.md](architecture.md).

### 2. Secure landing zone design

**Asked for:** an AWS account and environment structure (development, test,
staging, production) with separation of duties and least-privilege access.

**Delivered:** [docs/deliverables/landing-zone-design.md](../deliverables/landing-zone-design.md).
Six accounts in three OUs following the AWS Security Reference Architecture;
three Identity Center groups and three permission sets, with a table of who
gets what where; the two GitHub roles; the four guardrails; seven recorded
design decisions with the reason for each and what would cause a revisit;
the gaps against the Implementation Guide; and the open decisions only the
Centre can make (regions, SQL Server edition, identity provider, RTO/RPO).

**What it says, in short:** "test" is served by staging; a single Security
account replaces AWS's two; people sign in through single sign-on and
Solution A's code creates no IAM users (the team's own IAM users go at
milestone M1); guardrails hold against
administrators; the admin role is still too broad and there's no
break-glass role yet.

Handbook pages: [architecture.md](architecture.md#accounts),
[security.md](security.md#known-gaps).

### 3. Security control design

**Asked for:** a documented set of controls covering IAM, MFA, secrets,
encryption, network segmentation, logging, monitoring, vulnerability
management, incident response and backup/recovery.

**Delivered:** [docs/deliverables/security-controls.md](../deliverables/security-controls.md),
one section per area with what's done, which file builds it and what risk
remains; the [control map](../../infrastructure/README.md#control-map)
rating every control designed / configured / enforced for each solution;
and the [scan findings register](../deliverables/security-controls.md#scan-findings-register)
recording every Trivy, Checkov and manual-review finding and the decision on
it.

**What it says, in short:** all ten areas have a control built in code.
The weakest are backup (no off-account copy) and incident response (email
only). Nothing in Solution B is enforced because enforcement needs an
organisation.

Handbook page: [security.md](security.md#controls-by-area).

### 4. Infrastructure-as-code prototype

**Asked for:** a small but working prototype using Terraform, CloudFormation
or CDK to demonstrate repeatable deployment of core platform infrastructure.

**Delivered:** the Terraform in [`infrastructure/`](../../infrastructure/README.md):
nine tested modules, seven root configs, two complete solutions, a
one-command demo script, CI that formats, validates, tests and scans every
change, and a nightly drift workflow (built, but no environment enrolled
yet). The evidence that it works is in
[docs/deliverables/evidence.md](../deliverables/evidence.md): a dated log of every deployment
run with resource counts and timings, 30-odd redacted console screenshots,
the Terraform output logs, and the Implementation Guide's acceptance and
handoff checklists with a status for each item.

**What it says, in short:** Solution B deploys 48 resources in 5 minutes.
Solution A's landing zone plus dev was built and removed four times on 18
and 19 October 2026 (up in 13 minutes, down in 10); re-running `up` while
up reports zero changes. Staging and prod are in code but haven't been
deployed; a full Solution B deploy → destroy → redeploy by someone other
than the author is still to be recorded.

Handbook pages: [infrastructure-code.md](infrastructure-code.md),
[operations.md](operations.md).

### 5. Deployment and operations model

**Asked for:** how Cobble would be deployed, monitored, patched, backed up
and operated in AWS, including runbooks and support responsibilities.

**Delivered:** [docs/deliverables/deployment-operations.md](../deliverables/deployment-operations.md):
deployment principles and order, the change pipeline (what's built and what's
planned), the application release and rollback procedure, a monitoring
table, severity levels, a patching matrix by layer, backup coverage, proposed
RTO/RPO, restore testing, a routine-operations calendar, six incident
runbooks, a role table and a RACI. The deploy, demo and teardown runbooks
themselves are in [`runbooks/`](../../runbooks/README.md).

**What it says, in short:** everything is deployed from code, never by
clicking; AWS patches the hosts and the database engine; the database can
be restored to any point in the last week (five weeks in prod); the biggest gaps
are application alarms, an automated deploy workflow and an off-account
backup.

Handbook page: [operations.md](operations.md).

### 6. Threat model and risk assessment

**Asked for:** a practical assessment of key cloud security threats and
mitigations, especially multi-tenancy, privileged access, API exposure,
data protection and service availability.

**Delivered:** [docs/deliverables/threat-model.md](../deliverables/threat-model.md): nine
trust boundaries taken from the code, thirteen threats classified with
STRIDE, each with its mitigations, residual risk and rating, and a next step
for every High. A more detailed scored risk assessment and risk management
plan were produced as separate team documents; the deliverable explains how
their ratings (after proposed controls) relate to its own (as the platform
stands today).

**What it says, in short:** three High risks. T1: a tenant reaching another
tenant's data, because isolation is left to the application. T2: a stolen
admin session, because the admin role can do anything. T9: losing the
database and its backups together, because there's no copy outside the
account. Everything else is Medium or Low and accepted for a proof of
concept.

Handbook page: [security.md](security.md#threat-model).

### 7. Compliance and assurance mapping

**Asked for:** a lightweight mapping to NIST CSF, Essential Eight, ISO 27001
concepts or SOCI-style critical-infrastructure considerations.

**Delivered:** [docs/deliverables/compliance-mapping.md](../deliverables/compliance-mapping.md):
21 controls the code actually builds, each mapped to NIST CSF 2.0
subcategories, Essential Eight strategies and ISO/IEC 27001:2022 Annex A
controls, with the B / A strength; explicit "not covered" lists for each
framework; and a SOCI section on incident reporting, data residency and
tenant assurance.

**What it says, in short:** good coverage of NIST's Protect and Detect and
of ISO's technical controls; Essential Eight Maturity Level 1 is a realistic
claim once Solution A is deployed and a restore is tested; the gaps are
mostly organisational or depend on the application; SOCI reporting
deadlines would need a written procedure if Cobble hosts
critical-infrastructure tenants.

Handbook page: [security.md](security.md#compliance-posture).

### 8. Final stakeholder presentation

**Asked for:** a concise presentation explaining the design, why key
decisions were made, what risks remain, and the next implementation steps.

**Delivered:** a 19-slide deck with a speaking script and synopsis, given at
the end of Phase 1 with a live landing-zone demonstration (the
[demo runbook](../../runbooks/demo-landing-zone-quickstart.md) is how it was
run). The deck and script are no longer kept in this repository; they're in
its history.

**What it says, in short:** the story is "secure foundation, rebuilt from
code": what Cobble is, why it needs a foundation before features, two
solutions from one set of building blocks, six accounts with one job each,
one request from the internet to the database, four guardrails, ten control
areas in code, built and torn down from code, three risks to fix before
tenant data, and what the Centre needs to decide next.

## Beyond the brief

Three pages exist because of the review feedback rather than the brief:

- [Design iterations](../project/design-iterations.md): every piece of feedback
  from the Centre and the teaching team, what changed because of it, and
  where to see the result. Useful for understanding *why* a decision was
  made, not only what it was.
- [Evidence](../deliverables/evidence.md): the proof that the code runs, so the
  deliverables are claims that can be checked.
- [Phase 2 plan](../project/phase-2-plan.md): the decision points, milestones
  and sprints for the next phase, below.

## What's next

Phase 2 (QUT Semester 1 2027, Weeks 1–11) moves the platform from our proof-of-concept
account into the Centre's own AWS environment, and proves it there with a
stand-in module. At **G0**, before Week 1, the Centre chooses Solution A or
B and provides an account and budget. We recommend Solution B, grown towards
A one milestone at a time. At **G1**, at the end of Week 4, the Centre sets
the licence, recovery targets, backup location, domain and applicable laws.
The A$100 a month funding ceiling is agreed in Sprint 2.

Each sprint delivers one milestone, with a test that must pass before it
counts as done:

| Sprint | Weeks | Milestone | Done when |
|---|---|---|---|
| 1 | 1–2 | M1 Access | Each role is refused what it must not do; sessions expire on time |
| 2 | 3–4 | M2 Deploy and isolate | The stand-in module deploys through the pipeline alone; another tenant's files and another module's data are refused |
| 3 | 5–6 | M3 Monitoring | A recorded change shows who, what and when; a test alarm reaches the team |
| 4 | 7–8 | M4 Recovery | Both restores are timed, and the data lost is measured |
| 5 | 9–10 | M5 Staging and handover | Staging matches the code; every runbook is run by someone who didn't write it |
| Close | 11 | Handover | Final report, presentation, handover pack, and a migration plan marked verified or unverified |

That handover is the proposal: what the tests show the platform is ready
for (tenant data, or a first Cobble module) and what still has to happen
first. Full detail: [Phase 2 plan](../project/phase-2-plan.md).

---

[↑ Back to the top](#the-brief-and-the-deliverables) · ← [Security](security.md)
