# The brief and the deliverables

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

**Delivered:** [docs/01-reference-architecture/](../01-reference-architecture/README.md).
A whole-platform diagram and a per-environment diagram, the three network
layers and what each can reach, a component table that names the AWS
service and the module for every concern, the security boundaries and what
protects each, and a section-by-section alignment table against the
Implementation Guide. A second copy of the diagram
([`cobble-target-architecture.png`](../01-reference-architecture/cobble-target-architecture.png))
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

**Delivered:** [docs/02-landing-zone-design/](../02-landing-zone-design/README.md).
Six accounts in three OUs following the AWS Security Reference Architecture;
three Identity Center groups and three permission sets, with a table of who
gets what where; the two GitHub roles; the four guardrails; seven recorded
design decisions with the reason for each and what would cause a revisit;
the gaps against the Implementation Guide; and the open decisions only the
Centre can make (regions, SQL Server edition, identity provider, RTO/RPO).

**What it says, in short:** "test" is served by staging; a single Security
account replaces AWS's two; nobody uses IAM users; guardrails hold against
administrators; the admin role is still too broad and there's no
break-glass role yet.

Handbook pages: [architecture.md](architecture.md#accounts),
[security.md](security.md#known-gaps).

### 3. Security control design

**Asked for:** a documented set of controls covering IAM, MFA, secrets,
encryption, network segmentation, logging, monitoring, vulnerability
management, incident response and backup/recovery.

**Delivered:** [docs/03-security-controls/](../03-security-controls/README.md),
one section per area with what's done, which file builds it and what risk
remains; the [control map](../../infrastructure/README.md#control-map)
rating every control designed / configured / enforced for each solution;
and the [scan findings register](../03-security-controls/scan-findings.md)
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
change, and nightly drift detection. The evidence that it works is in
[docs/Evidence/](../Evidence/README.md): a dated log of every deployment
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

**Delivered:** [docs/05-deployment-operations/](../05-deployment-operations/README.md):
deployment principles and order, the change pipeline (what's built and what's
planned), the application release and rollback procedure, a monitoring
table, severity levels, a patching matrix by layer, backup coverage, proposed
RTO/RPO, restore testing, a routine-operations calendar, six incident
runbooks, a role table and a RACI. The deploy, demo and teardown runbooks
themselves are in [`runbooks/`](../../runbooks/README.md).

**What it says, in short:** everything is deployed from code, never by
clicking; AWS patches the hosts and the database engine; the database can
be restored to any point in the last week (five in prod); the biggest gaps
are application alarms, an automated deploy workflow and an off-account
backup.

Handbook page: [operations.md](operations.md).

### 6. Threat model and risk assessment

**Asked for:** a practical assessment of key cloud security threats and
mitigations, especially multi-tenancy, privileged access, API exposure,
data protection and service availability.

**Delivered:** [docs/06-threat-model/](../06-threat-model/README.md): nine
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

**Delivered:** [docs/07-compliance-mapping/](../07-compliance-mapping/README.md):
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

**Delivered:** [docs/Presentation/](../Presentation/README.md): a 19-slide
deck, a slide-by-slide speaking script, a synopsis, and the demo script for
the live landing-zone demonstration (with a recording as a fallback).

**What it says, in short:** the story is "secure foundation, rebuilt from
code": what Cobble is, why it needs a foundation before features, two
solutions from one set of building blocks, six accounts with one job each,
one request from the internet to the database, four guardrails, ten control
areas in code, built and torn down from code, three risks to fix before
tenant data, and what the Centre needs to decide next.

## Beyond the brief

Three pages exist because of the review feedback rather than the brief:

- [Design iterations](../design-iterations.md): every piece of feedback
  from the Centre and the teaching team, what changed because of it, and
  where to see the result. Useful for understanding *why* a decision was
  made, not only what it was.
- [Evidence](../Evidence/README.md): the proof that the code runs, so the
  deliverables are claims that can be checked.
- [Phase 2 roadmap](../phase-2-roadmap.md): the options, sign-off gates and
  sprint plan for the next phase, below.

## What's next

The next phase (February to May 2027) starts with a decision by the Centre
rather than with code. Phase 1 gives them three options:

| Option | What it is | Cost to run |
|---|---|---|
| 1. Full landing zone | Solution A deployed into the Centre's own AWS organisation | About A$790 a month; A$475 with dev and staging off when idle |
| 2. Start small, grow | Solution B in one Centre account now; move to A when real tenants arrive | About A$0 between demos |
| 3. Review DigitalOcean first | Review what the Centre runs on DigitalOcean today, then choose 1 or 2 with that evidence | Time only |

The same modules build options 1 and 2, so choosing one doesn't rule out
the other. Whichever is chosen, the build work is the same for most of the
phase and closes the three High risks in order:

| Sprint | Work |
|---|---|
| S2 | Narrow admin roles, break-glass role, least-privilege database user (T2) |
| S3–S4 | Deploy pipeline; application and database alarms; mid-point demo |
| S5 | Extra guardrails (public databases, unencrypted storage); Inspector; deploy into the Centre's accounts if approved |
| S6 | Backup account, Melbourne copy, timed restore test (T9) |
| S7 | Handover package; final presentation |

The Centre signs off at four gates: scope re-confirmed (week 0), option and
plan chosen (week 2), mid-point demo and accounts/budget confirmed (week 7),
handover accepted (week 12). The rule for every sprint is the same as in
Phase 1: a change is done only when it has been deployed, torn down and
redeployed from code with a clean final plan and the logs saved as
evidence. No Cobble application modules are built; only the Terraform is
extended.

Full detail: [phase-2-roadmap.md](../phase-2-roadmap.md).
