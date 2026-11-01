# Runbook: demo Solution A in one account

**What it does:** deploys Solution A's real workload (the same code as dev,
staging and prod) into the team's account for a demo, then removes it. It
uses the settings in
[`demo.tfvars`](../infrastructure/solution-a/workload/demo.tfvars): 66
resources, about 15 minutes.

**Cost:** about A$0.22 an hour (NAT gateway, load balancer, database, web
server). A 3-hour demo costs about A$0.70, but it's A$5 a day if
forgotten, so **always tear it down**.

## What you'll be showing

| | Solution B | Solution A demo |
|---|---|---|
| Network | Public subnets only, no NAT | Public, private and database layers, with a NAT gateway |
| Web servers | Optional, in a public subnet | In **private** subnets behind the load balancer, auto scaling 1–2 |
| Database | None | PostgreSQL with no route to the internet; only the web servers can connect |
| Can run at the same time? | Yes: separate networks (10.20.0.0/16 and 10.28.0.0/16) and separate records | |

**What the demo can't show:** the rest of Solution A (separate accounts,
guardrails, single sign-on access, locked audit logs, central security, the
container registry) needs an AWS Organisation. Show those as code, and as
passing automatic checks on every folder.

## Before you start

Same as Solution B: Terraform, the AWS CLI, and a sign-in to the team's
account ([deploy-solution-b.md](deploy-solution-b.md#sign-in)). Check
`aws sts get-caller-identity` shows account `669591255093`.

## Deploy

```powershell
cd infrastructure/solution-a/workload
terraform init -reconfigure -backend-config="key=solution-a/workload/demo/terraform.tfstate"
terraform plan -var-file="demo.tfvars" -out demo.tfplan  # should show 66 to add
terraform apply demo.tfplan          # about 10-15 minutes; the database is the slow part
terraform output app_url             # open this address in a browser
```

You should see the nginx welcome page. It stands in for a Cobble
application. If you get a 503 error at first, wait a minute: the web server
is still starting and passing its health checks.

## Things to point at during the demo

- **VPC > Subnets:** six subnets in three layers across two zones. The database subnets' route table has no route to the internet.
- **ECS > Clusters > cobble-demo:** the web server has a private IP only. Traffic reaches it through the load balancer.
- **ECS > the service > Auto scaling:** 1 to 2 web servers, aiming for 60% CPU.
- **RDS > cobble-demo:** "Publicly accessible: No", and encrypted with the environment's key.
- **Secrets Manager:** the database password. It's never in the code or the server's settings.
- **S3:** the data bucket: encrypted, versioned, access logged.

## Tear down

```powershell
terraform plan -destroy -var-file="demo.tfvars" -out destroy.tfplan
terraform apply destroy.tfplan
terraform state list                 # should print nothing
```

Everything is removed except the encryption key, which AWS holds for 7 days
before deleting it.

To prove it's repeatable, run the deploy steps again: you should get the
same 66 resources and the same page. Record it in the
[evidence log](../docs/Evidence/README.md#evidence-log).

## If something goes wrong

| Symptom | Cause | Fix |
|---|---|---|
| `AWS account ID not allowed` | Signed in to the wrong account | Sign in to 669591255093 |
| `AccessDenied` creating ECS, load balancer or RDS resources | Your IAM user's permissions only cover Solution B | Use single sign-on with an admin role, or add those services to your IAM user's policy |
| The load balancer returns 503 for more than 5 minutes | The web server can't start | ECS > the service > Tasks > a stopped task: read the reason, then the log group `/cobble-demo/app` |
| Tear down fails on a bucket | Files were added by hand | Run the tear down again. Buckets outside prod empty themselves |
