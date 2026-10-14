# Deliverable 5: Deployment and operations model

How Cobble is deployed, monitored, patched, backed up and run day to day in
AWS, and who is responsible for each part.

**In short:** every change goes through code review and automatic checks,
then is deployed from code, never by clicking in the console. Security
problems and overspending are emailed automatically, and a nightly check
catches anything changed by hand. AWS patches the servers and the database.
The database can be restored to any point in the last week (five weeks in
prod). The biggest gaps are application alarms and a backup copy outside
the account.

It covers both solutions:

- **Solution B** (`infrastructure/solution-b/`): one account, deployed for demos and torn down afterwards.
- **Solution A** (`infrastructure/solution-a/`): the full design. Its workload is deployed and torn down the same way for demos; the multi-account landing zone is set up once.

Each section separates what is **built today** from what is **designed
only** (Phase 2), so a future team knows exactly what it's inheriting.
"Guide §6.3" and similar refer to the client's Implementation Guide.

## Contents

1. [Deployment model](#1-deployment-model)
2. [Monitoring and alerting](#2-monitoring-and-alerting)
3. [Patching and vulnerability management](#3-patching-and-vulnerability-management)
4. [Backup and recovery](#4-backup-and-recovery)
5. [Routine operations](#5-routine-operations)
6. [Runbooks](#6-runbooks)
7. [Support responsibilities](#7-support-responsibilities)
8. [Gaps and next steps](#8-gaps-and-next-steps)

---

## 1. Deployment model

### Principles

- **Everything is code.** Every AWS resource is created by Terraform. A console change counts as drift and is reverted or put into code (Guide §15).
- **Same code, different settings.** demo, dev, staging and prod are all built by `solution-a/workload`. Only their settings file differs: size, number of NAT gateways, web firewall, backup retention.
- **Build once, promote the same image.** Container images are tagged with a version that can't be overwritten (ECR `IMMUTABLE` tags). The tag that passed staging is the one that goes to prod (Guide §12.2).
- **No stored keys.** People sign in through IAM Identity Center. CI signs in through GitHub OIDC with short-lived credentials.

### Order of deployment (Solution A)

| Step | Folder | Account | Done by |
|---|---|---|---|
| 0 | `bootstrap/` | Management | Platform admin, once |
| People | `solution-a/landing-zone/identity` | Whichever account administers Identity Center | Platform admin |
| 1 | `solution-a/landing-zone/1-organization` | Management | Platform admin |
| 2 | `solution-a/landing-zone/2-security` | Security | Platform admin |
| 3 | `solution-a/landing-zone/3-shared-services` | Shared Services | Platform admin |
| 4 | `solution-a/workload` with `dev`, `staging`, `prod.tfvars` | dev, staging, prod | Platform admin first; then the pipeline |

Full steps are in [deploy-solution-a.md](../../runbooks/deploy-solution-a.md).

### Change pipeline

```
Pull request  ──► automatic checks: format, validate, tests, security scan   (built)
              ──► preview of changes per environment, read-only role       (role built; Phase 2)
Merge to main ──► deploy to dev                                            (Phase 2)
              ──► deploy to staging   after 1 approval
              ──► deploy to prod      after 1 approval by a different person
Nightly       ──► drift check on dev, staging, prod                        (built)
```

The checks run on every pull request, and `main` needs one approving review
before a merge. GitHub Free can't make passing checks *mandatory* on a
private repository, so reviewers look at the result before approving. The
GitHub roles for previewing and deploying already exist in every Solution A
account (`modules/github-oidc`). Until the deploy workflow is added, a
platform admin deploys by following the runbook.

### Application releases

1. The module team builds the image and pushes `<registry>/cobble-module:<version>` to ECR in Shared Services. The scan on push runs straight away.
2. They change `container_image` for dev and apply. ECS starts the new containers and waits for them to pass health checks before it stops the old ones.
3. If the new containers fail their health checks, the **deployment circuit breaker** rolls back to the previous task definition automatically.
4. Promote the same tag to staging, then to prod.

**Rollback:** set `container_image` back to the previous tag and apply. The old image is still in ECR: the lifecycle policy keeps the 30 most recent.

### Solution B

### Demos (both solutions)

Deploy and tear down by hand around each demo:
[deploy.md](../../runbooks/deploy.md) and [teardown.md](../../runbooks/teardown.md) for
Solution B (48 resources), [demo-solution-a.md](../../runbooks/demo-solution-a.md) for
Solution A's workload (66 resources). A redeploy should create the same
resources again, and a final check should show nothing differs from the
code. That proves the deployment is repeatable.

---

## 2. Monitoring and alerting

| What is watched | How | Who is told | Solution |
|---|---|---|---|
| Threats (compromised credentials, crypto-mining, unusual API calls) | GuardDuty in every account | Security alerts email (high and critical) | A, B |
| Security posture (CIS v3.0, AWS Foundational Security Best Practices) | Security Hub, organisation-wide | Security alerts email (high and critical) | A |
| Configuration changes | AWS Config in every account, aggregated in Security | Reviewed weekly in Security Hub | A |
| Resources shared outside the organisation | IAM Access Analyzer | Security Hub | A |
| Every API call | Organisation CloudTrail, to the locked log archive | Investigations | A (B: one trail, removed on teardown) |
| Network traffic | VPC Flow Logs (30 days; 90 in prod) | Investigations | A, B |
| Container CPU and memory | Container Insights (prod); ECS service metrics everywhere | Auto scaling acts on CPU automatically | A |
| Load | Auto scaling: staging 1–2 containers, prod 2–10, aiming for 60% CPU | AWS adds or removes containers itself | A |
| Infrastructure drift | Nightly `terraform plan` ([drift.yml](../../.github/workflows/drift.yml)) | A failed workflow emails repo watchers | A |
| Spend | AWS Budgets per account: 80% of actual spend, 100% of forecast | Budget email | A, B |
| Container image vulnerabilities | ECR scan on push | Scan results in ECR, checked by the module team at release | A |

**Designed only (Phase 2), Guide §13.3:** application alarms (load
balancer 5xx errors, unhealthy containers, p95 latency; database CPU,
storage and connections), a dashboard per environment, and tracing. Until
these exist, the module team checks service health in the ECS console and
the load balancer metrics during a release.

### Severity and response times

These are proposals. The platform product owner approves them.

| Severity | Example | Respond within |
|---|---|---|
| Sev 1 | Prod down; confirmed security breach | 30 minutes, any hour |
| Sev 2 | Prod degraded; GuardDuty high finding | 4 business hours |
| Sev 3 | Non-prod down; drift found; budget forecast exceeded | Next business day |
| Sev 4 | Medium findings; advice | Weekly review |

---

## 3. Patching and vulnerability management

| Layer | Who patches | How | Cadence |
|---|---|---|---|
| Servers under the containers | AWS | Fargate: there are no servers for us to patch | Continuous |
| Fargate platform version | AWS, applied by us | New containers start on the latest platform version. Any release or forced redeploy picks it up | With each release, or monthly at the latest |
| Container image (OS packages, libraries) | Module team | Rebuild from a pinned base image, new version tag, normal release. ECR scan on push | Monthly, and within 7 days of a critical finding |
| Database engine (PostgreSQL) | AWS | `auto_minor_version_upgrade = true`: minor versions are applied in the maintenance window. Major versions are planned changes | Minor: automatic. Major: yearly |
| Terraform and AWS provider | Platform team | Bump the version in `versions.tf` and the lock file; CI validates and tests | Quarterly |
| GitHub Actions | Platform team | Pinned to commit hashes; bump them deliberately | Quarterly |
| Guardrails (SCPs, Security Hub standards) | Security operations | Code change through the pipeline | As needed |

**Vulnerability handling.** A critical or high finding (ECR scan, Security
Hub, GuardDuty) becomes a ticket for the owning team. Critical: fix within
7 days. High: within 30 days. A fix that can't be made in time needs a risk
acceptance from the platform product owner, recorded with an expiry date.
Terraform misconfiguration findings block the merge (the Trivy job in CI).
Deliberate exceptions are kept in
[scan-findings.md](../03-security-controls/scan-findings.md).

---

## 4. Backup and recovery

### What is protected today

| Data | Protection | Retention |
|---|---|---|
| Database (RDS PostgreSQL) | Automated backups with point-in-time restore | dev and staging: 7 days. prod: 35 days |
| Database (prod) | Standby copy in a second AZ (Multi-AZ). Deletion protection. A final snapshot is taken if it's ever deleted | While the database exists |
| Data buckets (S3) | Versioning: a deleted or overwritten file can be recovered | Old versions kept 90 days |
| Audit logs | Object Lock: can't be changed or deleted | 365 days (governance mode) |
| Container images | ECR, tags can't be overwritten | 30 most recent images |
| Infrastructure | Terraform code in Git; state in a versioned, encrypted S3 bucket | Git history |

The containers keep no data of their own, so recovering one means
redeploying it.

### Recovery objectives

These are proposals from Guide §14.2; the business owner must approve them.

| Component | RTO (back within) | RPO (data loss at most) | How |
|---|---|---|---|
| App containers | 30–60 minutes | None (they hold no data) | Redeploy the same image version |
| Database | 4 hours | 15 minutes (in practice about 5, with point-in-time restore) | Multi-AZ failover (automatic, 1–2 minutes), or restore to a point in time |
| Whole environment | 1 day | 15 minutes | `terraform apply` a new environment, then restore the database into it |

### Restore testing

A backup that has never been restored hasn't been proven. **Each
quarter:** restore the prod database to a point in time, into staging. Time
it, check the app works against it, and record the duration and how much
data was missing.

**Designed only (Phase 2), Guide §14.3:** AWS Backup copies to a separate
backup account and to Melbourne (ap-southeast-4), plus a DR runbook that
was tested. Today, losing a whole region or the prod account would mean
data loss up to the last backup that lives outside that account. Right now
there is no such backup. This is the largest remaining recovery risk.

---

## 5. Routine operations

| When | Task | Owner |
|---|---|---|
| Daily | Read any security alert or budget email; check the nightly drift run | Security operations; platform team |
| Weekly | Review new Security Hub findings and the GuardDuty summary; assign owners | Security operations |
| Weekly | Tear down dev and staging when idle (saves about $220 a month) | Platform team |
| Monthly | Rebuild and release container images; review spend against budget | Module team; platform product owner |
| Quarterly | Database restore test; access review (who is in which Identity Center group: edit `users.csv`); bump Terraform providers and actions | Database engineering; security operations; platform team |
| Yearly | Review RTO/RPO, retention periods and this document; consider switching audit logs to compliance mode | Platform product owner |

**Joiners and leavers.** Add or remove the person's row in
`solution-a/landing-zone/identity/users.csv` and apply. A leaver loses access to
every account at once. Never create IAM users (Guide §3.2).

---

## 6. Runbooks

### Written

Deploy, demo and teardown runbooks are listed in
[runbooks/README.md](../../runbooks/README.md), with which one to use when,
how to deploy into a fresh account, and what blocks a clean teardown.

### Incident runbooks (Guide §17.1)

Each one starts the same way: say who is handling it, start a timeline,
and **keep the logs** (don't delete anything you might need to
investigate).

**App outage (one environment)**
1. Check the load balancer target group: are the containers healthy?
2. In ECS, check the service events and stopped tasks (look at the stop reason), then the container logs in CloudWatch (`/cobble-<env>/app`).
3. If it started with a release, set `container_image` back to the previous tag and apply. If the circuit breaker has already rolled back, confirm the service is stable.
4. If the database is the cause, follow *Database failure* below.
5. Write a short post-incident note.

**Database failure or bad data**
1. Check RDS events. If a Multi-AZ failover is in progress, wait 1–2 minutes; the app reconnects on its own.
2. Bad data (a bad migration or a mistaken delete): stop writes first (scale the ECS service to 0), then restore to a new instance at a point in time just before the damage.
3. Point the app at the restored instance, check the data, and scale back up. Never drop the damaged database until the restore has been verified.

**Security finding or credential compromise**
1. Contain: disable the user in Identity Center, or remove the role's trust or policies. For a container, scale its service to 0.
2. Rotate the affected secrets (database password in Secrets Manager), then redeploy the services that use them.
3. Investigate using CloudTrail in the log archive (it can't be deleted) and the GuardDuty finding details.
4. Fix the cause in code, then re-enable. Tell the platform product owner. Assess whether any tenant data was exposed.

**Drift detected**
1. Read the failed `drift.yml` run: which resources changed?
2. If it was an emergency fix, put it into code and merge it. Otherwise apply `main` to put things back.
3. Find out who made the change (CloudTrail) and why the pipeline wasn't used.

**WAF blocking real users**
1. Find the rule in the WAF sampled requests.
2. Add a narrow exception in `container-service/waf.tf` (one rule, one path). It must be peer-reviewed, and record when it should be removed.

**Cost alert**
1. Open Cost Explorer for that account and group by service.
2. The usual causes are a forgotten environment, NAT data transfer, or auto scaling at its maximum. Tear down or scale down, then find the cause.

**Region outage (DR):** designed only. It needs the cross-region backups
from Section 4 first.

---

## 7. Support responsibilities

The roles follow Guide §17.2. The Identity Center group is what each role
signs in as.

| Role | Identity Center group | Responsible for |
|---|---|---|
| Cloud platform team | `platform-admins` | Landing zone, accounts, network, ECS, Terraform, pipeline, drift, provider updates |
| DevSecOps | `platform-admins` | CI checks, image scanning, deployment controls, release evidence |
| Database engineering | `developers` (dev); `platform-admins` for prod changes | Database settings, backups, restore tests, migrations |
| Security operations | `auditors` (read everywhere) | GuardDuty, Security Hub, CloudTrail, incident response, access reviews, WAF exceptions |
| Module team | `developers` | Their container image, health check, releases and rollbacks, fixing image vulnerabilities |
| Platform product owner | `auditors` | RTO/RPO, release approvals, risk acceptance, budget |

### Who does what (R = does it, A = accountable, C = consulted, I = told)

| Activity | Platform | DevSecOps | Database | SecOps | Module team | Product owner |
|---|---|---|---|---|---|---|
| Change infrastructure | R/A | C | C | C | I | I |
| Release to prod | C | R | C | I | R | A |
| Patch container images | I | C | | I | R/A | I |
| Restore test | C | | R/A | I | C | I |
| Security incident | R | C | C | A | C | I |
| Access review | C | | | R/A | | I |
| Accept a risk | C | C | C | C | | R/A |

---

## 8. Gaps and next steps

| Gap | Risk if left | Next step |
|---|---|---|
| No automatic deploy workflow yet | Deploys depend on one admin's laptop | Add a deploy workflow using the existing apply roles and GitHub environments |
| No application or database alarms (Guide §13.3) | An outage is noticed by users first | CloudWatch alarms on load balancer 5xx and unhealthy hosts, and on database CPU, storage and connections, sent to an on-call topic |
| No backups outside the account or region (Guide §14.3) | Losing an account or region loses data | AWS Backup to a backup account and to Melbourne; a quarterly DR exercise |
| No running-workload scanning (Inspector) | Vulnerabilities in running images go unnoticed | Turn on Inspector organisation-wide |
| Solution B removes its own audit trail on teardown | No record of the teardown | Accepted for the PoC ([key decisions](../02-landing-zone-design/README.md#key-decisions)); Solution A fixes it |
