# Cobble AWS Platform

**IFB398 Capstone · P608 / R014.1 · Tutorial group T235** · Industry partner: Cyber Security Centre

Cobble is the Cyber Security Centre's proof-of-concept platform for hosting
software for many customer organisations at once. This project builds the
secure AWS foundation it runs on: the accounts, network, sign-in, logging
and security controls. Everything is written as code (Terraform), so it can
be deployed, torn down and rebuilt the same way every time.

The Cobble application itself is out of scope. Where an application is
needed to prove the platform works, a standard web server stands in for it.

## Two solutions

We deliver the same platform at two levels of completeness. Both can be
deployed into AWS, shown in the console, and torn down again.

| | **Solution B: minimum viable product** | **Solution A: full landing zone** |
|---|---|---|
| In one line | The smallest secure version of the platform | The complete design we'd recommend for production |
| AWS accounts | 1 | 6: management, security, shared services, dev, staging, prod |
| What you can see running | Encryption, audit logging, threat detection, a private network, a budget alert | All of B, plus web servers in private subnets behind a load balancer, a private database, auto scaling and a web firewall |
| Extra security | | Guardrails no one can switch off, single sign-on, tamper-proof audit logs, central security monitoring |
| Cost (AUD) | About A$0 (deployed only for demos) | Demo: about A$0.35 an hour with the landing zone and dev (A$0.22 for the workload alone). Everything running: about A$790 a month |
| Code | [`infrastructure/solution-b/`](infrastructure/solution-b/) | [`infrastructure/solution-a/`](infrastructure/solution-a/) |

Solution B can be shown working today for almost nothing. Solution A is what
the Cyber Security Centre would actually run. Both are built from the same
building blocks, so B is a working slice of A rather than a separate
prototype.

## See it working

You need Terraform, the AWS CLI and a sign-in to the team's AWS account.
[runbooks/README.md](runbooks/README.md) has the full steps.

**The demo we show is Solution A's landing zone with a dev environment**,
built and removed with one command each way
([quickstart](runbooks/demo-landing-zone-quickstart.md)):

```powershell
cd infrastructure/solution-a
.\lz-dev.ps1 up       # about 15 minutes: security services + dev, in the existing accounts
.\lz-dev.ps1 status   # what's running in each account
.\lz-dev.ps1 down     # about 10 minutes: back to A$0 an hour. Accounts and guardrails stay
```

Solution B, and Solution A's workload on its own, run straight from Terraform:

```powershell
# Solution B: about 5 minutes, 48 resources
cd infrastructure/solution-b
terraform init
terraform apply
terraform destroy          # when you're done

# Solution A's workload in the same account: about 15 minutes, 66 resources
cd infrastructure/solution-a/workload
terraform init -reconfigure -backend-config="key=solution-a/workload/demo/terraform.tfstate"
terraform apply  -var-file="demo.tfvars"
terraform destroy -var-file="demo.tfvars"
```

Running the same commands again rebuilds exactly the same thing. That's the
point of the project: a platform you can deploy and redeploy with
confidence.

## Find your way around

| I want to... | Go to |
|---|---|
| Read a capstone deliverable (architecture, threat model, compliance...) | [docs/](docs/README.md) |
| Deploy, demo or tear down a solution | [runbooks/](runbooks/README.md) |
| Understand what the code builds and why | [infrastructure/](infrastructure/README.md) |
| Look up a term (landing zone, SCP, state...) | [Glossary](docs/glossary.md) |

```
.
├── docs/             The eight capstone deliverables, glossary and naming guide
├── infrastructure/   The Terraform code
│   ├── bootstrap/        the storage bucket Terraform keeps its records in (set up once)
│   ├── solution-b/       Solution B
│   ├── solution-a/       Solution A: workload/ (one environment) and landing-zone/
│   └── modules/          building blocks shared by both solutions
├── runbooks/         Step-by-step instructions
└── .github/          Automatic checks on every change, and a nightly drift check
```

## What Solution B leaves out, and how Solution A fills the gap

Solution B keeps cost near zero by simplifying. Each simplification is
deliberate, and Solution A shows the full answer.

| Solution B simplifies... | Solution A instead has... |
|---|---|
| Everything in one account | Six accounts, so a mistake in dev can't reach prod |
| Audit logs deleted when it's torn down | Audit logs in a separate account, locked against deletion |
| No outbound internet from the private network | A NAT gateway for outbound traffic (one per zone in prod) |
| One encryption key for everything | A separate key in each account |
| Team members sign in as IAM users | Single sign-on through IAM Identity Center |
| Automatic checks, but deploys are run by hand | Read-only roles for checks, and deploys that need a reviewer's approval |

## Status

In progress. Both solutions deploy, tear down and redeploy in AWS, and every
change is checked automatically.

- **Solution A, landing zone + dev:** deployed and removed twice on 18 October 2026, and the second cycle was recorded. Each `up` adds 68 security resources and 75 in dev; each `down` removes the same 143. The 4 Cobble accounts, sign-in and guardrails stay between runs. [Logs](infrastructure/solution-a/evidence/)
- **Solution A, workload only:** 66 resources in one account.
- **Solution B:** 48 resources in one account.

The status of each deliverable is in [docs/README.md](docs/README.md).
