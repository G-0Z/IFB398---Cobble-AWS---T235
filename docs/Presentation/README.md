# Deliverable 8: Stakeholder presentation

The presentation of the AWS platform for the Cyber Security Centre: what was
built, why, what risk remains, and what comes next.

## Files

| File | What it is |
|---|---|
| [`Cobble-AWS-Platform.pptx`](Cobble-AWS-Platform.pptx) | **The current deck:** 19 slides, last saved 20 October 2026 |
| [`T235-presentation-script.docx`](T235-presentation-script.docx) | The speaking script for that deck, slide by slide. [`script.md`](script.md) is a copy you can read on GitHub |
| [`T235-presentation-synopsis.pdf`](T235-presentation-synopsis.pdf) | The presentation synopsis |

The script runs to about 2,400 words: roughly 16 minutes at 150 words a
minute, before questions. Rehearse with a timer.

## Slide by slide

| Slide | Title | Presenter | Backed up by |
|---|---|---|---|
| 1 | Secure foundation. Rebuilt from code. | Jacob | |
| 2 | What is Cobble? | Jacob | Project brief |
| 3 | Cobble needs a foundation before it needs features | Jacob | Project brief; the Implementation Guide |
| 4 | Two solutions. One set of building blocks. | Jacob | [Key decisions](../02-landing-zone-design/README.md#key-decisions) |
| 5 | Six accounts, each with one job | Tim | [Deliverable 2](../02-landing-zone-design/README.md#accounts) |
| 6 | One request, from the internet to the database | Tim | [Deliverable 1](../01-reference-architecture/README.md) |
| 7 | Four guardrails hold, even for administrators | Tim | [Guardrails](../02-landing-zone-design/README.md#guardrails) |
| 8 | All ten control areas are built in code | Tim | [Deliverable 3](../03-security-controls/README.md) |
| 9 | Built, checked and torn down from code | Max | [Evidence log](../Evidence/README.md#evidence-log) |
| 10 | How we planned Phase 1 | Max | [Sprint plan](../Sprint%20Plans/IFB398-T235-Sprint%20Plan-Phase%201%20and%202.md) |
| 11 | Where we stand | Max | [Deliverables](../README.md) |
| 12 | Phase 2 is the Centre's decision to make | Max | [Phase 2 roadmap](../phase-2-roadmap.md#the-three-options) |
| 13 | Going forward in IFB399 | Max | [Phase 2 schedule](../phase-2-roadmap.md#schedule) |
| 14 | Why this plan is feasible | Max | [Risks to the plan](../phase-2-roadmap.md#risks-to-the-plan) |
| 15 | Three risks to fix before real tenant data arrives | Khai | [Deliverable 6](../06-threat-model/README.md) |
| 16 | Team members | Khai | |
| 17 | How the team operated | Khai | [Project records](../README.md#project-records) |
| 18 | Reflection and what's next | Khai | [Gaps](../02-landing-zone-design/README.md#gaps) |
| 19 | Questions? | All | [Likely questions](script.md#likely-questions) |

## Demo script

The demo is Solution A's landing zone with a dev environment, in the same
order as the run recorded on 18 October 2026. Setup is in the
[quickstart](../../runbooks/demo-landing-zone-quickstart.md).

**Before the session (about 15 minutes):** sign in and run
`.\lz-dev.ps1 up` in `infrastructure/solution-a`. It ends with
`Up. App: http://…`. Open the access portal and set every console tab to
**Asia Pacific (Sydney)**.

1. **The app.** Open the `App:` address. The nginx page comes from containers
   in **private** subnets, reached only through the load balancer.
2. **The organisation** (management account). Organizations > AWS accounts:
   the folders, each with its account. Policies > Service control policies:
   the 4 guardrails attached to Root.
3. **Sign-in.** The access portal lists the 5 accounts. IAM Identity Center >
   Permission sets: `CobblePlatformAdmin`, `CobbleDeveloper`, `CobbleReadOnly`.
   Clicking `CobbleReadOnly` on `cobble-security` as a platform admin gives
   "No access": you only get the roles your group is given.
4. **Central security** (`cobble-security`, `CobblePlatformAdmin`). S3: the
   audit log buckets. CloudTrail: the organisation trail. GuardDuty >
   Accounts: the other Cobble accounts enrolled. Security Hub: the
   standards. Config > Aggregators: every account.
5. **The workload** (`cobble-dev`, `CobblePlatformAdmin`). VPC: subnets in
   three layers. ECS: the service and its tasks, private IPs only. RDS: not
   publicly accessible, encrypted. S3: the encrypted data bucket. Billing:
   the cost so far.
6. **Optional: a guardrail refusing an admin.** In `cobble-dev`, switch to a
   region outside Australia and try to create an S3 bucket: "explicit deny in
   a service control policy".
7. **Tear down.** Run `.\lz-dev.ps1 down` (about 10 minutes). Its final table
   reads `False` for GuardDuty, Security Hub and Config in every account:
   nothing left billing. The accounts stay, and `up` rebuilds the same thing.

Solution B can be shown alongside it: see [deploy-solution-b.md](../../runbooks/deploy-solution-b.md).

> [!TIP]
> **If the live run fails,** play the recording of the 18 October run (40
> minutes cut to 20, with the build and teardown at 12x speed):
> `docs/Evidence/video/solution-a-demo.mp4`. Videos are git-ignored because
> of their size, so bring it on the presenting laptop. Its logs are
> [up](../../infrastructure/solution-a/evidence/lz-dev-up-20261018-2147.txt)
> and [down](../../infrastructure/solution-a/evidence/lz-dev-down-20261018-2219.txt).
