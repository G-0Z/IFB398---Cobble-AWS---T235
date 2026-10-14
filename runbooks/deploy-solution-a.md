# Runbook: build the full Solution A landing zone

**What it does:** builds the whole six-account design: the organisation,
people and groups, guardrails, central security, the container registry,
and then the dev, staging and prod environments.

> [!IMPORTANT]
> **Most of this can't simply be torn down.** It creates five new AWS accounts, and those have to be closed by hand (see [Tear down](#tear-down)). Running everything costs about US$550 a month. **To show Solution A working without any of that, use [demo-solution-a.md](demo-solution-a.md) instead.**

| | |
|---|---|
| **When** | Once. After that, only the environments (step 4) change routinely |
| **Time** | About half a day for the landing zone, then about an hour per environment. Creating accounts and switching on Security Hub take several minutes each |
| **Run by** | Someone with admin rights in the organisation's **management account**, signed in through single sign-on, never as root. The team's organisation is `o-b60hme0nfl`, managed from account `669591255093` |
| **Related** | All runbooks: [README.md](README.md) |

## Contents

1. [The plan at a glance](#the-plan-at-a-glance)
2. [Before you start](#before-you-start)
3. [How every step works](#how-every-step-works)
4. [Values to carry forward](#values-to-carry-forward)
5. [Step 0: state bucket](#step-0-state-bucket)
6. [People and groups](#people-and-groups)
7. [Step 1: organisation, accounts, guardrails, sign-in](#step-1-organisation-accounts-guardrails-sign-in)
8. [Step 2: Security account](#step-2-security-account)
9. [Step 3: Shared Services account](#step-3-shared-services-account)
10. [Step 4: dev, then staging, then prod](#step-4-dev-then-staging-then-prod)
11. [Done checklist](#done-checklist)
12. [Tear down](#tear-down)
13. [Troubleshooting](#troubleshooting)

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
| 0 | `infrastructure/bootstrap` | Terraform state bucket (shared with Solution B) | |
| People | `solution-a/landing-zone/identity` | Identity Center groups, and a sign-in for each person in `users.csv` | Group names |
| 1 | `solution-a/landing-zone/1-organization` | Organisation, 5 member accounts, guardrails, what each group may do in each account | `organization_id`, `account_ids` |
| 2 | `solution-a/landing-zone/2-security` | Security account: Security Hub, GuardDuty, AWS Config, alerts | `config_bucket_name`, `config_kms_key_arn` |
| 3 | `solution-a/landing-zone/3-shared-services` | Shared Services account: container registry | `container_registry_url` |
| 4 | `solution-a/workload` with `dev.tfvars`, `staging.tfvars`, `prod.tfvars` | One environment per account, each running the Cobble module | `app_url` |

> [!NOTE]
> Work through the steps in order, and finish each step's **Verify** checks before starting the next. Several later steps fail in confusing ways if an earlier one is only half applied.

---

## Before you start

- [ ] [Terraform](https://developer.hashicorp.com/terraform/install) 1.10 or later, and the [AWS CLI](https://aws.amazon.com/cli/)
- [ ] Signed in to the **management account** with administrator rights, never as root
- [ ] A monitored email address for each of the 5 new accounts, plus one for security alerts. Gmail-style plus addresses work, for example `t235cobbleaws+dev@gmail.com`
- [ ] If Solution B is deployed in the management account: set `enable_guardduty = false` in its `poc.auto.tfvars` and apply it first. Step 1 takes over threat detection there, and AWS allows only one detector
- [ ] IAM Identity Center enabled for the organisation (console: IAM Identity Center > Enable), with **MFA required** and **Send email OTP** turned on (Settings > Authentication)
- [ ] The costs in [infrastructure/README.md](../infrastructure/README.md#what-it-costs) agreed with the client

Confirm you are in the right account before you touch anything:

```powershell
aws sts get-caller-identity   # Account must be the management account
```

---

## How every step works

The landing-zone steps (people, 1, 2, 3) follow the same pattern. Only the folder changes. Step 4 is different: see [Step 4](#step-4-dev-then-staging-then-prod).

```powershell
cd infrastructure/solution-a/landing-zone/<step>
Copy-Item settings.auto.tfvars.example settings.auto.tfvars  # then edit it
terraform init
terraform plan -out step.tfplan    # read it before applying
terraform apply step.tfplan
terraform output                   # note the values the next step needs
```

| Command | Why |
|---|---|
| `terraform init` | Connects to the state bucket from step 0. The bucket name is already in `backend.tf` |
| `settings.auto.tfvars` | The values for this step: account IDs, emails, budgets and outputs from earlier steps |
| `terraform plan -out` | Saves exactly what you reviewed, so `apply` does only that |
| `terraform output` | Prints the values you must copy into later steps (see the table below) |

Ground rules:

- Read every plan before applying it. A plan that wants to replace or destroy something you did not expect is a stop sign.
- Replace every `@example.com` placeholder with a real address, or account creation fails.
- Stay signed in to the management account throughout. Steps 2 and 3 reach into their accounts through `OrganizationAccountAccessRole`; step 4 needs `-var "assume_role_name=OrganizationAccountAccessRole"`.

---

## Values to carry forward

Copy these as you go. Each is produced by one step and consumed by a later one.

| Value | Produced in | Used in |
|---|---|---|
| `organization_id` | Step 1 | Step 0 re-run (`-var "organization_id=..."`) |
| `account_ids` (management, security, shared services, dev, staging, prod) | Step 1 | The account ID fields in steps 2 and 3, and `account_id` in each step 4 `.tfvars` |
| `config_bucket_name`, `config_kms_key_arn` | Step 2 | Steps 3 and 4 |
| `container_registry_url` | Step 3 | Step 4 `container_image` (as `<container_registry_url>:<version>`) |
| `app_url` | Step 4 | Verification only |

---

## Step 0: state bucket

**Goal:** a state bucket in the management account.

Solution A shares Solution B's state bucket, `cobble-tfstate-669591255093`: Solution B's account is the organisation's management account. Its state lives under `solution-a/` beside Solution B's `poc/`. If the bucket already exists (it does once Solution B has been deployed), there's nothing to do here. Otherwise create it as in [bootstrap.md](bootstrap.md).

> [!NOTE]
> **In a different organisation**, run bootstrap with that management account's ID, then change the bucket name in every `backend.tf` (Solution B, the workload and the four landing-zone steps) and `state_bucket_name` in the workload's `variables.tf`.

**Verify**

- [ ] `aws s3api head-bucket --bucket cobble-tfstate-<management-account-id>` returns without an error

---

## People and groups

**Goal:** create the three Identity Center groups and a sign-in for each person.

This step only touches the Identity Center directory. It creates no accounts and doesn't change the organisation. It runs in whichever account administers Identity Center: the management account, or a member account the organisation has made the delegated administrator. That makes it the one part of Solution A you can run on its own.

```powershell
cd infrastructure/solution-a/landing-zone/identity
```

Copy `users.csv.example` to `users.csv` and put in one row per person: their sign-in name, name, email and groups (`platform-admins`, `developers` or `auditors`; separate several with `;`). To add or remove someone later, edit the file and apply again. `users.csv` is not committed because it holds personal details.

**If people or groups were already added by hand in the console**, bring them under Terraform first, or the apply fails with a conflict. Find the IDs (as a platform admin):

```powershell
$store = aws sso-admin list-instances --query "Instances[0].IdentityStoreId" --output text
aws identitystore list-users  --identity-store-id $store --query "Users[].[UserName,UserId]"        --output table
aws identitystore list-groups --identity-store-id $store --query "Groups[].[DisplayName,GroupId]" --output table
```

Put each existing person in `users.csv` with their **exact** sign-in name, then after `terraform init`:

```powershell
terraform import 'aws_identitystore_user.this[\"<user-name>\"]' "$store/<user-id>"
terraform import 'aws_identitystore_group.this[\"developers\"]' "$store/<group-id>"   # only for cobble- groups that already exist
```

Group memberships added by hand are imported the same way (`aws_identitystore_group_membership.this["<user-name>/<group>"]`, ID `$store/<membership-id>`). It's simpler to remove them in the console and let Terraform add them back. The plan should then show only the changes you expect.

Then plan and apply as in [How every step works](#how-every-step-works).

**Afterwards:** tell each person to go to the AWS access portal URL (IAM Identity Center > Settings) and sign in with their sign-in name. Because **Send email OTP** is on, they get a one-time code by email and then set their own password and MFA device.

> [!IMPORTANT]
> Until step 1 has run, people can sign in to the portal but see **no accounts**. Groups only become access once step 1 assigns them a role in an account.

**Verify**

- [ ] The three `cobble-` groups exist in IAM Identity Center, and every person in `users.csv` is in theirs
- [ ] One person has signed in to the access portal and set up MFA

---

## Step 1: organisation, accounts, guardrails, sign-in

**Goal:** create the organisation, the 5 member accounts, the guardrail policies (SCPs) and each group's access to each account.

```powershell
cd infrastructure/solution-a/landing-zone/1-organization
```

**If the organisation already exists**, bring it under Terraform first. Check with:

```powershell
aws organizations describe-organization
```

If it returns an organisation, import it:

```powershell
terraform init
terraform import aws_organizations_organization.this <organization-id>   # o-b60hme0nfl for the T235 organisation
```

Then plan and apply as in [How every step works](#how-every-step-works). It needs the groups from [People and groups](#people-and-groups) to exist already.

**Record:** `organization_id` and `account_ids`.

**By hand afterwards**

1. From now on, sign in through the AWS access portal instead of any IAM user.
2. Re-run bootstrap with `-var "organization_id=<organization-id>"` (in `infrastructure/bootstrap`, on the machine that holds its local state) so the CI roles created in step 4 can reach their state.

**Verify**

- [ ] `aws organizations list-accounts --query "Accounts[].[Name,Id,Status]" --output table` shows the 5 new accounts as `ACTIVE`
- [ ] Signed in through the access portal, each group sees its accounts (for example, `developers` sees dev, staging and prod)
- [ ] The bootstrap re-run finished without errors

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

All three use the one `solution-a/workload` folder. Each environment's values are in its own `.tfvars` file. In `dev.tfvars` (then `staging.tfvars`, then `prod.tfvars`), replace each `REPLACE:` value:

- `account_id`: step 1 output `account_ids.<environment>`
- `container_image`: `<container_registry_url>:<version>` from step 3
- `config_bucket_name`, `config_kms_key_arn`: step 2 outputs

Commit the filled-in files: they hold no secrets, and CI's drift check reads them.

```powershell
cd infrastructure/solution-a/workload
$e = "dev"   # then staging, then prod
terraform init -reconfigure -backend-config="key=solution-a/workload/$e/terraform.tfstate"
terraform plan -var-file="$e.tfvars" -var "assume_role_name=OrganizationAccountAccessRole" -out "$e.tfplan"
terraform apply "$e.tfplan"
```

**Verify each environment before starting the next**

```powershell
terraform output app_url          # open it: the application should answer
terraform plan -var-file="$e.tfvars" -var "assume_role_name=OrganizationAccountAccessRole" -detailed-exitcode   # exit code 0 = no drift
```

- [ ] `app_url` opens and the application answers
- [ ] The plan exits with code 0 (no drift)

**By hand afterwards**

1. In GitHub (Settings > Environments), create `dev`, `staging` and `prod`. Add required reviewers to `staging` and `prod`.
2. Turn on the nightly drift check (`.github/workflows/drift.yml`) for this environment. In GitHub, Settings > Secrets and variables > Actions > Variables, add `SOLUTION_A_<ENV>_PLAN_ROLE_ARN` (with `<ENV>` as `dev`, `staging` or `prod`) set to the `github_plan_role_arn` output.

   Run the workflow by hand once (Actions > Drift detection > Run workflow, on `main`). It should pass. A failed run means someone changed AWS outside Terraform: re-apply, or put the change into code.
3. When the domain is ready, request an ACM certificate (for example for `dev.cobble.com`), set `certificate_arn`, and re-apply. HTTP then redirects to HTTPS.

---

## Done checklist

- [ ] Organisation and all 5 member accounts are `ACTIVE`
- [ ] Everyone signs in through the AWS access portal, and MFA is required
- [ ] Security alerts subscription is confirmed
- [ ] The first Cobble image is in the registry
- [ ] dev, staging and prod each answer at their `app_url`, and the plan shows nothing has drifted
- [ ] GitHub environments exist, with reviewers on `staging` and `prod`
- [ ] The drift detection workflow passes for dev, staging and prod
- [ ] Certificates are set and HTTP redirects to HTTPS (once the domain is ready)

---

## Tear down

| What | How |
|---|---|
| dev or staging (to save cost) | `terraform destroy -var-file="$e.tfvars" -var "assume_role_name=OrganizationAccountAccessRole"` in `solution-a/workload`, after `init` with that environment's key. Run by a person: GitHub's roles can't, because a guardrail stops them switching off configuration history. Rebuild later with apply |
| prod | Set `protect_from_deletion = false` in `prod.tfvars`, apply, then destroy. Deliberately two steps |
| The landing zone | Not torn down routinely. The member accounts are protected and must be closed by hand in AWS Organizations. Audit logs stay locked for `audit_log_retention_days` |

---

## Troubleshooting

> [!TIP]
> Most failures come down to being in the wrong account, or moving on before AWS has finished setting something up. Check `aws sts get-caller-identity` first, and wait a few minutes before retrying.

| Error | Usually in | Cause | Fix |
|---|---|---|---|
| `AWS account ID not allowed` | Any step | Wrong account, or wrong ID in the settings | `aws sts get-caller-identity`; check `settings.auto.tfvars` or the `.tfvars` file |
| GuardDuty detector already exists | Step 1 | Solution B's threat detection is still on in the management account | Set `enable_guardduty = false` in Solution B and apply it, then retry |
| Account limit reached creating accounts | Step 1 | A new organisation may start with a low account limit | Request an increase in Service Quotas (AWS Organizations), then retry |
| `AlreadyInOrganizationException` / organisation already exists | Step 1 | The organisation predates Terraform | Import it (see [step 1](#step-1-organisation-accounts-guardrails-sign-in)) |
| `AccessDenied` assuming `OrganizationAccountAccessRole` | Steps 2 to 4 | Account still being created, or not signed in to management | Wait a few minutes; check sign-in |
| `aws_ssoadmin_instances` returns nothing | Step 1 | Identity Center not enabled | Enable it in the console first |
| Security Hub or GuardDuty "not a delegated administrator" | Step 2 | Step 1 not applied, or still propagating | Apply step 1; wait a few minutes; retry step 2 |
| Denied by an SCP (`explicit deny in a service control policy`) | Any step | A guardrail blocked the action | Expected for other regions and for turning off security services. Check `1-organization/policies/` |
| `email address must be real` | Steps 1 to 4 | `@example.com` placeholders left in | Replace them |
| `The term 'aws' is not recognized` | Before you start | AWS CLI not installed, or the terminal was opened before installing it | Install the AWS CLI, then restart the terminal or IDE |
| `The term 'terraform' is not recognized` | Before you start | Terraform not installed, or the terminal was opened before installing it | Install Terraform, then restart the terminal or IDE |
