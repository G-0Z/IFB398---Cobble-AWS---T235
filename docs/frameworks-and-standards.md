# Frameworks and standards

The outside frameworks, guides and conventions this project follows, and
where each one shows up. Whenever a page says "following X", X is listed
here.

## Cloud architecture

| Framework | Version | What it governs here | Applied in |
|---|---|---|---|
| Cobbled AWS Platform Engineering Implementation Guide (client) | v1.0 | The target design, tags, runbook list, acceptance checklist | Throughout; alignment table in [deliverable 1](01-reference-architecture/README.md#how-we-line-up-with-the-implementation-guide) |
| [AWS Security Reference Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/welcome.html) | Current | OU and account structure; security services delegated to a Security account | [`solution-a/landing-zone/1-organization`](../infrastructure/solution-a/landing-zone/1-organization/), [deliverable 2](02-landing-zone-design/README.md) |
| [Organizing your AWS environment](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/organizing-your-aws-environment.html) | Current | OU names (Security, Infrastructure, Workloads) | `organization.tf` |
| [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html), Security pillar | Current | Threat modelling (SEC01-BP07), least privilege, encryption, detection | [Deliverables 3](03-security-controls/README.md) and [6](06-threat-model/README.md) |
| [IAM security best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html) | Current | Temporary credentials only: Identity Center for people, OIDC for CI | `identity-center.tf`, `modules/github-oidc` |

## Security and compliance

| Framework | Version | What it governs here | Applied in |
|---|---|---|---|
| [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework) | 2.0 (Feb 2024) | Grouping of controls into Govern, Identify, Protect, Detect, Respond, Recover | [Deliverable 7](07-compliance-mapping/README.md) |
| [ASD Essential Eight](https://www.cyber.gov.au/business-government/asds-cyber-security-frameworks/essential-eight/essential-eight-maturity-model) | Maturity Model, Nov 2023 | Australian baseline mitigation strategies | Deliverable 7 |
| [ISO/IEC 27001](https://www.iso.org/standard/27001) | 2022 | Annex A control themes | Deliverable 7 |
| Security of Critical Infrastructure Act 2018 (SOCI) | As amended (enhanced CIRMP rules 10 Jun 2026) | "SOCI-style considerations" if Cobble hosts critical-infrastructure tenants | Deliverable 7 |
| [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services) | v3.0 | Live posture checks in Security Hub | [`2-security/detection.tf`](../infrastructure/solution-a/landing-zone/2-security/detection.tf) |
| AWS Foundational Security Best Practices | Current | Live posture checks in Security Hub | `2-security/detection.tf` |
| STRIDE, with [AWS Threat Composer](https://awslabs.github.io/threat-composer/) | — | Threat modelling method | [Deliverable 6](06-threat-model/README.md) |

## Code

| Convention | Version | What it governs here | Applied in |
|---|---|---|---|
| [Terraform style guide](https://developer.hashicorp.com/terraform/language/style) | Current | Formatting (`terraform fmt`), naming, file layout | All `.tf` files; [naming conventions](naming-conventions.md) |
| [Standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure) | Current | `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, README per module | [`infrastructure/modules/`](../infrastructure/modules/README.md) |
| [Dependency lock file](https://developer.hashicorp.com/terraform/language/files/dependency-lock) | Terraform 1.x | Lock file committed per root config, not per module | `.gitignore`, every root config |
| [Terraform tests](https://developer.hashicorp.com/terraform/language/tests) | Terraform 1.x | Module tests with mocked providers | `infrastructure/modules/*/tests/` |
| [Trivy](https://trivy.dev/) (replaced tfsec) | 0.7x | Misconfiguration scanning, blocks merges | [`ci.yml`](../.github/workflows/ci.yml), [scan findings](03-security-controls/scan-findings.md) |
