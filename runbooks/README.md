# Runbooks

Step-by-step instructions for deploying, demoing and tearing down the
platform. Each runbook is written so that someone who didn't write the code
can follow it from start to finish.

## Which runbook do I need?

| I want to... | Runbook | Time |
|---|---|---|
| Show Solution B, then remove it | [deploy.md](deploy.md), then [teardown.md](teardown.md) | About 5 minutes each way |
| Show Solution A's workload in the same account, then remove it | [demo-solution-a.md](demo-solution-a.md) | About 15 minutes each way |
| Prove a solution redeploys identically | [teardown.md](teardown.md#redeploy-the-repeatability-check) | |
| Create the state bucket (only if it's missing) | [bootstrap.md](bootstrap.md) | A few minutes, once |
| Build the full six-account landing zone | [deploy-solution-a.md](deploy-solution-a.md) | Half a day, plus an hour per environment |

Runbooks for when something goes wrong (an outage, a database failure,
stolen credentials, drift, the web firewall blocking real users, a cost
spike) are in the
[operations model](../docs/05-deployment-operations/README.md#6-runbooks).

## A typical demo day

```text
1. deploy.md            Solution B: the account's security baseline
2. demo-solution-a.md   Solution A's workload beside it
                        ... demo ...
3. demo-solution-a.md   tear down Solution A first
4. teardown.md          then Solution B
```

Solution A's workload doesn't depend on Solution B, so you can also deploy
it on its own.

## What you need

- [Terraform](https://developer.hashicorp.com/terraform/install) 1.10 or later
- The [AWS CLI](https://aws.amazon.com/cli/)
- A sign-in to the team's AWS account. See [deploy.md](deploy.md#sign-in)

## Things that can block a clean teardown

| Blocker | What happens | What to do |
|---|---|---|
| Encryption keys | AWS waits 7 to 30 days before deleting a key, and bills for it until then | Expected. A redeploy creates a new key |
| Locked audit logs (Solution A landing zone) | In the default "governance" mode an admin can remove the lock. In "compliance" mode **nobody can, not even the root user,** until the date passes | Keep governance mode. Never use compliance mode in a student or demo account |
| AWS accounts (Solution A landing zone) | They're protected, so `terraform destroy` only removes them from the organisation. Closed accounts linger for 90 days and still count towards the account limit | The landing zone isn't torn down routinely. Close accounts by hand only when you're sure |
| The state bucket | Not removed by any teardown | Leave it. It holds the record of what was built |

## Check nothing is left running

After a teardown, `terraform plan` in the same folder should offer to
create everything again: 48 resources for Solution B, 66 for the Solution A
demo. In the AWS console, check that the VPCs, load balancers, ECS clusters
and databases are gone, and look at Billing the next day for any new spend.

## Deploying into a different AWS account

The runbooks are written for the team's account (`669591255093`). To use
another one:

1. Use a **standard AWS account** with rights to create IAM roles, encryption keys and networks. AWS Academy Learner Lab accounts won't work: they restrict IAM and limit the regions available.
2. Replace the account ID everywhere it's written down. Terraform doesn't allow variables in some of these places, so they're literal values:
   - `account_id` in `infrastructure/bootstrap/variables.tf`
   - the bucket name in every `backend.tf`: `infrastructure/solution-b/`, `infrastructure/solution-a/workload/` and the four `infrastructure/solution-a/landing-zone/*/` folders
   - `state_bucket_name` in `infrastructure/solution-a/workload/variables.tf`
   - `account_id` in `infrastructure/solution-b/poc.auto.tfvars` and `infrastructure/solution-a/workload/demo.tfvars`
3. Follow [bootstrap.md](bootstrap.md), then the runbook for the solution you want.

Never change the `key` in a `backend.tf`. It's how Terraform finds what it
already built. With a new key, Terraform thinks nothing exists.
