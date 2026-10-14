# Deliverable 4: Infrastructure-as-code prototype and evidence

The code is in [`infrastructure/`](../../infrastructure/README.md). This page
collects the **evidence that it deploys, tears down and redeploys
reliably**, and tracks the platform against the Implementation Guide's
acceptance checklist.

**In short:** both solutions deploy from code into the team's AWS account
and tear down cleanly. Deploying again gives exactly the same result, and a
final check confirms nothing differs from the code. Every change is also
checked automatically before it can merge.

## What the prototype is

| | Solution B (MVP) | Solution A (full landing zone) |
|---|---|---|
| Code | [`solution-b`](../../infrastructure/solution-b/) | [`solution-a/`](../../infrastructure/solution-a/) |
| Deploys | 48 resources, one `terraform apply` | Workload: 66 resources in one account with `demo.tfvars` ([`workload/`](../../infrastructure/solution-a/workload/)); landing zone in ordered steps |
| Checked on every pull request | Formatting, validation, security scan, and automated tests for every building block | Same |
| How to run it | [runbooks/deploy.md](../../runbooks/deploy.md) | [runbooks/demo-solution-a.md](../../runbooks/demo-solution-a.md) |

## Evidence log

Record each run here, newest first. Before committing screenshots or logs,
hide account IDs, email addresses and resource IDs (ARNs). Ideally the
person running it didn't write the code, and follows only the runbooks: that
proves the instructions work too.

| Date | What | Who | Result | Evidence |
|---|---|---|---|---|
| YYYY-MM-DD | Solution B: deploy → teardown → redeploy → `plan -detailed-exitcode` | | e.g. 48 added / 48 destroyed / 48 added / exit 0 | link to log or screenshot |
| YYYY-MM-DD | Solution A demo: deploy → teardown → redeploy → `plan -detailed-exitcode` | | e.g. 66 added / 66 destroyed / 66 added / exit 0 | |
| YYYY-MM-DD | CI run on `main` (all jobs green) | | | link to the Actions run |
| YYYY-MM-DD | `terraform test` across all modules | | | |

### Screenshots worth capturing

| Shows | Where in the console |
|---|---|
| The demo page served through the load balancer | Browser, `terraform output app_url` |
| ECS tasks running in private subnets with no public IP | ECS > cluster > task > Networking |
| RDS "Publicly accessible: No", encryption on | RDS > database > Connectivity, Configuration |
| Data bucket encrypted with the KMS key, public access blocked | S3 > bucket > Properties, Permissions |
| CloudTrail logging with log file validation | CloudTrail > Trails |
| GuardDuty enabled | GuardDuty > Summary |
| Flow logs on the VPC | VPC > Flow logs |
| The budget and its alert | Billing > Budgets |
| A green CI run | GitHub > Actions |

Save images in `docs/04-iac-evidence/images/` and link them in the log.

## Implementation Guide acceptance checklist

The Guide's platform acceptance checklist (§16.1, p.31). Many items are
about the Cobble application, which is out of scope. Those are marked N/A
rather than left blank.

| # | Guide item (summarised) | Status | Evidence or reason |
|---|---|---|---|
| 1 | All production resources created by IaC; drift reports clean | Partial | Everything is Terraform; nightly drift plan ([`drift.yml`](../../.github/workflows/drift.yml)). No production deployed yet |
| 2 | No task, ALB backend or RDS instance publicly reachable | Met (design) | Private subnets, no public IPs, database subnets with no route ([architecture](../01-reference-architecture/README.md#network-zones)). Screenshot pending |
| 3 | WAF enforcing tuned rules, logs to the central account | Partial | Web firewall in staging and prod; not yet tuned; no firewall logging ([key decisions](../02-landing-zone-design/README.md#key-decisions)) |
| 4 | Every API route follows `/apl`, `/adm`, `/aum` versioned paths | N/A | Application routes; no API Gateway yet ([key decisions](../02-landing-zone-design/README.md#key-decisions)) |
| 5 | Each module API has its own task identity, secrets, DB principal, target group, log group, alarms | N/A (Phase 2) | One service per environment until the application exists |
| 6 | Runtime DB principals can't do direct table DML or call other modules' procedures | N/A (Phase 2) | Application schema; app currently uses the master user |
| 7 | RLS negative tests prove missing tenant context fails closed | N/A | Application |
| 8 | Module install, verify, disable, re-enable, roll back, with audit records | N/A | Application |
| 9 | N, N-1 and N-2 versions coexist | N/A | Application |
| 10 | A disabled module can't receive credentials or traffic | N/A | Application |
| 11 | Blue/green rollback, RDS failover and backup restore meet RTO/RPO | Not met | Circuit breaker rollback built; failover and restore not yet tested ([ops model §4](../05-deployment-operations/README.md#restore-testing)) |
| 12 | Critical ECR / Inspector findings block release; SBOM and digest kept | Not met | Scan on push only; no Inspector, SBOM or digest pinning |
| 13 | CloudTrail, Container Insights, logs, traces and findings visible to on-call | Partial | CloudTrail, findings, logs, Container Insights (prod) built; no tracing |
| 14 | Runbooks, escalation contacts, ownership and access reviews approved | Partial | Runbooks and RACI written ([ops model](../05-deployment-operations/README.md)); named contacts and approval pending |

## Handoff checklist

The Guide's final handoff checklist (Appendix E, p.36), for whoever takes
the platform on next.

| Item | Status |
|---|---|
| Architecture decisions approved | Recorded in [deliverable 2](../02-landing-zone-design/README.md#key-decisions); client approval pending |
| IaC repositories and deployment roles created | Done (this repo; `github-oidc` roles) |
| Diagrams updated with deployed identifiers | Pending deployment |
| Security group, route, WAF and IAM policies peer reviewed | Each change reviewed by pull request |
| Secrets, keys, rotation and break-glass tested | Not yet; no break-glass role |
| Module deployment and recovery tests | N/A (application) |
| RDS failover and restore evidence | Not yet |
| Dashboards, alarms, runbooks, on-call accepted | Runbooks written; no alarms or dashboards |
| Cost forecast, budgets, quotas approved | Cost estimate in [`infrastructure/README.md`](../../infrastructure/README.md#what-it-costs); budgets built; approval pending |
| Go-live and rollback authority named | Pending (platform product owner) |
