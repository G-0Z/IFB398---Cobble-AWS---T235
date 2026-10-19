# Presentation script: 14 slides

The spoken script for [`Cobble-AWS-Platform.pptx`](Cobble-AWS-Platform.pptx):
**14 slides, including the title and Questions. About 9:30 of talk,
then 3 minutes of questions, 12:30 in all.** The same words are in each
slide's speaker notes, so presenter view shows them.

## How it's built

The talk tells one story rather than listing deliverables:

1. **Start with a person.** Wayne asked for something implementable, not a diagram.
2. **Give the reason for every choice.** Two solutions from one codebase, one Security account, ECS over Kubernetes.
3. **Use the method to find something.** The "could an admin turn it off?" test is what exposed the backup gap.
4. **Show, don't describe.** The demo comes as soon as the design is explained.
5. **Own the mistake.** Closing the accounts on 17 October, and how it changed the design.
6. **Say who did what.** Each presenter names their role and why it suited them.
7. **End confident.** What's ready to hand over, then thank you.

## Running order

| Slide | Title | Who | Starts | Length |
|---|---|---|---|---|
| 1 | Secure foundation. Rebuilt from code. | Jacob | 0:00 | 0:30 |
| 2 | Cobble needs a foundation before it needs features | Jacob | 0:30 | 0:50 |
| 3 | Two solutions. One set of building blocks. | Jacob | 1:20 | 0:45 |
| 4 | Six accounts, each with one job | Tim | 2:05 | 0:50 |
| 5 | Four guardrails hold, even for administrators | Tim | 2:55 | 0:45 |
| 6 | All ten control areas are built in code | Tim | 3:40 | 0:45 |
| 7 | The page is served by containers the internet can’t reach | Max | 4:25 | 0:45 |
| 8 | Even an administrator is refused outside Australia | Max | 5:10 | 0:30 |
| 9 | Everything that costs money came down with one command | Max | 5:40 | 0:50 |
| 10 | Where we stand | Max | 6:30 | 0:45 |
| 11 | Three risks to fix before real tenant data arrives | Khai | 7:15 | 0:45 |
| 12 | How the team operated | Khai | 8:00 | 0:45 |
| 13 | Reflection and what’s next | Khai | 8:45 | 0:45 |
| 14 | Questions? | All | 9:30 | 3:00 |

Every section fits its time at about 150 words a minute, leaving room for
clicks and the live demo. Rehearse with a timer: if a section runs long, cut
its last sentence, not the demo.

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

Hi, we're Team T235. Our industry partner is the Cyber Security Centre, and they're building Cobble: one platform that will host software for many customer organisations at once. I'll cover what we were asked for, Tim the design, Max a live demo and where we stand, and Khai how we work and what's left.

### 2. Cobble needs a foundation before it needs features

*Jacob, about 50 seconds*

When we first met Wayne at the Centre, he didn't ask for a diagram. He asked for something implementable: recommendations he could act on, issues written down, and a plan he could run in one month or three. That shaped everything we did. Cobble's tenants will share one platform, so a weak foundation doesn't expose one customer, it exposes all of them at once. The brief asks for eight deliverables, ten control areas and five risk themes. And one requirement drove the rest: it has to be repeatable, deployed, torn down and rebuilt the same way every time, from code. So our scope is the AWS foundation underneath Cobble, not the app itself.

### 3. Two solutions. One set of building blocks.

*Jacob, about 45 seconds*

That left us a choice: one full design that's expensive to run, or a cheap prototype that gets thrown away. We did neither. We wrote one set of Terraform modules and built two solutions from it. Solution B is the minimum viable product: one account, 48 resources, close to nothing to run because it's torn down between demos. Solution A is what the Centre would actually run: six accounts, guardrails, single sign-on and central security, about 790 dollars a month with everything on. Because they share code, B is a working slice of A, and a fix in one lands in both. Tim.

### 4. Six accounts, each with one job

*Tim, about 50 seconds*

Solution A gives each job its own account, following the AWS Security Reference Architecture. Management runs the organisation and sign-in. Security holds the audit logs and the threat detection, away from the people being logged. Shared services holds the container registry. And dev, staging and prod are separate, so a mistake in dev can't reach prod. We made one deliberate simplification: a single Security account does the work of AWS's two, which halves the fixed cost. Inside each environment, only the load balancer faces the internet; the web servers and database sit in private subnets.

### 5. Four guardrails hold, even for administrators

*Tim, about 45 seconds*

A policy in a document can be ignored. A service control policy can't. These four guardrails sit at the root of the organisation, so they apply in every account, to everyone, administrators included: stay in Australia, no root user, the security services can't be switched off, and no account can leave or close itself. And no one holds a standing password or key: people sign in through single sign-on with MFA, and admin sessions end after four hours.

### 6. All ten control areas are built in code

*Tim, about 45 seconds*

For each of the ten control areas we asked one question: could an administrator turn this off? If a guardrail stops them, we call it enforced. If the code builds it but an admin could still change it, we call it configured. That question is what showed us our biggest gap: backups have no copy outside the account they protect. Rather than describe any more of it, Max will show you.

### 7. The page is served by containers the internet can’t reach

*Max, about 45 seconds*

This is Solution A, running now. Before the session I ran one command, lz-dev.ps1 up, and about 15 minutes later the security services and a dev environment were built into accounts we keep. [Live: open the App address.] This page is a stand-in for Cobble. What matters is the path: it reaches you through the load balancer, from containers with no public address, and the database behind them has no route to the internet at all.

### 8. Even an administrator is refused outside Australia

*Max, about 30 seconds*

Here I'm a full administrator in the dev account, and I try to create a storage bucket in London. Refused: explicit deny in a service control policy. Even an admin can't take data out of Australia, which is exactly the guardrail Tim described.

### 9. Everything that costs money came down with one command

*Max, about 50 seconds*

Now the part we got wrong first. On 17 October we tore everything down, accounts included. Then we found a closed AWS account keeps counting against the organisation's limit for 90 days, so we couldn't simply rebuild. So we changed the design: accounts, sign-in and guardrails cost nothing, so they stay, and only what costs money comes and goes. [Live: run .\lz-dev.ps1 down.] One command removes 75 dev and 68 security resources in about ten minutes. I've just started it, so it finishes while we take questions.

### 10. Where we stand

*Max, about 45 seconds*

So where are we? Both solutions deploy and tear down from code, and the landing zone with dev now goes up and down with one command each way. We ran that cycle twice on 18 October and recorded the second. Running it again found two settings that changed on every apply, and we fixed both, which is exactly what repeatable is meant to catch. Still to do: a backup restore test and the last evidence. Next is Phase 2: the same code, deployed into the Centre's own accounts. Khai.

### 11. Three risks to fix before real tenant data arrives

*Khai, about 45 seconds*

Three risks stand between this and real tenant data. Tenant isolation: today only the application keeps tenants apart, so the fix is a database user and role per module. Admin access: one stolen admin session could change anything, so narrower roles and a break-glass role. Backups: no copy outside the account they protect, so AWS Backup to another account and region. We rated thirteen threats in all; these are the three High ones, and each has a named fix.

### 12. How the team operated

*Khai, about 45 seconds*

On how we worked: each of us owned a part of today. Jacob led the definition; Tim the design; Max the build, the demo and the plans; and I led operations. [Each of us: one sentence on why that role suited you.] Design and build ran side by side, so the documents and the code shaped each other. Every change went through a pull request, automatic checks and one teammate's review before it merged. And when we departed from the Implementation Guide, like choosing ECS over Kubernetes, we wrote down why, and what would make us change our minds.

### 13. Reflection and what’s next

*Khai, about 45 seconds*

If we did it again, we'd capture evidence as each step runs. We took screenshots after our first demo, and they showed setup gaps we hadn't checked; the landing zone also needed retries to deploy in order. Scripting the whole run fixed both, but we'd do it from day one. Here's what's ready to hand over: two solutions that deploy and tear down from code, every change checked and reviewed, all eight deliverables drafted, and the Phase 2 work named and in order. With that, we're in a strong position to put Cobble's foundation into the Centre's hands. Thank you.

## Likely questions

| Question | Answer | Who |
|---|---|---|
| If the live demo had failed, what was your fallback? | A recording of the full run on 18 October, and the run logs in the repository. The script also picks up where it stopped if it's run again | Max |
| What were your roles, and why? | [Each presenter: your section, and one sentence on why it suited you] | All |
| Could this run in the Centre's own AWS? | Yes, that's Phase 2. The same code deploys into their organisation with their settings files; it needs their accounts and a budget decision first | Max |
| How long does it take to deploy? | About 15 minutes up and 10 down for the landing zone with dev. The very first build, creating the accounts, took about half a day | Max |
| What keeps tenants apart today? | Only the application. That's a High risk: the fix is a database user and role per module | Khai |
| How is the network separated? | Only the load balancer is public; web servers and the database sit in private subnets, and the database has no route to the internet (slides 17 and 21) | Tim |
| Why one Security account, not two? | It does the work of AWS's separate Log Archive and Security Tooling accounts with the same separation, at half the fixed cost (slide 25) | Tim |
| Why ECS and not Kubernetes? | The Implementation Guide recommends EKS only when the team can run Kubernetes day to day. ECS Fargate needs no cluster to look after (slides 19 and 25) | Tim |
| What if someone changes something by hand in the console? | A nightly drift check compares AWS with the code and flags the difference, and the guardrails stop anyone switching the security services off (slide 24) | Khai |
| How do people get access over time? | Through IAM Identity Center groups with MFA. Adding someone is one row in a file; what they can do in each account comes from their group (slide 18) | Tim |
| Is it compliant with the Essential Eight? | We mapped it to NIST CSF 2.0, the Essential Eight, ISO 27001 and SOCI: support, not certification. Maturity Level 1 is realistic once it's in the Centre's accounts and a restore is tested (slide 26) | Khai |
| What would it cost? | About A$790 a month with everything running, about A$475 with dev and staging off when idle (slide 23) | Max |

**Before closing:** Max shows the `down` output's final table: every column
`False`, `Dev app: not deployed`.
