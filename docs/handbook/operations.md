# Operations

How the platform is deployed, demoed, released, watched, patched, backed up
and torn down, and who is responsible for each part. The step-by-step
runbooks are in [`runbooks/`](../../runbooks/README.md); this page explains
the model they follow.

## Principles

- **Everything is code.** Every AWS resource is created by Terraform. A
  console change is drift: it's either reverted or put into code.
- **Same code, different values.** demo, dev, staging and prod are built by
  one folder. Only the values file differs.
- **Build once, promote the same image.** Container images get an immutable
  version tag. The tag that passed staging is the tag that goes to prod.
- **No stored keys.** People sign in through Identity Center; CI signs in
  through GitHub OIDC with short-lived credentials.
- **Tear down what costs money.** Accounts, sign-in and guardrails are free
  and stay. Everything else is built to be removed and rebuilt cleanly.

## What you need

- Terraform 1.10 or later and the AWS CLI.
- A single sign-on login to the organisation's management account with
  administrator rights (`aws configure sso` once, `aws sso login` per
  session). Never the root user.
- For Solution A's landing zone: the filled-in `settings.auto.tfvars` files
  and `users.csv`, which are kept out of Git because they hold account IDs
  and email addresses. The team holds the copies.

Before touching anything: `aws sts get-caller-identity` and confirm the
account.

## Deploying Solution A

The full build is done once, in order. Each step produces outputs the next
step needs. The landing-zone steps all follow the same pattern: copy the
`.example` settings file, fill it in, `terraform init`, `plan -out`, read the
plan, `apply`, `output`.

| Step | Folder | Runs in | Builds | Hands on |
|---|---|---|---|---|
| 0 | `bootstrap` | Management | The state bucket (shared with Solution B). Re-run later with `organization_id` so CI roles can reach state | |
| People | `landing-zone/identity` | Whichever account administers Identity Center | Three groups and a login per row of `users.csv` | group names |
| 1 | `landing-zone/1-organization` | Management | OUs, 5 member accounts, 4 guardrails, each group's role in each account | `organization_id`, `account_ids` |
| 2 | `landing-zone/2-security` | Security (via assumed role) | Locked log bucket, organisation trail, GuardDuty, Security Hub, Config aggregator, Access Analyzer, alert topic, key | `config_bucket_name`, `config_kms_key_arn` |
| 3 | `landing-zone/3-shared-services` | Shared Services | Container registry, account baseline, budget | `container_registry_url` |
| 4 | `workload` + `dev.tfvars`, then `staging`, then `prod` | Each environment's account | Network, app, database, bucket, GitHub roles, budget | `app_url` |

Ground rules from the runbook: read every plan before applying, and treat a
plan that wants to destroy or replace something unexpected as a stop sign;
finish each step's verification before starting the next; stay signed in to
the management account throughout.

Full detail: [deploy-solution-a.md](../../runbooks/deploy-solution-a.md).

### Steps that can't be code

A few things have no AWS API, so they're documented manual steps:

1. Enable IAM Identity Center for the organisation, require MFA, and turn on
   "Send email OTP" so people created by Terraform can set their own
   password.
2. Confirm the "AWS Notification - Subscription Confirmation" email after
   step 2, or no security alerts arrive. (Tearing down step 2 deletes the
   subscription, so this repeats after every rebuild.)
3. Create the GitHub environments `dev`, `staging` and `prod`, with required
   reviewers on `staging` and `prod`.
4. Store each environment's plan role ARN as a repository variable so the
   nightly drift check covers it.
5. Request an ACM certificate once a domain exists, set `certificate_arn`,
   and re-apply. HTTP then redirects to HTTPS.

## The demo loop: landing zone + dev in one command

[`lz-dev.ps1`](../../infrastructure/solution-a/lz-dev.ps1) wraps steps
People, 1, 2 and 4 (dev) so the whole thing can be shown and removed
without creating or closing an account.

```powershell
cd infrastructure/solution-a
.\lz-dev.ps1 up       # ~15 min: people + organisation (0 changes if already there), security (68), dev (75). Ends with the app URL
.\lz-dev.ps1 status   # per account: GuardDuty / Security Hub / Config on or off; dev app URL
.\lz-dev.ps1 down     # ~10 min: destroys dev and security; hands security services back and switches them off in each member. Accounts stay
```

Safeguards built into the script: it refuses to run unless signed in to the
management account; it refuses to apply a step-1 plan that would delete
anything; it never creates an account that exists or closes one; it logs
every run to `infrastructure/solution-a/evidence/lz-dev-<action>-<timestamp>.txt`;
both `up` and `down` can be re-run and pick up where they stopped.

After `down`, every column of the status table must read `False`. If one
says `True`, run `down` again. Cost while up is about A$0.35 an hour;
nothing after `down`.

Quickstart with troubleshooting:
[demo-landing-zone-quickstart.md](../../runbooks/demo-landing-zone-quickstart.md).

## Deploying Solution B

```powershell
cd infrastructure/solution-b
terraform init
terraform plan -out deploy.tfplan   # 48 to add
terraform apply deploy.tfplan
terraform plan -detailed-exitcode   # exit 0: running matches code

terraform plan -destroy -out destroy.tfplan
terraform apply destroy.tfplan      # from your own machine, never from CI: the deploy role would delete itself
```

Set `enable_demo_app = true` in `poc.auto.tfvars` to add a load balancer and
one container (about A$1.90 a day). Tearing down Solution B also deletes its
audit trail, which is an accepted trade-off for a demo platform; Solution A
keeps its trail in a separate account.
[deploy-solution-b.md](../../runbooks/deploy-solution-b.md).

## Workload-only demo

Solution A's real `workload` can be deployed into the team's own account for
a few hours with `demo.tfvars` (66 resources, about A$0.22 an hour):

```powershell
cd infrastructure/solution-a/workload
terraform init -reconfigure -backend-config="key=solution-a/workload/demo/terraform.tfstate"
terraform apply  -var-file="demo.tfvars"
terraform destroy -var-file="demo.tfvars"
```

It can run at the same time as Solution B (separate IP ranges and state).
What it can't show is anything that needs an organisation: guardrails,
single sign-on, the locked log archive, central detection, the registry.
[demo-solution-a.md](../../runbooks/demo-solution-a.md).

## Repeatability check

A deployment is only considered done when it has been deployed, torn down
and redeployed from code, a final `terraform plan -detailed-exitcode` exits
0, and the run logs are saved as evidence. Ideally someone who didn't write
the code runs it, following only the runbook, which proves the instructions
as well as the code. Runs are recorded in the
[evidence log](../Evidence/README.md#evidence-log).

## Releasing the application

1. The module team builds the image and pushes
   `<registry>/cobble-module:<version>` to ECR in Shared Services. The
   on-push scan runs immediately.
2. They set `container_image` to that tag in `dev.tfvars` and apply. ECS
   starts the new containers and waits for them to pass health checks before
   stopping the old ones.
3. If the new containers fail their health checks, the deployment circuit
   breaker rolls back to the previous task definition automatically.
4. The same tag is promoted to staging, then prod.

**Rollback:** set `container_image` back to the previous tag and apply. The
old image is still in ECR; the lifecycle policy keeps the 30 most recent.

## Change pipeline: today and planned

```
Pull request   ──► format, validate, tests, Trivy scan               built
               ──► terraform plan per environment, read-only role    roles built; workflow planned
Merge to main  ──► deploy to dev                                     planned
               ──► deploy to staging   after 1 approval              planned
               ──► deploy to prod      after 1 approval, different person
Nightly        ──► drift check on dev, staging, prod                 built
```

The plan and apply roles exist in every Solution A account. Until the deploy
workflow is written, a platform admin deploys by following the runbook from
their own machine. The GitHub environments with required reviewers are what
will gate the apply role.

## Monitoring and alerting

| What is watched | How | Who is told |
|---|---|---|
| Threats: compromised credentials, crypto-mining, unusual API calls | GuardDuty in every account, managed from Security | Security alerts email (high and critical) |
| Security posture against CIS v3.0 and AWS best practices | Security Hub, organisation-wide | Security alerts email (high and critical); weekly review |
| Configuration changes | AWS Config, aggregated in Security | Weekly review |
| Resources shared outside the organisation | IAM Access Analyzer | Security Hub |
| Every API call | Organisation CloudTrail → locked archive | Investigations |
| Network traffic | VPC Flow Logs (30 days; 90 in prod) | Investigations |
| Container CPU and memory | ECS metrics; Container Insights in prod | Auto scaling acts on CPU (target 60%) |
| Load | Auto scaling: staging 1–2, prod 2–10 tasks | AWS adds or removes tasks |
| Drift from code | Nightly plan with the read-only role | Failed workflow emails repository watchers |
| Spend | AWS Budgets per account: 80% actual, 100% forecast | Budget email |
| Image vulnerabilities | ECR scan on push | Checked by the module team at release |

Not yet proven end to end: the alert emails are configured, but no alert has
been received in a live test yet. That needs a deployment left running.

Designed only, for the next phase: CloudWatch alarms on load balancer 5xx
and unhealthy hosts, on database CPU, storage and connections; a dashboard
per environment; tracing; WAF logs. Until then the module team watches
service health in the ECS console and the load balancer metrics during a
release.

### Severity and response times (proposed)

| Severity | Example | Respond within |
|---|---|---|
| Sev 1 | Prod down; confirmed security breach | 30 minutes, any hour |
| Sev 2 | Prod degraded; GuardDuty high finding | 4 business hours |
| Sev 3 | Non-prod down; drift found; budget forecast exceeded | Next business day |
| Sev 4 | Medium findings; advice | Weekly review |

## Patching and vulnerability management

| Layer | Who | How | Cadence |
|---|---|---|---|
| Hosts under the containers | AWS | Fargate: no hosts to patch | Continuous |
| Fargate platform version | AWS, picked up by us | New tasks start on the latest version; any release or forced redeploy picks it up | Each release, monthly at the latest |
| Container image (OS packages, libraries) | Module team | Rebuild from a pinned base, new tag, normal release, scan on push | Monthly, and within 7 days of a critical finding |
| PostgreSQL engine | AWS | Minor versions applied automatically in the maintenance window; major versions are planned changes | Minor: automatic. Major: yearly |
| Terraform and providers | Platform team | Bump `versions.tf` and the lock file; CI validates and tests | Quarterly |
| GitHub Actions | Platform team | Pinned to commit hashes; bumped deliberately | Quarterly |
| Guardrails, Security Hub standards | Security operations | Code change through the pipeline | As needed |

A critical or high finding (ECR, Security Hub, GuardDuty) becomes a ticket
for the owning team: critical fixed within 7 days, high within 30. A fix
that can't be made in time needs a risk acceptance from the platform product
owner, recorded with an expiry date. Terraform misconfiguration findings
block the merge.

## Backup and recovery

| Data | Protection | Retention |
|---|---|---|
| Database | Automated backups, point-in-time restore | dev and staging 7 days; prod 35 |
| Database (prod) | Multi-AZ standby; deletion protection; final snapshot on delete | While it exists |
| Tenant files | S3 versioning | Old versions 90 days |
| Audit logs | Object Lock, governance mode | 365 days (1 day in the demo so it can be torn down) |
| Container images | Immutable tags | 30 most recent |
| The platform | Code in Git; state in a versioned, encrypted bucket | Git history |

Recovery objectives, proposed and awaiting the business owner's approval:

| Component | Back within (RTO) | Data loss at most (RPO) | How |
|---|---|---|---|
| App containers | 30–60 minutes | None (stateless) | Redeploy the same image |
| Database | 4 hours | 15 minutes (about 5 in practice) | Multi-AZ failover (1–2 minutes, automatic) or point-in-time restore |
| Whole environment | 1 day | 15 minutes | `terraform apply` a new environment, restore the database into it |

**Restore testing:** each quarter, restore the prod database to a point in
time into staging, time it, check the app against it, and record the result.
A backup that has never been restored isn't proven.

**The gap:** there is no copy outside the account or region. Losing the prod
account would lose its backups. The planned fix is AWS Backup to a separate
backup account and to Melbourne (`ap-southeast-4`), with Vault Lock and a
tested restore. The region guardrail would need to allow Melbourne first.

## Routine operations

| When | Task | Owner |
|---|---|---|
| Daily | Read security alert and budget emails; check the nightly drift run | Security operations; platform team |
| Weekly | Review new Security Hub findings and the GuardDuty summary; assign owners | Security operations |
| Weekly | Tear down dev and staging when idle (saves about A$315 a month) | Platform team |
| Monthly | Rebuild and release container images; review spend against budget | Module team; product owner |
| Quarterly | Database restore test; access review (edit `users.csv`); bump Terraform providers and actions | Database engineering; security operations; platform team |
| Yearly | Review RTO/RPO, retention periods and this model; consider compliance-mode Object Lock | Product owner |

**Joiners and leavers:** add or remove the person's row in
`landing-zone/identity/users.csv` and apply. A leaver loses access to every
account at once. IAM users are never created.

## Incident runbooks

Every incident starts the same way: name who's handling it, start a
timeline, and keep the logs.

| Incident | Short version |
|---|---|
| App outage | Check the target group's health; read ECS service events, stopped-task reasons and the container log (`/cobble-<env>/app`). If it followed a release, roll back the image tag. If the database is the cause, see below. Write a short post-incident note |
| Database failure or bad data | Check RDS events; a Multi-AZ failover completes in 1–2 minutes and the app reconnects. For bad data: scale the service to 0 to stop writes, restore to a new instance at a point just before the damage, point the app at it, verify, scale back up. Never drop the damaged database until the restore is verified |
| Security finding or credential compromise | Contain: disable the user in Identity Center or strip the role; scale a compromised service to 0. Rotate secrets and redeploy. Investigate in the locked CloudTrail archive and the GuardDuty finding. Fix in code, re-enable, tell the product owner, assess tenant exposure |
| Drift detected | Read the failed drift run. If it was an emergency fix, put it into code and merge; otherwise apply `main` to revert. Find out who and why from CloudTrail |
| WAF blocking real users | Find the rule in the WAF sampled requests; add a narrow, peer-reviewed exception in `waf.tf` with a removal date |
| Cost alert | Cost Explorer grouped by service. Usual causes: a forgotten environment, NAT data transfer, auto scaling at its ceiling. Tear down or scale down, then find the cause |
| Region outage | Designed only; needs the cross-region backups first |

Full text: [operations model §6](../05-deployment-operations/README.md#6-runbooks).

## Who does what

| Role | Signs in as | Responsible for |
|---|---|---|
| Cloud platform team | `cobble-platform-admins` | Landing zone, accounts, network, ECS, Terraform, pipeline, drift, provider updates |
| DevSecOps | `cobble-platform-admins` | CI checks, image scanning, deployment controls, release evidence |
| Database engineering | `cobble-developers` (dev); platform admin for prod changes | Database settings, backups, restore tests, migrations |
| Security operations | `cobble-auditors` | GuardDuty, Security Hub, CloudTrail, incident response, access reviews, WAF exceptions |
| Module team | `cobble-developers` | Their image, health check, releases, rollbacks, image vulnerabilities |
| Platform product owner | `cobble-auditors` | RTO/RPO, release approvals, risk acceptance, budget |

| Activity | Does it | Accountable |
|---|---|---|
| Change infrastructure | Platform | Platform |
| Release to prod | DevSecOps, module team | Product owner |
| Patch container images | Module team | Module team |
| Restore test | Database | Database |
| Security incident | Platform | Security operations |
| Access review | Security operations | Security operations |
| Accept a risk | Product owner | Product owner |

## Cost

Australian dollars, Sydney, low traffic, everything left running. AWS prices
in USD; converted at A$1.44 per US$1 (late July 2026). AWS Budgets only work
in USD, so the limits in the code are USD.

| | Per month |
|---|---|
| Solution B | Under A$7; about A$0 when torn down between demos |
| Solution A: management, Security, Shared Services | A$70 to A$145 (detection, checks, Config, keys, log storage, registry) |
| Solution A: dev | About A$160 (NAT A$62, ALB ~A$29, one task ~A$16, database A$26, public IPs ~A$16, logs and keys) |
| Solution A: staging | About A$175 (as dev plus WAF ~A$14) |
| Solution A: prod | About A$375 (2 NATs A$124, ALB, 2 larger tasks ~A$62, Multi-AZ database ~A$115, WAF, public IPs ~A$22) |
| **Solution A, everything on** | **About A$790** |
| Solution A with dev and staging off when idle | About A$475 |

Hourly, for demos: workload alone A$0.22; landing zone + dev A$0.35. Unit
prices and sources are in
[infrastructure/README.md](../../infrastructure/README.md#what-it-costs).

## Tearing down

| What | How |
|---|---|
| Landing zone demo | `.\lz-dev.ps1 down`. Accounts, sign-in and guardrails stay |
| dev or staging | `terraform destroy` in `workload` with that environment's values file and state key, by a person: the GitHub roles can't, because a guardrail stops them switching off Config |
| prod | Set `protect_from_deletion = false`, apply, then destroy. Deliberately two steps |
| Step 2 (Security) | `terraform destroy` after the environments. Log buckets only go with `force_destroy_buckets = true`; audit logs under a compliance-mode lock never do |
| Steps 1 and 3, people, accounts | Not torn down. Accounts are `prevent_destroy`; they're closed by hand only at the end of the project |
| The state bucket | Never. It holds the record of what was built |

Things that block a clean teardown, and what to do:

| Blocker | What happens | What to do |
|---|---|---|
| KMS keys | AWS waits 7 to 30 days before deleting a key and bills until then | Expected. A redeploy creates a new key |
| Object Lock | Governance mode: an admin can lift it. Compliance mode: nobody can, not even root, until the date passes | Keep governance mode in any demo or student account |
| AWS accounts | Protected from `terraform destroy`. Closed accounts linger 90 days and count against the account quota | Keep them between demos |
| A last log file landing mid-delete | `BucketNotEmpty` during `down` | Run `down` again |

After any teardown: `terraform plan` should offer to create everything
again; `status` should read `False` everywhere; check the console for
leftover VPCs, load balancers, clusters or databases; check Billing the next
day.
