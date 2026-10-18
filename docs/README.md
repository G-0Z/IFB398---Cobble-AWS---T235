# Capstone deliverables

The project brief asks for eight deliverables. Each has its own folder here.
Deliverable 4 is the code itself, in [`infrastructure/`](../infrastructure/README.md),
so its folder holds the evidence that the code works.

| # | Deliverable | What it answers | Status |
|---|---|---|---|
| 1 | [Reference architecture](01-reference-architecture/README.md) | How is Cobble hosted in AWS? | Drafted |
| 2 | [Landing zone design](02-landing-zone-design/README.md) | Which accounts exist, who can do what, and which rules can't be broken? Also lists the key design decisions | Drafted |
| 3 | [Security controls](03-security-controls/README.md) | Which controls protect the platform, and where are they built? | Drafted, with a [scan findings register](03-security-controls/scan-findings.md) |
| 4 | [Infrastructure as code](04-iac-evidence/README.md) | Does the code deploy and redeploy reliably? | Both solutions deploy and tear down; landing zone demo recorded 18 Oct 2026. Screenshots still to add |
| 5 | [Deployment and operations](05-deployment-operations/README.md) | How is the platform deployed, monitored, patched, backed up and supported? | Drafted |
| 6 | [Threat model](06-threat-model/README.md) | What could go wrong, and how much risk is left? | Drafted |
| 7 | [Compliance mapping](07-compliance-mapping/README.md) | How does the design line up with NIST CSF, Essential Eight and ISO 27001? | Drafted |
| 8 | [Presentation](08-presentation/README.md) | What do we tell stakeholders, and what do we demo? | Deck, outline and demo script |

Update the Status column as each deliverable is finished.

## Reference pages

| Page | Use it to |
|---|---|
| [Glossary](glossary.md) | Look up a term |
| [Naming conventions](naming-conventions.md) | Name a folder, file or AWS resource |
| [Frameworks and standards](frameworks-and-standards.md) | See which frameworks the design follows, and where |
