# Deliverable 8: Final stakeholder presentation

A concise presentation of the AWS platform design for the Cyber Security
Centre: what was built, why the key decisions were made, what risk
remains, and what to do next. The deck itself goes in this folder when it's
ready.

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

Deploy both solutions **before** the session, because Solution A takes about
15 minutes. Follow [deploy.md](../../runbooks/deploy.md), then
[demo-solution-a.md](../../runbooks/demo-solution-a.md).

1. Show the green automatic checks on `main`: every folder formatted,
   validated, tested and security-scanned.
2. **Solution B** in the console: the encryption key, the audit trail
   (CloudTrail) and threat detection (GuardDuty) switched on, and the budget
   alert.
3. **Solution A**: open `terraform output app_url`. The page comes from web
   servers in **private** subnets that the internet can't reach directly.
4. In the console: the web server has no public IP; the database says
   "Publicly accessible: No"; the data bucket is encrypted.
5. Run `terraform plan -detailed-exitcode` and show it returns 0: what's
   running matches the code exactly.
6. After the session, tear down (Solution A first, then B) and mention that
   running the same commands again rebuilds the identical platform.

Keep screenshots of each step as a fallback in case the live demo fails.
