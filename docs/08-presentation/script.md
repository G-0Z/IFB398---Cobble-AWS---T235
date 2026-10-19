# Presentation script: 14 slides

The spoken script for [`Cobble-AWS-Platform.pptx`](Cobble-AWS-Platform.pptx):
**14 slides, including the title and Questions. About 9:15 of talk,
then 3 minutes of questions, 12:15 in all.** The same words are in each
slide's speaker notes, so presenter view shows them.

## Running order

| Slide | Title | Who | Starts | Length |
|---|---|---|---|---|
| 1 | Secure foundation. Rebuilt from code. | Jacob | 0:00 | 0:30 |
| 2 | Cobble needs a foundation before it needs features | Jacob | 0:30 | 0:45 |
| 3 | Two solutions. One set of building blocks. | Jacob | 1:15 | 0:45 |
| 4 | Six accounts, each with one job | Tim | 2:00 | 0:55 |
| 5 | Four guardrails hold, even for administrators | Tim | 2:55 | 0:50 |
| 6 | All ten control areas are built in code | Tim | 3:45 | 0:40 |
| 7 | The page is served by containers the internet can’t reach | Max | 4:25 | 0:45 |
| 8 | Even an administrator is refused outside Australia | Max | 5:10 | 0:30 |
| 9 | Everything that costs money came down with one command | Max | 5:40 | 0:45 |
| 10 | Where we stand | Max | 6:25 | 0:45 |
| 11 | How the team operated | Khai | 7:10 | 0:40 |
| 12 | Three risks to fix before real tenant data arrives | Khai | 7:50 | 0:45 |
| 13 | Reflection and what’s next | Khai | 8:35 | 0:40 |
| 14 | Questions? | All | 9:15 | 3:00 |

Every section is under its time at about 150 words a minute, leaving room
for clicks and the live demo. Rehearse with a timer: if a section runs
long, cut its last sentence, not the demo.

## Backup slides (hidden)

These sit after **Questions?**. The slideshow skips them; jump to one only
if a question needs it.

| Slide | Title |
|---|---|
| 15 | What is the Cobble AWS platform? |
| 16 | Five risk themes shaped every decision |
| 17 | Only the edge faces the internet |
| 18 | No one has a standing password or key to AWS |
| 19 | Where we differ from the Implementation Guide |
| 20 | Live demo: Solution A, deployed into dev |
| 21 | The database is private, and its storage is encrypted |
| 22 | A threat in any account surfaces in the Security account |
| 23 | About A$790 a month to run everything |
| 24 | Every change is checked before it reaches AWS |
| 25 | Key decisions and the reasoning behind them |
| 26 | Mapped to four frameworks: support, not certification |

## Before the session

1. **About 20 minutes before:** sign in and run `.\lz-dev.ps1 up` in
   `infrastructure/solution-a` ([quickstart](../../runbooks/demo-landing-zone-quickstart.md)).
   Wait for `Up. App: http://…`.
2. Open these browser tabs, all set to **Asia Pacific (Sydney)**:
   the `App:` address, and the S3 *Create bucket* page in `cobble-dev` as
   `CobblePlatformAdmin`, with the region switched to **Europe (London)**.
3. Keep a PowerShell window open in `infrastructure/solution-a`, signed in,
   ready to run `.\lz-dev.ps1 down` at slide 9.
4. Have the recording of the 18 October run open and paused at the start,
   in case the live demo fails.

## Script

### 1. Secure foundation. Rebuilt from code.

*Jacob, about 30 seconds*

Hi, we're Team T235, and our industry partner is the Cyber Security Centre. In the next ten minutes: I'll cover what we were asked to build, Tim the design, Max a live demo and where we stand, and Khai how it's operated and the risks that remain. Then questions.

### 2. Cobble needs a foundation before it needs features

*Jacob, about 45 seconds*

Cobble is the Centre's proof-of-concept platform for hosting software for many customer organisations at once. Because those tenants share one platform, a weak foundation exposes all of them at once. The brief asked for eight deliverables, covering ten control areas and five risk themes: multi-tenancy, privileged access, API exposure, data protection and availability. And it had to be repeatable: deployed, torn down and rebuilt the same way every time. Our scope is the AWS foundation, not the Cobble application; a standard web server stands in for it.

### 3. Two solutions. One set of building blocks.

*Jacob, about 45 seconds*

We built two solutions from one set of Terraform modules. Solution B is the minimum viable product: one account, 48 resources, with encryption, an audit trail, threat detection and a budget alert. It costs about nothing because we tear it down between demos. Solution A is what the Centre would actually run: six accounts with guardrails, single sign-on, locked central logs and security monitoring, about 790 dollars a month with everything on. Because they share modules, B is a working slice of A, not a throwaway prototype. Tim will walk through A.

### 4. Six accounts, each with one job

*Tim, about 55 seconds*

Solution A splits the platform into six accounts, each with one job, following the AWS Security Reference Architecture. Management runs the organisation, sign-in and billing. Security holds the locked logs and the detection services. Shared services holds the container registry. Dev, staging and prod are separate accounts, so a mistake in dev can't reach prod. One simplification: a single Security account does the job of AWS's separate Log Archive and Security Tooling accounts, which halves the fixed cost. Inside each environment only the load balancer faces the internet; the web servers and database sit in private subnets.

### 5. Four guardrails hold, even for administrators

*Tim, about 50 seconds*

Four guardrails sit at the root of the organisation as service control policies, so they apply to every member account whoever signs in, administrators included. Stay in Australia. No root user. The security services can't be switched off. And no account can leave the organisation or close itself. On top of that, no one has a standing password or key: people sign in through IAM Identity Center with MFA, admin sessions last four hours, and GitHub deploys with short-lived roles. Max will show a guardrail refusing an administrator.

### 6. All ten control areas are built in code

*Tim, about 40 seconds*

All ten control areas in the brief are built in code. We mark each one as enforced, meaning a guardrail stops anyone turning it off, or configured, meaning the code builds it but an admin could still change it. We think being honest about that difference matters. The biggest gap is backups: there's no copy outside the account they protect yet. Over to Max.

### 7. The page is served by containers the internet can’t reach

*Max, about 45 seconds*

Here's Solution A running. Before the session I ran one command, lz-dev.ps1 up, which builds the security services and a dev environment in about 15 minutes. [Live: open the App address.] This is the dev app, a stand-in nginx page. It reaches you through the load balancer, from containers in private subnets with no public IP, and the database has no route to the internet at all. If anything fails live, we have a recording of the full run from 18 October.

### 8. Even an administrator is refused outside Australia

*Max, about 30 seconds*

Here I'm signed in as a full administrator in cobble-dev, and I try to create a bucket in London. It's refused: explicit deny in a service control policy. Even an admin can't take data out of Australia.

### 9. Everything that costs money came down with one command

*Max, about 45 seconds*

While it's up, every account reports to the Security account: GuardDuty, Security Hub and Config, with high and critical findings emailed to the team. [Live: run .\lz-dev.ps1 down.] And it comes down with one command. It removes 75 dev resources and 68 security resources in about ten minutes; I've just started it, so it finishes while we take questions. Its last check reads every account directly: GuardDuty, Security Hub and Config all off. The accounts, sign-in and guardrails are free, so they stay for next time.

### 10. Where we stand

*Max, about 45 seconds*

So where are we? Both solutions deploy and tear down from code, and the landing zone with dev now goes up and down with one command each way, recorded. Still in progress: the evidence log and screenshots, the Security Hub scores, the first backup restore test, and the shared services account, which waits on AWS's account limit. Running everything would cost about 790 Australian dollars a month, or 475 with dev and staging off when idle. Phase 2 closes the gaps: backups outside the account, alarms and dashboards, a break-glass role, and automatic deploys with approvals. Khai will cover how we work.

### 11. How the team operated

*Khai, about 40 seconds*

Design and build ran in parallel: one stream on the architecture, controls, operations, threat model and compliance documents, the other on the Terraform, both solutions, the checks and the runbooks. Every deliverable is a GitHub issue, and every change goes branch, pull request, automatic checks, one approving review, then merge. The checks format, validate, test and security-scan every change, and a nightly drift check flags anything changed outside the code.

### 12. Three risks to fix before real tenant data arrives

*Khai, about 45 seconds*

We rated thirteen threats with STRIDE. Three are High, and all three must be fixed before real tenant data arrives. Tenant isolation: today tenants are kept apart only by the application, so the fix is a database user and role per module. Admin access: one stolen admin session can change anything, so narrower roles and a break-glass role. Backups: no copy outside the account they protect, so AWS Backup to another account and region.

### 13. Reflection and what’s next

*Khai, about 40 seconds*

Honestly, we captured evidence late. Screenshots after our first demo showed setup gaps we hadn't checked, and the landing zone needed retries to deploy in order. We've since scripted the whole run, so it's one tested command each way, but next time we'd capture evidence as each step runs. Ready to hand over: both solutions, every change checked and reviewed, all eight deliverables drafted, and the Phase 2 gaps named and sequenced. We still need decisions from the Centre on the recovery region, the SQL Server edition and recovery targets. Thank you.

## Likely questions

The assessors' questions to Team T183 (26se1) were about a demo fallback,
team roles, and deployment. Ours are likely to be similar.

| Question | Answer | Who |
|---|---|---|
| If the live demo had failed, did you have a fallback? | Yes: a recording of the full run on 18 October, and the run logs in the repository. The script also picks up where it stopped if it's run again | Max |
| What were your roles, and why? | [Each presenter: one sentence on your role and why it suited you] | All |
| Could this run in the Centre's own AWS? | Yes, that's Phase 2. The same code deploys into their organisation with their settings files; it needs their accounts and a budget decision first | Max |
| How long does it take to deploy? | About 15 minutes up and 10 down for the landing zone with dev. The very first build, creating the accounts, took about half a day | Max |
| What keeps tenants apart today? | Only the application. That's High risk T1: the fix is a database user and role per module | Khai |
| How is the network separated? | Only the load balancer is public; web servers and the database sit in private subnets, and the database has no route to the internet (slides 17 and 21) | Tim |
| Why one Security account, not two? | It does the job of AWS's separate Log Archive and Security Tooling accounts with the same separation, at half the fixed cost (slide 25) | Tim |
| Why ECS and not Kubernetes? | The Implementation Guide recommends EKS only when the team can run Kubernetes day to day. ECS Fargate needs no cluster to look after (slides 19 and 25) | Tim |
| What if someone changes something by hand in the console? | A nightly drift check compares AWS with the code and flags the difference, and the guardrails stop anyone switching the security services off (slide 24) | Khai |
| How do people get access over time? | Through IAM Identity Center groups with MFA. Adding someone is one row in a file; what they can do in each account comes from their group (slide 18) | Tim |
| Is it compliant with the Essential Eight? | We mapped it to NIST CSF 2.0, the Essential Eight, ISO 27001 and SOCI: support, not certification. Maturity Level 1 is realistic once it's in the Centre's accounts and a restore is tested (slide 26) | Khai |
| What would it cost? | About A$790 a month with everything running, about A$475 with dev and staging off when idle (slide 23) | Max |

**Before closing:** Max shows the `down` output's final table: every column
`False`, `Dev app: not deployed`.
