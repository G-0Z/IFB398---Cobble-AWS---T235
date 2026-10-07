# Capstone deliverables

| # | Deliverable | Location | Status |
|---|---|---|---|
| 1 | Reference architecture | [`01-reference-architecture/`](01-reference-architecture/) | Scaffolding |
| 2 | Landing zone design | [`02-landing-zone-design/`](02-landing-zone-design/) | Started: [ADRs](02-landing-zone-design/adr/) 0001 to 0003 (0003: [Solution A and B](02-landing-zone-design/adr/0003-two-solutions-mvp-and-full-landing-zone.md)) |
| 3 | Security controls | [`03-security-controls/`](03-security-controls/) | Started: [scan findings register](03-security-controls/scan-findings.md); control map in [`infrastructure/README.md`](../infrastructure/README.md#control-map) |
| 4 | Terraform PoC | [`infrastructure/`](../infrastructure/) | Solution B deployed; Solution A written and tested |
| 5 | Deployment and operations | [`05-deployment-operations/`](05-deployment-operations/), [`runbooks/`](../runbooks/) | Started: deploy and teardown [runbooks](../runbooks/) for both solutions |
| 6 | Threat model | [`06-threat-model/`](06-threat-model/) | Scaffolding |
| 7 | Compliance mapping | [`07-compliance-mapping/`](07-compliance-mapping/) | Scaffolding |
| 8 | Presentation | [`08-presentation/`](08-presentation/) | Scaffolding |

Deliverable 4 is code, so it lives in `infrastructure/` rather than here.
Update the Status column as each deliverable lands.

Naming rules for folders, files, Terraform and AWS resources:
[`naming-conventions.md`](naming-conventions.md).
