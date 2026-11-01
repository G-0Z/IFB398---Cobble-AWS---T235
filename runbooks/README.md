# Runbooks

Step-by-step instructions for deploying, demoing and tearing down the
platform. Each one is written so that someone who didn't write the code can
follow it from start to finish.

## Which runbook do I need?

| I want to... | Runbook | Time |
|---|---|---|
| **Run the demo we show:** Solution A's landing zone with dev, up and down with one command each | [demo-landing-zone-quickstart.md](demo-landing-zone-quickstart.md) | 15 min up, 10 down |
| Show Solution B, then remove it | [deploy-solution-b.md](deploy-solution-b.md) | 5 min each way |
| Show Solution A's workload in one account, then remove it | [demo-solution-a.md](demo-solution-a.md) | 15 min each way |
| Prove a solution redeploys identically | [deploy-solution-b.md, Redeploy](deploy-solution-b.md#redeploy-the-repeatability-check) | |
| Create the state bucket (only if it's missing) | [bootstrap.md](bootstrap.md) | A few minutes, once |
| Run the landing zone demo by hand, take the evidence screenshots, or close the accounts at the end of the project | [demo-landing-zone-dev.md](demo-landing-zone-dev.md) | Half a day |
| Build the full six-account landing zone, with staging and prod | [deploy-solution-a.md](deploy-solution-a.md) | Half a day, plus an hour per environment |

For when something goes wrong in a running platform (an outage, a database
failure, stolen credentials, drift, the web firewall blocking real users, a
cost spike), see the
[incident runbooks](../docs/deliverables/deployment-operations.md#6-runbooks).

## What you need

- [Terraform](https://developer.hashicorp.com/terraform/install) 1.10 or later
- The [AWS CLI](https://aws.amazon.com/cli/)
- A sign-in to the team's AWS account: see [deploy-solution-b.md](deploy-solution-b.md#sign-in)

## A typical demo day

The 18 October 2026 recording is steps 1 and 4, with the console tour in
between:

```text
1. quickstart   .\lz-dev.ps1 up     Solution A: landing zone + dev       about 15 min
2. solution-b   terraform apply     Solution B, if showing it too        about 5 min
                ... the app, then the console tour (quickstart step 3) ...
3. solution-b   terraform destroy   Solution B first, if deployed
4. quickstart   .\lz-dev.ps1 down   Solution A                           about 10 min
```

The two solutions don't depend on each other, so either can be shown on its
own.

## Check nothing is left running

| After tearing down | It's clean when |
|---|---|
| Solution B | `terraform plan` offers to create all 48 resources again |
| Solution A workload demo | `terraform plan -var-file="demo.tfvars"` offers to create all 66 again |
| Landing zone demo | `.\lz-dev.ps1 status` reads `False` in every column and `Dev app: not deployed` |

Then check the AWS console for leftover VPCs, load balancers, ECS clusters
or databases, and look at Billing the next day for any new spend.

## Things that can block a clean teardown

| Blocker | What happens | What to do |
|---|---|---|
| Encryption keys | AWS waits 7 to 30 days before deleting a key, and bills for it until then | Expected. A redeploy creates a new key |
| Locked audit logs (landing zone) | In "governance" mode an admin can remove the lock. In "compliance" mode **nobody can, not even the root user,** until the date passes | Keep governance mode. Never use compliance mode in a student or demo account |
| AWS accounts (landing zone) | They're protected, so `terraform destroy` doesn't remove them. Closed accounts linger for 90 days and still count towards the account limit | Keep them between demos. Close them only at the end of the project |
| The state bucket | Not removed by any teardown | Leave it. It holds the record of what was built |

## Deploying into a different AWS account

The runbooks are written for the team's account (`669591255093`). To use
another one:

1. Use a **standard AWS account** with rights to create IAM roles, encryption keys and networks. AWS Academy Learner Lab accounts won't work: they restrict IAM and the regions available.
2. Replace the account ID everywhere it's written down. Terraform doesn't allow variables in some of these places, so they're literal values:
   - `account_id` and the `state_bucket_name` default in `infrastructure/bootstrap/variables.tf`
   - the bucket name in every `backend.tf`: `infrastructure/solution-b/`, `infrastructure/solution-a/workload/` and the four `infrastructure/solution-a/landing-zone/*/` folders
   - `state_bucket_name` in `infrastructure/solution-a/workload/variables.tf`
   - `account_id` in `infrastructure/solution-b/poc.auto.tfvars` and `infrastructure/solution-a/workload/demo.tfvars`
   - the profile name, account ID and organisation ID in `infrastructure/solution-a/lz-dev.ps1`
3. Follow [bootstrap.md](bootstrap.md), then the runbook for the solution you want.

> [!WARNING]
> Never change the `key` in a `backend.tf`. It's how Terraform finds what it
> already built. With a new key, Terraform thinks nothing exists.
