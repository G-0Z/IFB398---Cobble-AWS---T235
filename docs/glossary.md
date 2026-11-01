# Glossary

The terms used across this project, in plain English.

## The project

| Term | Meaning |
|---|---|
| **Cobble** | The Cyber Security Centre's proof-of-concept platform for hosting software for many customer organisations |
| **Solution B**, **MVP**, **PoC** | Three names for the same thing: the smallest secure version of the platform, in one AWS account (`infrastructure/solution-b/`) |
| **Solution A** | The full design: six AWS accounts with guardrails, single sign-on and central security (`infrastructure/solution-a/`) |
| **Workload** | One Cobble environment: network, web servers, database and storage (`solution-a/workload/`). The same code builds the demo, dev, staging and prod |
| **Demo** | Usually the landing zone demo: Solution A's security services and dev environment brought up and down with `lz-dev.ps1`. Also the `demo` environment: Solution A's workload deployed into Solution B's account for a few hours |
| **Landing zone** | The secure, ready-made AWS starting point that applications are deployed into (`solution-a/landing-zone/`) |
| **Implementation Guide** | The client's *Cobbled AWS Platform Engineering Implementation Guide*, the target design we measure ourselves against |
| **Phase 1 / Phase 2** | This semester's work / the follow-on work we've recommended |

## Terraform

| Term | Meaning |
|---|---|
| **Terraform** | The tool that reads our code and creates the matching resources in AWS |
| **Root config** | A folder you run Terraform in. Each one deploys something on its own. There are seven |
| **Module** | A reusable building block (for example, "a private database") in `infrastructure/modules/`. Never run on its own |
| **State** | Terraform's record of what it has built. Kept in an S3 bucket so the whole team shares it |
| **State key** | Where one root config's state lives in the bucket. **Never change it**: Terraform would think nothing exists and try to build everything again |
| **Bootstrap** | The small one-off config that creates the state bucket |
| **`.tfvars` file** | The settings for one deployment, for example `prod.tfvars` |
| **Plan / apply / destroy** | Preview the changes / make them / remove everything |
| **Drift** | When what's running in AWS no longer matches the code, usually because someone changed it in the console |

## AWS

| Term | Meaning |
|---|---|
| **Account** | A separate AWS container with its own resources and bill. The strongest separation AWS offers |
| **Organisation, OU** | AWS Organizations groups accounts; an organisational unit (OU) is a folder of accounts that share rules |
| **SCP** | Service control policy: a guardrail that limits what anyone in an account can do, even an administrator |
| **IAM Identity Center** | AWS single sign-on. People sign in once, then pick an account and a role |
| **Permission set** | A role in Identity Center, such as read-only, given to a group in an account |
| **OIDC** | How GitHub gets short-lived AWS access without storing any passwords or keys |
| **VPC, subnet** | A private network in AWS, divided into sections. Public subnets face the internet; private ones don't |
| **NAT gateway** | Lets servers in private subnets reach out to the internet without being reachable from it |
| **KMS key** | An encryption key AWS manages for us. Data can't be read without permission to use the key |
| **CloudTrail** | A record of every action taken in AWS: who, what, when |
| **GuardDuty** | AWS's threat detection service: it watches for signs of attack |
| **Security Hub** | Checks the accounts against security best practices and collects findings in one place |
| **Object Lock** | An S3 setting that stops files being changed or deleted until a set date. Used for audit logs |
| **ECS Fargate** | Runs containers (packaged applications) without any servers for us to manage |
| **RDS** | AWS's managed database service |
| **WAF** | Web application firewall: blocks common web attacks before they reach the application |
| **Multi-tenant** | One platform serving many customer organisations (tenants), whose data must stay separate |

## How finished a control is

Two separate questions. **Has it run in AWS?** uses *demonstrated*, as in
the [status diagram](01-reference-architecture/README.md#what-has-been-tested).
**How strong is it?** uses the scale below, as in the
[control map](../infrastructure/README.md#control-map) and the deliverables.

| Status | Meaning |
|---|---|
| **Demonstrated** | Deployed and seen working in AWS, in the runs of 17 to 18 October 2026, with logs and screenshots in [the evidence](Evidence/README.md) |
| **Designed** | Written down only. The status diagram calls this *not yet built* |
| **Configured** | Built by the code, so it's there whenever the platform is deployed. An administrator could still change it |
| **Enforced** | Built, and no one in the account can turn it off (for example, because a guardrail stops them) |
| **Not covered** | Not part of that solution |
