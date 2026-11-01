# Architecture decision records

Short records of the decisions that shaped the platform: the context at the
time, the options weighed, what was chosen and what it cost. New decisions
get the next number. Records are never deleted. A superseded one stays,
marked as such, so the reasoning isn't lost.

| # | Decision | Date | Status |
|---|---|---|---|
| [0001](0001-deferred-landing-zone-design.md) | Ship a working single-config PoC; defer the full landing-zone layout (D1 to D10) | 6 Oct 2026 | Superseded in part by 0003 |
| [0002](0002-codebase-structure-for-readability.md) | Restructure the Terraform for readability, without changing what it deploys | 6 Oct 2026 | Accepted |
| [0003](0003-two-solutions-mvp-and-full-landing-zone.md) | Two solutions, an MVP (B) and a full landing zone (A), from one set of modules | 6 Oct 2026 | Accepted |
| [0004](0004-one-workload-per-environment.md) | One workload folder, one settings file per environment | 14 Oct 2026 | Accepted |
| [0005](0005-ecs-fargate-not-eks.md) | Containers on ECS Fargate, not Kubernetes | Sprint 2 | Accepted |
| [0006](0006-one-security-account.md) | One Security account, not two | 6 Oct 2026 | Accepted |
| [0007](0007-postgresql-now-sql-server-target.md) | PostgreSQL in the prototype; SQL Server as the target | Sprint 4, amended 21 Oct 2026 | Accepted |
| [0008](0008-load-balancer-and-waf.md) | A load balancer with a web firewall, not CloudFront and API Gateway | 6 Oct 2026 | Accepted |
| [0009](0009-solution-b-shortcuts.md) | Solution B accepts some shortcuts to stay near A$0 | 6 Oct 2026 | Accepted |
| [0010](0010-keep-accounts-between-demos.md) | Keep the accounts between demos; tear down only what costs money | 18 Oct 2026 | Accepted |
| [0011](0011-trivy-on-every-change.md) | Trivy on every change; Checkov and a manual review as second opinions | 14 Oct 2026 | Accepted |
| [0012](0012-own-aws-organization.md) | Build Phase 1 in the team's own AWS organisation | 16 Sep 2026 | Accepted |

The decisions only the Cyber Security Centre can make (regions, SQL Server
edition, identity provider, recovery targets) are listed in the
[landing zone design](../deliverables/landing-zone-design.md#open-decisions).
