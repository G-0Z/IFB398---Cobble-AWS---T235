# Cobble AWS platform: engineering handbook

> **Handbook:** **Start here** · [Architecture](architecture.md) · [Infrastructure code](infrastructure-code.md) · [Operations](operations.md) · [Security](security.md) · [Deliverables](deliverables.md) · [Glossary](glossary.md) · [Standards](../standards/README.md)

This handbook explains the Cobble AWS platform to someone who has never seen
it: what it is, how it's put together, how it's deployed and run, how it's
secured, and what the project set out to deliver. It's written for
engineers, operators and security reviewers. You don't need to know anything
about the project to start here.

## What Cobble is, and what this repository is

**Cobble** is a proof-of-concept platform from the Cyber Security Centre for
hosting software modules for many customer organisations (tenants) at once.
The modules themselves are being built elsewhere. This repository builds the
**AWS foundation they would run on**: the accounts, the network, sign-in,
logging, monitoring, backups and security controls, all written as Terraform
code so the whole platform can be created, torn down and rebuilt identically.

The Cobble application is out of scope. Wherever a running application is
needed to prove that the platform works, a stock nginx container stands in
for it.

The work was done as a university capstone project (QUT IFB398, team T235,
August to November 2026) with the Cyber Security Centre as the industry
partner. The brief asked for eight deliverables, from a reference
architecture through to a threat model and compliance mapping;
[deliverables.md](deliverables.md) explains what each one asked for and what
it turned into. The rest of this handbook describes the platform on its own
terms.

## Two solutions from one codebase

The platform is delivered at two levels of completeness. Both are built from
the same Terraform modules, so the small one is a working slice of the large
one, not a separate prototype.

| | Solution B: minimum viable platform | Solution A: full landing zone |
|---|---|---|
| Scope | One AWS account with the core security baseline: encryption key, audit trail, threat detection, a private network with traffic logging, a hardened data bucket, GitHub deploy roles and a budget alert. Optional demo web page | Six AWS accounts in an AWS Organization with guardrails, single sign-on, tamper-proof central audit logs, organisation-wide threat detection, a container registry, and separate dev, staging and prod environments each running web servers behind a load balancer with a private PostgreSQL database |
| Resources | 48, in about 5 minutes | Landing zone + dev: 143 on top of the accounts. One environment alone: 66 |
| Cost | About A$0 (deployed only for demos) | About A$790 a month with everything running; about A$475 with dev and staging switched off when idle |
| Use | Show the baseline cheaply; a starting point for a single-account deployment | What the Centre would run in production |

## How to read this handbook

Read in order the first time. Each page stands alone after that.

| Page | Answers |
|---|---|
| [architecture.md](architecture.md) | How is the platform shaped? Accounts, network, request path, identity, logging, encryption, backups, and the decisions behind them |
| [infrastructure-code.md](infrastructure-code.md) | How is the Terraform organised? Modules, root configs, settings, state, and the checks that run on every change |
| [operations.md](operations.md) | How is it deployed, demoed, released, monitored, patched, backed up, torn down, and who does what |
| [security.md](security.md) | Which controls exist, how strong each one is, what the threat model says, what the scanners found, and how the design lines up with NIST CSF, Essential Eight, ISO 27001 and SOCI |
| [deliverables.md](deliverables.md) | What the project brief asked for, what was delivered against each item, and what's planned next |

Changing the code? The [Terraform standards](../standards/README.md) are the
rules this handbook's platform was built to.

Deeper material lives alongside the code and in the deliverable pages;
each page links to it. In particular:

- [`infrastructure/`](../../infrastructure/README.md): every folder has its own README saying what it builds and why.
- [`runbooks/`](../../runbooks/README.md): step-by-step instructions for every deploy, demo and teardown.
- [The deliverables](../README.md#the-eight-deliverables): the original write-ups, one page each.
- [Glossary](glossary.md): plain-English definitions of the AWS and Terraform terms used throughout.

## Two words you'll see everywhere

The platform's documents describe status with two separate scales, because
"is it built?" and "has it run?" are different questions.

**How strong a control is:**

| Word | Meaning |
|---|---|
| Designed | Written down only |
| Configured | Built by the code, so it exists whenever the platform is deployed. An administrator could still change it |
| Enforced | Built, and a guardrail stops anyone in the account turning it off |

**Whether it has run in AWS:**

| Word | Meaning |
|---|---|
| Demonstrated | Deployed and seen working, with logs and screenshots (the runs of 17 to 19 October 2026) |
| Configured | In the code, not yet run live |
| Not yet built | Planned for the next phase |

## Current state in one paragraph

Solution A's landing zone with a dev environment deploys, tears down and
redeploys identically: it has been built and removed with one command each
way four times (18 to 19 October 2026), with one cycle screen-recorded.
Solution B deploys and tears down from code; its recorded redeploy cycle is
still to do. Every
change to the code is formatted, validated, tested against a mocked AWS and
security-scanned in CI, and reviewed before it merges. A nightly drift
workflow is built, ready for environments that stay deployed. No real tenant data is used. What the tests
show feeds a proposal to the Centre: before the platform holds tenant data
or hosts a first Cobble module, three risks need fixing. They are tenant
isolation (left to the application), an over-broad administrator role, and
backups that live in the same account as the data. Each has a planned fix
([security.md](security.md#what-would-reduce-the-high-risks)).

---

[↑ Back to the top](#cobble-aws-platform-engineering-handbook) · Next: [Architecture →](architecture.md)
