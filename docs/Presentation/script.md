# Presentation script

The speaking script for [`Cobble-AWS-Platform.pptx`](Cobble-AWS-Platform.pptx),
the current 19-slide deck. It's a copy of
[`T235-presentation-script.docx`](T235-presentation-script.docx) (20 October
2026), kept here so it can be read on GitHub. If the two ever differ, the
Word file is the master.

| Slides | Presenter |
|---|---|
| 1 to 4 | Jacob |
| 5 to 8 | Tim |
| 9 to 14 | Max |
| 15 to 18 | Khai |
| 19 | All |

About 2,400 words: roughly 16 minutes at 150 words a minute, before
questions.

## Script

### 1. Secure foundation. Rebuilt from code. (Jacob)

The Cyber Security Centre is building Cobble: one platform that will
host software for many customer organisations at once. And if the
foundation underneath it is weak, every one of those customers is
exposed at the same time.

### 2. What is Cobble? (Jacob)

So what is Cobble? It's a research platform from the Cyber Security
Centre: a proof of concept for hosting software as a service, where many
customer organisations, called tenants, share one platform.

It's built from modules. The application plane is the shell users sign
in to. The administrative plane runs the platform itself: tenancies,
installing and versioning modules, and logging. And the user modules are
the features tenants actually use, like member management.

Every module ships on its own: its own screen, its own API and its own
data, so one can be updated, rolled back or switched off without
touching the others. Twenty modules means twenty services.

We weren't asked to build those modules. We were asked to build the
secure AWS foundation they'll run on.

### 3. Cobble needs a foundation before it needs features (Jacob)

When we first met Wayne Wood at the Centre, he didn't ask us for a
diagram. He asked for something he could implement: recommendations he
could act on, problems and their fixes written down, and a plan he could
run in one month or in three. That request shaped every decision we
made.

Here's why it matters. Cobble's tenants will share one platform. If the
foundation underneath is weak, it doesn't expose one customer, it
exposes all of them at once. So the brief asked for eight deliverables,
covering ten security control areas and five risk themes.

The Centre also gave us its Implementation Guide, seventeen sections
from the landing zone through to the runbooks, and we used it as our
target design. And one requirement drove everything else: it has to be
repeatable. Deployed, torn down and rebuilt the same way every time,
from code, not from someone clicking through a console.

So our scope is the AWS foundation underneath Cobble, not the Cobble
application itself. Where we need an app to prove the platform works, a
standard web server stands in for it.

### 4. Two solutions. One set of building blocks. (Jacob)

That left us with a choice: one full production design that's expensive
to keep running, or a cheap prototype that gets thrown away. We did
neither. We wrote one set of Terraform building blocks and built two
solutions from them.

Solution B is the minimum viable product. It's a single account with 48
resources: encryption, an audit trail, threat detection and a budget
alert. It costs close to nothing, because we tear it down between demos.

Solution A is what the Centre would actually run: six accounts,
guardrails, single sign-on and central security monitoring, at about 790
Australian dollars a month with everything switched on.

Because the two share the same code, Solution B is a working slice of
Solution A, not a throwaway, and a fix in one lands in both. So what
does Solution A actually look like?

### 5. Six accounts, each with one job (Tim)

Solution A gives each job its own AWS account, following the AWS
Security Reference Architecture. At the top, the management account runs
the organisation, sign-in and billing, and nothing else.

The Security account holds the audit logs and runs threat detection,
deliberately kept away from the people whose actions are being logged.
Shared services holds the container registry. Then dev, staging and prod
are separate accounts, so a mistake made in dev simply can't reach
production or tenant data.

We made one deliberate simplification. AWS suggests two security
accounts, one for logs and one for tooling. We combined them into one,
which halves the fixed cost while still keeping the logs away from the
workloads.

Inside each environment the network has three layers: only the load
balancer faces the internet, the web servers sit in private subnets
behind it, and the database sits in a third layer with no route out at
all.

### 6. One request, from the internet to the database (Tim)

This is the target architecture from the Centre's Implementation Guide,
the one every workload account is built towards. Follow one request. It
comes in at the edge: Route 53, then CloudFront with a web firewall, and
static pages come from a private storage bucket. API calls go through
API Gateway to a load balancer that isn't on the internet at all. Behind
it, containers on Fargate run in private subnets and fetch their secrets
at start-up. And the database sits in an isolated subnet with no route
out, reachable only through stored procedures.

Our proof of concept builds the inner part today: the load balancer, the
private containers and the private, encrypted database. The edge and API
Gateway need a domain name first, so they're Phase 2.

### 7. Four guardrails hold, even for administrators (Tim)

A security rule written in a document can be ignored. A service control
policy can't. These four guardrails are attached at the root of the
organisation, so they apply to every member account and everyone in it,
administrators included.

One: stay in Australia. Resources can only be created in Sydney, plus
the one US region AWS needs for global services. Two: no root user.
Three: the security services stay on, so nobody can switch off
CloudTrail, GuardDuty, Config, Security Hub or Access Analyzer. And
four: no account can leave the organisation.

On top of that, nobody holds a standing password or access key. People
sign in through single sign-on with multi-factor authentication, and
admin sessions end after four hours.

### 8. All ten control areas are built in code (Tim)

The brief named ten control areas, and all ten are built in code. For
each one we asked a simple question: could an administrator turn this
off?

If a guardrail stops them, we call the control enforced: that's access,
logging and monitoring. If the code builds it but an admin could still
change it, we call it configured, like encryption, network separation,
secrets and backups. We chose those two words on purpose, because
calling something enforced when it's only configured would mislead a
security centre.

That question is also how we found our biggest gap: the backups have no
copy outside the account they protect, so one compromised account could
lose the data and its backups together. That's on our Phase 2 list. The
best evidence for everything else is watching it run.

### 9. Built, checked and torn down from code (Max)

[The video starts by itself. Keep pace with its captions.]

[0:00] This is our recorded run from 18 October, cut down to two
minutes. It starts with one command: lz-dev.ps1 up.

[0:06] This part is sped up sixty times. In about fifteen minutes it
builds 68 security resources and 75 in dev, into accounts we keep
between runs. When it finishes, it prints the app's address.

[0:24] This page stands in for Cobble. What matters is the path: it
reaches you through the load balancer, from containers with no public
address.

[0:30] Here's the organisation, each account in its folder, [0:36]
and the four guardrails Tim described, attached to every account.
[0:42] The organisation-wide audit trail, stored in the Security
account. [0:48] Single sign-on: three groups, each with its own role.

[0:54] Security Hub checks every account against the security
standards, [1:00] and Config records every change, all collected in
one place.

[1:06] In dev: the network in three layers, [1:12] the web servers
running in private subnets, [1:18] and the data bucket, encrypted,
with public access blocked.

[1:24] Now the guardrail test. I'm a full administrator, and I try to
create a bucket in London. Refused: explicit deny in a service control
policy. Even an admin can't take data out of Australia. [1:30] And a
read-only user gets no access to the Security account at all.

[1:36] Every change to this code goes through GitHub's automatic
checks before it merges.

[1:42] Finally, one command takes it down. About ten minutes later,
everything that costs money is gone: every account reads False. The
accounts, sign-in and guardrails stay, so the next run rebuilds the same
thing. We learned that the hard way: the first time, we closed the
accounts, and AWS counts closed accounts against the limit for 90 days.
[The video holds on the final table; finish this, then click.]

### 10. How we planned Phase 1 (Max)

Before Phase 2, here's how we planned Phase 1. We ran six two-week
sprints on a GitHub project board, each with one goal: set up the
repository and workflow, research the services and pricing, meet the
Centre and scope the deliverables, build both solutions in Terraform,
deploy the landing zone with the demo and this deck, and finally finish
the deliverables.

Both our sprint plan and our issues register live in GitHub. On the left
is the sprint plan: every deliverable is an issue with an owner, a
priority, a size and dates, sitting in its sprint. On the right is the
issues register: thirteen done, and this presentation in progress. Every
change went through a pull request, nineteen merged so far, so the plan
and the code stay linked.

### 11. Where we stand (Max)

So where do we stand? Done: both solutions deploy and tear down from
code, one command each way. The landing zone, guardrails and sign-in are
built, along with central logging and detection, automatic checks on
every change and a nightly drift check.

We ran the full cycle twice on 18 October and recorded the second run.
Running it again picked up two settings that changed on every deploy,
and we fixed both, which is exactly what testing for repeatability is
meant to catch.

In progress: the last evidence, the Security Hub scores, the shared
services account, which is waiting on an AWS account limit, and our
first backup restore test. Phase 2 then closes the gaps: backups outside
the account, application alarms, a break-glass role with narrower admin
roles, and automatic deploys with approvals. But where that work lands
is the Centre's call.

### 12. Phase 2 is the Centre's decision to make (Max)

Phase 2 starts with a decision only the Centre can make: how they want
their platform configured. Phase 1 gives them three options.

Option one: Solution A, the full landing zone, deployed into their own
AWS organisation. About 790 dollars a month with everything on.

Option two: start small. Solution B in one of their accounts, close to
nothing to run, growing into Solution A when real tenants arrive. Same
code, so nothing is thrown away.

Option three: review the platform they run on DigitalOcean today, then
choose option one or two with that evidence. That one needs development
approval to review their DigitalOcean platform, which we don't have yet.

So the first step next semester is to re-confirm the scope with the
Centre and ask for that access. They choose an option and sign off the
Phase 2 plan and business case, and then we build.

### 13. Going forward in IFB399 (Max)

Here's how we go forward into IFB399 next semester. The team re-forms in
Welcome Week, on 15 February. After that, most dates are still to be
confirmed, because they depend on the Centre and on the unit. We meet
the Centre to re-align the scope, and ask for development approval to
review their DigitalOcean platform. We meet the unit coordinator to
confirm the IFB399 deliverables. We revise our sprint plan to fit. And
the Centre decides how they want Phase 2 configured, and signs off the
plan and business case.

Our goal date is the end of teaching, 28 May, with the platform ready to
hand over.

### 14. Why this plan is feasible (Max)

Why is this plan realistic? Three reasons. First, it's already running.
You've just watched both solutions deploy and tear down from code, so
Phase 2 extends a working platform; it doesn't start again. Second, the
work is named and ordered: we rated thirteen threats, and each of the
three High ones has a named fix. Third, the Centre's decision can't
stall us, because the same modules serve whichever option they choose.

We've also rated the risks to the plan itself. The two Very important
ones both depend on the Centre. If the DigitalOcean access isn't
approved, we keep building and leave the review as a recommendation. If
their decision takes time, the same modules serve every option. That's
why we raise both first, at the re-alignment meeting.

### 15. Three risks to fix before real tenant data arrives (Khai)

The plan also has to close the threats we found. We rated thirteen using
STRIDE, and three of them are High. They're the three things to fix
before any real tenant data goes in.

First, tenant isolation. Today only the application keeps tenants apart,
because they share the same servers and database. The fix is a separate
database user and role for each module.

Second, admin access. One stolen admin session could change anything in
that account, so the fix is narrower roles, plus a break-glass role that
raises an alarm whenever it's used.

Third, backups. As Tim said, there's no copy outside the account they
protect, so the fix is AWS Backup copying to another account and region.
The other ten threats are Medium or Low, which is acceptable for a proof
of concept.

### 16. Team members (Khai)

Here's who we are. Jacob led the definition: the brief, the requirements
and the scope. Tim led the design: the landing zone, the controls and
the project's risks. Max managed the project and led the build, the demo
and the plans. And I led operations: how the platform is deployed,
monitored, backed up and supported.

[Each of us: one sentence on why that role suited you.]

Next semester we keep to our strengths: Jacob on the client side and the
sign-offs, Tim on security, Max on the plan and the build, and me on
operations and the handover.

### 17. How the team operated (Khai)

On how we worked: design and build ran side by side, so the documents
and the code shaped each other. As you saw, everything was tracked in
GitHub, and every change went through a branch, a pull request and
automatic checks before it merged. We met weekly on Discord, and met
Wayne at the Centre twice.

When we departed from the Implementation Guide, for example choosing ECS
on Fargate over Kubernetes, we wrote down why, and what would make us
change our minds.

### 18. Reflection and what's next (Khai)

If we did it again, we'd capture evidence as each step runs. We took our
screenshots after the first demo, and they showed setup gaps we hadn't
checked; the landing zone also needed retries to deploy in the right
order. Scripting the whole run fixed both, but we'd do that from day
one. We'd also make a teammate's review required on every merge, which
is how Phase 2 will run.

Here's what's ready to hand over: two solutions that deploy and tear
down from code, every change checked, all eight deliverables drafted,
and the Phase 2 work named and in order. Thank you. We're happy to take
your questions.

### 19. Questions? (All)

Questions. Answer the ones in your own area; the likely questions and
answers are in the script document.

## Likely questions

| Question | Answer | Who |
|---|---|---|
| If the live demo had failed, what was your fallback? | A recording of the full run on 18 October, and the run logs in the repository. The script also picks up where it stopped if it's run again | Max |
| What were your roles, and why? | [Each presenter: your section, and one sentence on why it suited you] | All |
| Could this run in the Centre's own AWS? | Yes, that's Phase 2. The same code deploys into their organisation with their settings files; it needs their accounts and a budget decision first | Max |
| How long does it take to deploy? | About 15 minutes up and 10 down for the landing zone with dev. The very first build, creating the accounts, took about half a day | Max |
| What keeps tenants apart today? | Only the application. That's a High risk: the fix is a database user and role per module | Khai |
| How is the network separated? | Only the load balancer is public; web servers and the database sit in private subnets, and the database has no route to the internet | Tim |
| Why one Security account, not two? | It does the work of AWS's separate Log Archive and Security Tooling accounts with the same separation, at half the fixed cost | Tim |
| Why ECS and not Kubernetes? | The Implementation Guide recommends EKS only when the team can run Kubernetes day to day. ECS Fargate needs no cluster to look after | Tim |
| What if someone changes something by hand in the console? | A nightly drift check compares AWS with the code and flags the difference, and the guardrails stop anyone switching the security services off | Khai |
| How do people get access over time? | Through IAM Identity Center groups with MFA. Adding someone is one row in a file; what they can do in each account comes from their group | Tim |
| Is it compliant with the Essential Eight? | We mapped it to NIST CSF 2.0, the Essential Eight, ISO 27001 and SOCI: support, not certification. Maturity Level 1 is realistic once it's in the Centre's accounts and a restore is tested | Khai |
| What would it cost? | About A$790 a month with everything running, about A$475 with dev and staging off when idle | Max |

**Before closing:** Max shows the `down` output's final table: every column
`False`, `Dev app: not deployed`.
