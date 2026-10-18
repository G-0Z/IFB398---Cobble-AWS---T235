# Deliverable 8: Final stakeholder presentation

A concise presentation of the AWS platform design for the Cyber Security
Centre: what was built, why the key decisions were made, what risk
remains, and what to do next. The deck is in [`deck/`](deck/).

## Suggested outline (about 15 minutes plus a 5-minute demo)

| # | Slide | Content | Source |
|---|---|---|---|
| 1 | The problem | Platforms fail on weak foundations, not weak ideas; Cobble needs a secure, repeatable AWS base | Project brief |
| 2 | Two solutions | Solution B (one account, about A$0) and Solution A (six accounts, the full design). Both deploy and tear down from code; B is a working slice of A | [Key decisions](../02-landing-zone-design/README.md#key-decisions) |
| 3 | Reference architecture | One diagram: accounts, network zones, data path | [Deliverable 1](../01-reference-architecture/README.md) |
| 4 | Landing zone | OUs and accounts; who can do what; the four guardrails | [Deliverable 2](../02-landing-zone-design/README.md) |
| 5 | Security controls | The ten areas in one table, with what's enforced vs configured | [Deliverable 3](../03-security-controls/README.md) |
| 6 | Live demo | Deploy, show and tear down (see below) | [Deliverable 4](../04-iac-evidence/README.md) |
| 7 | How it's run | Deploy pipeline, monitoring, patching, backups, who's responsible | [Deliverable 5](../05-deployment-operations/README.md) |
| 8 | Top risks | The three High threats: tenant isolation, admin access, backups | [Deliverable 6](../06-threat-model/README.md) |
| 9 | Compliance | NIST CSF 2.0 / Essential Eight / ISO 27001 coverage and what's out of scope | [Deliverable 7](../07-compliance-mapping/README.md) |
| 10 | Where we differ from the Guide, and why | PostgreSQL for now; a load balancer with a web firewall for now; ECS instead of Kubernetes | [Key decisions](../02-landing-zone-design/README.md#key-decisions) |
| 11 | Cost | B near A$0; A about A$790 a month, about A$475 with dev and staging off | [Cost estimate](../../infrastructure/README.md#what-it-costs) |
| 12 | Next steps | Deploy Solution A's landing zone into the client's organisation; off-account backups; alarms; a break-glass role; automatic deploys | [Gaps](../02-landing-zone-design/README.md#gaps), [operations gaps](../05-deployment-operations/README.md#8-gaps-and-next-steps) |

## Demo script

The demo is Solution A's landing zone with a dev environment, in the
order of the run recorded on 18 October 2026. Follow the
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
6. **Optional, a guardrail refusing an admin.** In `cobble-dev`, switch to a
   region outside Australia and try to create an S3 bucket: "explicit deny in
   a service control policy".
7. **Tear down.** Run `.\lz-dev.ps1 down` (about 10 minutes). Its final table
   reads `False` for GuardDuty, Security Hub and Config in every account:
   nothing left billing. The accounts stay, and `up` rebuilds the same thing.

Solution B can be shown alongside: deploy it first with
[deploy.md](../../runbooks/deploy.md) and tear it down with
[teardown.md](../../runbooks/teardown.md).

**Fallback:** if the live run fails, play the recording of the 18 October
run (40 minutes cut to 20, with the build and teardown at 12x speed). The
logs from that run are
[up](../../infrastructure/solution-a/evidence/lz-dev-up-20261018-2147.txt) and
[down](../../infrastructure/solution-a/evidence/lz-dev-down-20261018-2219.txt).
