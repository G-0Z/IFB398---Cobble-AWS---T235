# Project documentation

The project has three steps: **build** the platform from code, **test** it in
AWS, then **propose** to the Cyber Security Centre what it's ready for:
holding tenant data, or a first Cobble module being built on it. No real
tenant data is used. A stock nginx container and test data stand in.

> [!TIP]
> **New to the project?** Start with the [engineering handbook](handbook/README.md).
> It explains the platform end to end without assuming you know the brief.

| Folder | What's in it |
|---|---|
| [`handbook/`](handbook/README.md) | How the platform works, for someone new: [architecture](handbook/architecture.md), [infrastructure code](handbook/infrastructure-code.md), [operations](handbook/operations.md), [security](handbook/security.md), [deliverables](handbook/deliverables.md), and the [glossary](handbook/glossary.md) |
| [`standards/`](standards/README.md) | The rules for changing the code: directory structure, file layout, naming, state, modules, variables and outputs, version control, documentation, testing |
| [`deliverables/`](#the-eight-deliverables) | The capstone deliverables, one page each (below) |
| [`decisions/`](decisions/README.md) | Twelve architecture decision records |
| `project/` | How the project ran and what's next: [definition](project/definition.md), [how we work](project/way-of-working.md), [design iterations](project/design-iterations.md), [governance, risks and ethics](project/governance-risks-ethics.md), [Phase 1 sprints](project/phase-1-sprints.md), [Phase 1 meetings](project/phase-1-meetings.md), [Phase 2 plan](project/phase-2-plan.md) |
| `media/` | Diagrams (with `.drawio` sources) and redacted console screenshots |

Outside `docs/`: the [infrastructure code](../infrastructure/README.md), the
[runbooks](../runbooks/README.md) and the [CI workflows](../.github/workflows/README.md).

## The eight deliverables

| # | Deliverable | What it answers |
|---|---|---|
| 1 | [Reference architecture](deliverables/reference-architecture.md) | How is Cobble hosted in AWS, and what has actually been tested? |
| 2 | [Landing zone design](deliverables/landing-zone-design.md) | Which accounts exist, who can do what, and which rules can't be broken? |
| 3 | [Security controls](deliverables/security-controls.md) | Which controls protect the platform, where are they built, and what did the scanners find? |
| 4 | [Infrastructure as code](../infrastructure/README.md), with its [evidence](deliverables/evidence.md) | Does the code deploy, tear down and redeploy reliably? |
| 5 | [Deployment and operations](deliverables/deployment-operations.md) | How is the platform deployed, monitored, patched, backed up and supported? |
| 6 | [Threat model and risk assessment](deliverables/threat-model.md) | What could go wrong, how much risk is left, and how risks are managed |
| 7 | [Compliance mapping](deliverables/compliance-mapping.md) | How does the design line up with NIST CSF, Essential Eight, ISO 27001 and SOCI? |
| 8 | Stakeholder presentation | Given at the end of Phase 1 (Week 13), with a live landing-zone demo. The final presentation falls in Phase 2 |

## How we describe status

| Question | Words used |
|---|---|
| Has it actually run in AWS? | **Demonstrated** (deployed and seen working), **configured** (in the code, not yet run live) or **not yet built** |
| How strong is the control? | **Designed** (written down only), **configured** (built by the code; an administrator could still change it) or **enforced** (built, and a guardrail stops anyone turning it off) |

The [glossary](handbook/glossary.md#how-finished-a-control-is) has the full definitions.
