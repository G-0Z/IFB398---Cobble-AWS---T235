# Runbook: deploy Solution A (full landing zone)

| | |
|---|---|
| **Purpose** | Build the organisation in the Cyber Security Centre's AWS management account |
| **When** | Once. After that only step 4 changes routinely (and eventually through CI) |
| **Time** | About half a day for steps 0 to 3, then about an hour per environment. Creating accounts and turning on Security Hub can take several minutes each |
| **Run by** | A person with administrator rights in the **management account**, never as root |
| **Related** | Solution B's runbooks ([deploy.md](deploy.md), [teardown.md](teardown.md)) are separate and unaffected |

## Contents

1. [The plan at a glance](#the-plan-at-a-glance)
2. [Before you start](#before-you-start)
3. [How every step works](#how-every-step-works)
4. [Values to carry forward](#values-to-carry-forward)
5. [Step 0: state bucket](#step-0-state-bucket)
6. [Step 1: organisation, accounts, guardrails, sign-in](#step-1-organisation-accounts-guardrails-sign-in)
7. [Step 2: Security account](#step-2-security-account)
8. [Step 3: Shared Services account](#step-3-shared-services-account)
9. [Step 4: dev, then staging, then prod](#step-4-dev-then-staging-then-prod)
10. [Done checklist](#done-checklist)
11. [Tear down](#tear-down)
12. [Troubleshooting](#troubleshooting)

---

## The plan at a glance

```text
Step 0         Step 1                  Step 2        Step 3             Step 4
State bucket → Organisation, accounts, → Security   → Shared Services → dev → staging → prod
               guardrails, sign-in      account       (registry)
                    │
                    └─ then re-run Step 0 with the organisation ID
                       (needed before Step 4's CI roles can reach state)
```

| Step | Folder | What it builds | Hands on to the next step |
|---|---|---|---|
| 0 | `infrastructure/bootstrap` | Terraform state bucket (own workspace) | Bucket name |
| 1 | `solution-a/1-organization` | Organisation, 5 member accounts, guardrails, Identity Center groups | `organization_id`, `account_ids` |
| 2 | `solution-a/2-security` | Security account: Security Hub, GuardDuty, AWS Config, alerts | `config_bucket_name`, `config_kms_key_arn` |
| 3 | `solution-a/3-shared-services` | Shared Services account: container registry | `container_registry_url` |
| 4 | `solution-a/4-workloads/dev`, `staging`, `prod` | One environment per account, each running the Cobble module | `app_url` |

> [!NOTE]
> Work through the steps in order, and finish each step's **Verify** checks before starting the next. Several later steps fail in confusing ways if an earlier one is only half applied.

---

## Before you start

- [ ] [Terraform](https://developer.hashicorp.com/terraform/install) 1.10 or later, and the [AWS CLI](https://aws.amazon.com/cli/)
- [ ] Signed in to the **management account** with administrator rights, never as root
- [ ] One monitored team mailbox for each of the 5 new accounts, plus a security-alerts mailbox
- [ ] IAM Identity Center enabled for the organisation (console: IAM Identity Center > Enable), with **MFA required** (Settings > Authentication)
- [ ] The costs in [infrastructure/README.md](../infrastructure/README.md#what-it-costs) agreed with the client

Confirm you are in the right account before you touch anything:

```powershell
aws sts get-caller-identity   # Account must be the management account
```

---

## How every step works

Steps 1 to 4 follow the same pattern. Only the folder changes.

```powershell
cd infrastructure/solution-a/<step>
Copy-Item backend.hcl.example backend.hcl                    # then edit it
Copy-Item settings.auto.tfvars.example settings.auto.tfvars  # then edit it
terraform init -backend-config=backend.hcl
terraform plan -out step.tfplan    # read it before applying
terraform apply step.tfplan
terraform output                   # note the values the next step needs
```

| Command | Why |
|---|---|
| `backend.hcl` | Points Terraform at the state bucket from step 0 |
| `settings.auto.tfvars` | The values for this step: account IDs, emails, budgets and outputs from earlier steps |
| `terraform plan -out` | Saves exactly what you reviewed, so `apply` does only that |
| `terraform output` | Prints the values you must copy into later steps (see the table below) |

Ground rules:

- Read every plan before applying it. A plan that wants to replace or destroy something you did not expect is a stop sign.
- Replace every `@example.com` placeholder with a real address, or account creation fails.
- Stay signed in to the management account throughout. Keep `assume_role_name = "OrganizationAccountAccessRole"` for runs by a person.

---

## Values to carry forward

Copy these as you go. Each is produced by one step and consumed by a later one.

| Value | Produced in | Used in |
|---|---|---|
| State bucket name | Step 0 | `backend.hcl` in **every** step folder |
| `organization_id` | Step 1 | Step 0 re-run (`-var "organization_id=..."`) |
| `account_ids` (management, security, shared services, dev, staging, prod) | Step 1 | The account ID fields in steps 2 to 4 |
| `config_bucket_name`, `config_kms_key_arn` | Step 2 | Steps 3 and 4 |
| `container_registry_url` | Step 3 | Step 4 `container_image` (as `<container_registry_url>:<version>`) |
| `app_url` | Step 4 | Verification only |

---

## Step 0: state bucket

**Goal:** create the state bucket for Solution A in the management account.

Bootstrap keeps its own state locally, so give Solution A its **own workspace**. Otherwise Terraform would try to replace Solution B's bucket.

```powershell
cd infrastructure/bootstrap
terraform init
terraform workspace new solution-a        # 'terraform workspace select solution-a' next time
terraform apply -var "account_id=<management-account-id>" -var "state_bucket_name=cobble-tfstate-<management-account-id>"
```

Put the bucket name into every `backend.hcl`.

**Verify**

- [ ] `terraform workspace show` prints `solution-a`
- [ ] `aws s3api head-bucket --bucket cobble-tfstate-<management-account-id>` returns without an error

---

## Step 1: organisation, accounts, guardrails, sign-in

**Goal:** create the organisation, the 5 member accounts, the guardrail policies (SCPs) and the Identity Center groups.

```powershell
cd infrastructure/solution-a/1-organization
```

**If the organisation already exists**, bring it under Terraform first. Check with:

```powershell
aws organizations describe-organization
```

If it returns an organisation, import it:

```powershell
terraform init -backend-config=backend.hcl
terraform import aws_organizations_organization.this <organization-id>
```

Then plan and apply as in [How every step works](#how-every-step-works).

**Record:** `organization_id` and `account_ids`.

**By hand afterwards**

1. In IAM Identity Center, create a user for each person and add them to `cobble-platform-admins`, `cobble-developers` or `cobble-auditors`.
2. From now on, sign in through the AWS access portal instead of any IAM user.
3. Re-run bootstrap (step 0, **same workspace**) with `-var "organization_id=<organization-id>"` so the CI roles created in step 4 can reach their state.

**Verify**

- [ ] `aws organizations list-accounts --query "Accounts[].[Name,Id,Status]" --output table` shows the 5 new accounts as `ACTIVE`
- [ ] The three groups exist in IAM Identity Center and every person is in one
- [ ] Bootstrap re-run completed in the `solution-a` workspace

---

## Step 2: Security account

**Goal:** stand up the Security account (Security Hub, GuardDuty, AWS Config and alerting).

Fill in `management_account_id`, `security_account_id` (both from step 1) and `security_alert_email`. Plan and apply.

**Record:** `config_bucket_name` and `config_kms_key_arn`.

**By hand afterwards:** open the "AWS Notification - Subscription Confirmation" email and click **Confirm subscription**, or no alerts arrive.

**Verify**

- [ ] The subscription email is confirmed
- [ ] Security Hub and GuardDuty show the Security account as the delegated administrator (if not, see [Troubleshooting](#troubleshooting))

---

## Step 3: Shared Services account

**Goal:** create the Shared Services account and its container registry, then publish the first Cobble image.

Fill in the account ID, the two step 2 outputs, a budget and an email. Plan and apply.

**Record:** `container_registry_url`.

Push the first Cobble image:

```powershell
aws ecr get-login-password | docker login --username AWS --password-stdin <registry-host>
docker tag cobble-module:1.0.0 <container_registry_url>:1.0.0
docker push <container_registry_url>:1.0.0
```

> [!TIP]
> `<registry-host>` is the part of `container_registry_url` before the first `/`. The `aws ecr` command must run with credentials for the **Shared Services** account (and the registry's region), not the management account.

**Verify**

- [ ] The push completes and the image appears in the registry in the Shared Services account

---

## Step 4: dev, then staging, then prod

**Goal:** create each environment, one at a time, in this order: **dev, staging, prod**.

For each environment folder, fill in:

- its account ID
- `container_image` (`<container_registry_url>:<version>`)
- the step 2 outputs
- GitHub details
- budget and email

Keep `assume_role_name = "OrganizationAccountAccessRole"` for runs by a person. Plan and apply.

**Verify each environment before starting the next**

```powershell
terraform output app_url          # open it: the Cobble module should answer
terraform plan -detailed-exitcode # exit code 0 = no drift
```

- [ ] `app_url` opens and the Cobble module answers
- [ ] The plan exits with code 0 (no drift)

**By hand afterwards**

1. In GitHub (Settings > Environments), create `dev`, `staging` and `prod`. Add required reviewers to `staging` and `prod`.
2. When the domain is ready, request an ACM certificate (for example for `dev.cobble.com`), set `certificate_arn`, and re-apply. HTTP then redirects to HTTPS.

---

## Done checklist

- [ ] Organisation and all 5 member accounts are `ACTIVE`
- [ ] Everyone signs in through the AWS access portal, and MFA is required
- [ ] Security alerts subscription is confirmed
- [ ] The first Cobble image is in the registry
- [ ] dev, staging and prod each answer at their `app_url` and show no drift
- [ ] GitHub environments exist, with reviewers on `staging` and `prod`
- [ ] Certificates are set and HTTP redirects to HTTPS (once the domain is ready)

---

## Tear down

| What | How |
|---|---|
| dev or staging (to save cost) | `terraform destroy` in its folder, run by a person signed in to the management account. Rebuild later with apply. CI can't tear down: the guardrail SCP stops its roles switching off AWS Config, by design. For the same reason, a change to an environment's AWS Config recorder or VPC flow logs must be applied by a person. |
| prod | Set `protect_from_deletion = false` in `prod/main.tf`, apply, then destroy. Deliberately two steps. |
| Steps 1 to 3 | Not torn down routinely. Member accounts are protected (`prevent_destroy`) and must be closed by hand in AWS Organizations. Audit logs stay locked for `audit_log_retention_days`. |

---

## Troubleshooting

> [!TIP]
> Most failures come down to being in the wrong account or acting before something has finished propagating. Check `aws sts get-caller-identity` first, and wait a few minutes before retrying.

| Error | Usually in | Cause | Fix |
|---|---|---|---|
| `AWS account ID not allowed` | Any step | Wrong account, or wrong ID in settings | `aws sts get-caller-identity`; check `settings.auto.tfvars` |
| `AlreadyInOrganizationException` / organisation already exists | Step 1 | The organisation predates Terraform | Import it (see [step 1](#step-1-organisation-accounts-guardrails-sign-in)) |
| `AccessDenied` assuming `OrganizationAccountAccessRole` | Steps 2 to 4 | Account still being created, or not signed in to management | Wait a few minutes; check sign-in |
| `aws_ssoadmin_instances` returns nothing | Step 1 | Identity Center not enabled | Enable it in the console first |
| Security Hub or GuardDuty "not a delegated administrator" | Step 2 | Step 1 not applied, or still propagating | Apply step 1; wait a few minutes; retry step 2 |
| Denied by an SCP (`explicit deny in a service control policy`) | Any step | A guardrail blocked the action | Expected for other regions and for turning off security services. Check `1-organization/policies/` |
| `email address must be real` | Steps 1 to 4 | `@example.com` placeholders left in | Replace them |
| `The term 'aws' is not recognized` | Before you start | AWS CLI not installed, or the terminal was opened before installing it | Install the AWS CLI, then restart the terminal or IDE |
| `The term 'terraform' is not recognized` | Before you start | Terraform not installed, or the terminal was opened before installing it | Install Terraform, then restart the terminal or IDE |
