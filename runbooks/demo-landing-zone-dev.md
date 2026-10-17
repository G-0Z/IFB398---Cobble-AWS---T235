# Runbook: demo the Solution A landing zone with one environment (dev)

**What it does:** builds the real Solution A landing zone in the team's
organisation (`o-b60hme0nfl`, managed from `669591255093`) and one
environment (dev) inside it, so it can be recorded. Then it removes
everything that can be removed and closes the new accounts.

Unlike the [single-account demo](demo-solution-a.md), this shows the parts
that need an organisation: separate accounts, guardrails that block even an
administrator, single sign-on, and central security.

> [!IMPORTANT]
> **This creates 5 real AWS accounts.** Terraform can't delete them, so you close them by hand at the end ([step 7](#7-tear-down-same-day)). A closed account stays in the organisation, labelled `CLOSED`, for 90 days. It still counts toward the organisation's account limit during that time, and **its email address can never be used again**.

| | |
|---|---|
| **Builds** | Single sign-on for one person, 5 member accounts in their folders, 4 guardrails, central audit trail, GuardDuty, Security Hub, Config, alerts, and the dev environment (network, web server, database, data bucket) |
| **Skips** | Step 3 (container registry): dev runs a stock nginx image instead. Staging and prod environments: their accounts are created, but nothing is deployed in them |
| **Time** | About half a day, mostly waiting for AWS: accounts, Security Hub and the database are slow |
| **Cost** | About A$0.30 to A$0.40 an hour while it's up, so roughly A$10 to A$15 for the session. Charges stop once the accounts are closed |
| **Left afterwards** | 5 closed accounts (no charges) for 90 days, the empty account folders, and the organisation itself, as before |

The settings files are already filled in. They're kept off GitHub by
`.gitignore`:

| File | Holds |
|---|---|
| `landing-zone/identity/settings.auto.tfvars` | The management account ID |
| `landing-zone/identity/users.csv` | One login: `max.gosling`, emailed at `t235cobbleaws+max@gmail.com`. Add teammates as extra rows if wanted |
| `landing-zone/1-organization/settings.auto.tfvars` | The management account ID and an email for each new account (`t235cobbleaws+security@gmail.com` and so on) |
| `landing-zone/2-security/settings.auto.tfvars` | The security alert email (`n11543027@qut.edu.au` for now) and a 1-day audit log lock for the demo |

Dev uses the committed `workload/dev.tfvars`, with a few demo values set on
the command line in [step 4](#4-dev-environment), including sending its
budget alerts to `n11543027@qut.edu.au`.

---

## 0. Before you start

Work through this list first. Do everything in **one PowerShell window**
and keep it open: later steps reuse values saved in earlier ones.

- [ ] **Signed in as an administrator.** The default CLI login (IAM user `mgosling`) can only change its own password, so use the Identity Center admin profile:

  ```powershell
  aws sso login --profile AdministratorAccess-669591255093
  $env:AWS_PROFILE = "AdministratorAccess-669591255093"
  aws sts get-caller-identity    # Arn should contain AWSReservedSSO_AdministratorAccess, account 669591255093
  ```

  The sign-in lasts a few hours. If a later step fails with an expired token, run `aws sso login` again in the same window.
- [ ] **Organisation.** `aws organizations describe-organization` shows `o-b60hme0nfl` and `"FeatureSet": "ALL"`
- [ ] **IAM Identity Center** is enabled for the organisation in Sydney. In its console, Settings > Authentication: **MFA required**, and **Send email OTP** turned on
- [ ] **Room for 5 more accounts.** Service Quotas > AWS Organizations > *Default maximum number of accounts* must be at least the current number of accounts plus 5. If not, request an increase and wait for it
- [ ] **Solution B hands over GuardDuty.** An account can only have one GuardDuty detector, and step 2 takes it over. In `infrastructure/solution-b`, set `enable_guardduty = false` in `poc.auto.tfvars`, then:

  ```powershell
  cd C:\Users\maxgo\dev\IFB398---Cobble-AWS---T235\infrastructure\solution-b
  terraform plan -out deploy.tfplan     # should only remove the GuardDuty detector
  terraform apply deploy.tfplan
  ```

Then set up the values the rest of the runbook uses:

```powershell
$repo = "C:\Users\maxgo\dev\IFB398---Cobble-AWS---T235"
$lz   = "$repo\infrastructure\solution-a\landing-zone"
$ev   = "$repo\infrastructure\solution-a\evidence"
New-Item -ItemType Directory -Force $ev | Out-Null
```

Every `cmd /c "... 2>&1" | Tee-Object` line below saves Terraform's output
into `$ev` as evidence while still showing it on screen. Windows PowerShell
5.1 writes these as UTF-16, which GitHub shows as binary, so convert them
before committing: `Get-ChildItem $ev\*.txt | % { $t = Get-Content $_; Set-Content $_ $t -Encoding utf8 }`.

> [!TIP]
> Record in segments, one per step, rather than one long video. Most of the time is spent waiting.

---

## 1. People: single sign-on

```powershell
cd "$lz\identity"
terraform init
```

**If anyone was added to Identity Center by hand earlier**, check before
planning. A `cobble-` group or a `max.gosling` user that already exists
makes the apply fail:

```powershell
$store = aws sso-admin list-instances --query "Instances[0].IdentityStoreId" --output text
aws identitystore list-users  --identity-store-id $store --query "Users[].[UserName,UserId]"       --output table
aws identitystore list-groups --identity-store-id $store --query "Groups[].[DisplayName,GroupId]" --output table
```

If one exists, delete it in the console, or import it as in
[deploy-solution-a.md](deploy-solution-a.md#people-and-groups).

```powershell
cmd /c "terraform plan -no-color -out people.tfplan 2>&1"  | Tee-Object "$ev\1-people_plan.txt"   # 3 groups, 1 user, 1 membership
cmd /c "terraform apply -no-color people.tfplan 2>&1"      | Tee-Object "$ev\1-people_apply.txt"
```

**Afterwards:** open the AWS access portal (IAM Identity Center > Settings >
*AWS access portal URL*). Sign in as `max.gosling`. The one-time code goes to
the team inbox. Set a password and an MFA device. You'll see no accounts yet:
step 2 grants them.

---

## 2. Organisation, accounts and guardrails

**This step creates the 5 accounts. It's the point of no return.**

```powershell
cd "$lz\1-organization"
terraform init
terraform import aws_organizations_organization.this o-b60hme0nfl   # brings the existing organisation under Terraform; changes nothing in AWS
cmd /c "terraform plan -no-color -out org.tfplan 2>&1" | Tee-Object "$ev\2-org_plan.txt"
```

**Read the plan before applying.** You should see:

- the organisation: **update in-place** only (switching on SCPs and trusted access). If it says *destroy* or *replace*, stop
- in that update, no lines starting with `-` under `aws_service_access_principals` or `enabled_policy_types`. Terraform turns off anything not in [organization.tf](../infrastructure/solution-a/landing-zone/1-organization/organization.tf), so a `-` means something switched on by hand would be switched off. If you see one, add it to the list in that file and plan again
- 5 `aws_organizations_account` and 5 organisational units to add
- 4 policies and 4 attachments (the guardrails)
- permission sets and account assignments (who can sign in where)
- GuardDuty, Security Hub, Config and Access Analyzer handed to the Security account

```powershell
cmd /c "terraform apply -no-color org.tfplan 2>&1" | Tee-Object "$ev\2-org_apply.txt"   # 10 to 20 minutes
$ids = terraform output -json account_ids | ConvertFrom-Json
$ids
aws organizations list-accounts --query "Accounts[].[Name,Id,Status]" --output table | Tee-Object "$ev\2-org_accounts.txt"
```

All 5 new accounts should show `ACTIVE`. Refresh the access portal: under
`max.gosling` you now see all six accounts.

---

## 3. Security account

If this fails with `AccessDenied` assuming `OrganizationAccountAccessRole`,
the new account is still settling. Wait five minutes and run it again.

```powershell
cd "$lz\2-security"
terraform init
cmd /c "terraform plan -no-color -var security_account_id=$($ids.security) -out security.tfplan 2>&1" | Tee-Object "$ev\3-security_plan.txt"
cmd /c "terraform apply -no-color security.tfplan 2>&1" | Tee-Object "$ev\3-security_apply.txt"
$cfgBucket = terraform output -raw config_bucket_name
$cfgKey    = terraform output -raw config_kms_key_arn
```

This also adds the other four Cobble accounts as members of both GuardDuty
and Security Hub. Their auto-enable settings only cover accounts that join
later, and these already exist.

**Afterwards:** in the `n11543027@qut.edu.au` inbox, open "AWS Notification
- Subscription Confirmation" and click **Confirm subscription**. Otherwise no
alerts arrive.

> [!NOTE]
> This step also applies the account safety settings to the management account: a stricter IAM password policy, S3 public access block and default EBS encryption. The password policy applies to the team's existing IAM users the next time they change their password. Step 7 removes all three.

---

## 4. Dev environment

The committed `dev.tfvars`, plus demo values on the command line:

| Value | Why |
|---|---|
| `account_id`, `config_bucket_name`, `config_kms_key_arn` | From steps 2 and 3 |
| `assume_role_name=OrganizationAccountAccessRole` | You're running it from the management account |
| `container_image` = stock nginx, `read_only_root_filesystem=false` | No registry, because step 3 is skipped |
| `enable_github_deploy=false` | GitHub's deploy roles aren't needed for a demo |
| `app_max_count=2` | Shows auto scaling, as in the single-account demo |
| `alert_email=n11543027@qut.edu.au` | Budget alerts go to the same inbox as security alerts for now |

```powershell
cd "$repo\infrastructure\solution-a\workload"
terraform init -reconfigure -backend-config="key=solution-a/workload/dev/terraform.tfstate"

$devArgs = "-var-file=dev.tfvars -var account_id=$($ids.dev) -var assume_role_name=OrganizationAccountAccessRole -var container_image=public.ecr.aws/nginx/nginx:stable -var read_only_root_filesystem=false -var enable_github_deploy=false -var app_max_count=2 -var alert_email=n11543027@qut.edu.au -var config_bucket_name=$cfgBucket -var config_kms_key_arn=$cfgKey"

cmd /c "terraform plan -no-color $devArgs -out dev.tfplan 2>&1" | Tee-Object "$ev\4-dev_plan.txt"
cmd /c "terraform apply -no-color dev.tfplan 2>&1"              | Tee-Object "$ev\4-dev_apply.txt"   # 10 to 15 minutes
terraform output app_url
```

Open `app_url`. You should see the nginx page. A 503 at first means the web
server is still starting, so wait a minute.

---

## 5. What to record

Sign in through the **access portal as `max.gosling`** for the console tour,
not the IAM user. That's the point being shown. The portal address is in
IAM Identity Center > Settings > *AWS access portal URL*. Sign in with the
username, not the email, and the password and MFA device set in
[step 1](#1-people-single-sign-on). If the password is lost, use **Forgot
password** on the sign-in page, or IAM Identity Center > Users >
`max.gosling` > **Reset password** as the management admin.

In the portal, expand an account and click a role to open its console. Use
**CobbleReadOnly** for the tour and **CobblePlatformAdmin** only where a
row says so. Keep the region on Sydney unless told otherwise.

| Where | Show | What it proves |
|---|---|---|
| Organizations > AWS accounts (management account) | The folder tree: Security, Infrastructure, Workloads > NonProduction / Production, each with its account | Separate accounts per purpose and environment (D2) |
| Organizations > Policies > Service control policies | The 4 guardrails attached to Root | Guardrails cover every member account (D2, D3) |
| **A guardrail blocking an admin** | Portal > `cobble-dev` > `CobblePlatformAdmin`. Switch the region to US West (Oregon) and try to create an S3 bucket | "Explicit deny in a service control policy": even a full administrator can't work outside the allowed regions |
| IAM Identity Center | The `cobble-` groups, the 3 permission sets, MFA required | Single sign-on with MFA, no shared IAM users (D3) |
| Portal > `cobble-security` | CloudTrail: the organisation trail. S3: `cobble-audit-logs-<security account ID>` > Properties > Object Lock (the bucket is in this account, not the management account). GuardDuty > Accounts: the four other Cobble accounts enrolled. Security Hub: both standards (findings fill in over the next hours), and Settings > Accounts listing the Cobble accounts as members. Config > Aggregators: all accounts | Central, tamper-resistant logging and detection across the organisation (D3) |
| Portal > `cobble-dev` | VPC: six subnets in three layers. ECS: the web server has a private IP only. RDS: "Publicly accessible: No", encrypted. Secrets Manager: the database password. S3: encrypted, versioned data bucket. Budgets: the US$100 dev budget | The workload design running in its own account (D1, D4) |
| `app_url` in a browser | The page loads through the load balancer | The environment works end to end |

**Optional: show an alert arriving.** The finding must be created in the
**Security account**. One made in the management account stays there: that
account doesn't report to Security, so nothing is emailed.

1. In the access portal, expand `cobble-security` and click
   **CobblePlatformAdmin** (ReadOnly can't create findings).
2. Check the console shows Sydney, then open **CloudShell** (the `>_` icon
   in the top bar).
3. Create a high-severity sample finding:

   ```bash
   aws guardduty create-sample-findings \
     --detector-id $(aws guardduty list-detectors --query 'DetectorIds[0]' --output text) \
     --finding-types 'Backdoor:EC2/C&CActivity.B!DNS'
   ```

   No output means it worked.

   **Or from the runbook's PowerShell window.** That window is signed in to
   the management account, so switch into Security first, and back after.
   The bash command above doesn't work in PowerShell.

   ```powershell
   $c = aws sts assume-role --role-arn "arn:aws:iam::$($ids.security):role/OrganizationAccountAccessRole" --role-session-name sample-finding --query Credentials --output json | ConvertFrom-Json
   $env:AWS_ACCESS_KEY_ID = $c.AccessKeyId; $env:AWS_SECRET_ACCESS_KEY = $c.SecretAccessKey; $env:AWS_SESSION_TOKEN = $c.SessionToken

   aws sts get-caller-identity --query Account --output text    # must print the Security account ID
   $det = aws guardduty list-detectors --region ap-southeast-2 --query 'DetectorIds[0]' --output text
   aws guardduty create-sample-findings --region ap-southeast-2 --detector-id $det --finding-types 'Backdoor:EC2/C&CActivity.B!DNS'

   Remove-Item Env:AWS_ACCESS_KEY_ID, Env:AWS_SECRET_ACCESS_KEY, Env:AWS_SESSION_TOKEN   # back to the management account
   ```

4. GuardDuty > Findings shows `[SAMPLE] Backdoor:EC2/C&CActivity.B!DNS`
   straight away. Within about 15 minutes it reaches Security Hub and is
   emailed to `n11543027@qut.edu.au`.

To show it again, use a different type. Running the same type again only
updates the existing finding. These are all high severity, so each one sends
an email:

- `CryptoCurrency:EC2/BitcoinTool.B!DNS`
- `Trojan:EC2/DNSDataExfiltration`
- `UnauthorizedAccess:EC2/MaliciousIPCaller.Custom`

You might also get emails you didn't trigger, such as "AWS Config should be
enabled" for `cobble-prod`, `cobble-staging` and `cobble-shared-services`.
They're real findings. Those accounts have no Config recorder because only
dev is deployed, so they're expected in this demo.

---

## 6. Evidence

`$ev` now holds the plan and apply log for every step. Before committing the
logs, skim them: they hold account IDs and email addresses, which are fine in
this private repo but nothing else should be in there. Never commit the
`*.tfplan` files (`.gitignore` already blocks them).

Also screenshot the console views from step 5. Save them in
`docs/04-iac-evidence/images/` and blur account IDs, email addresses and
ARNs first. Grouped by where you sign in, so you switch as little as
possible:

| Portal sign-in | File | Where | Must be visible |
|---|---|---|---|
| Portal home | `01-portal-accounts.png` | After signing in | All 6 accounts, one expanded to show its roles |
| Management, ReadOnly | `02-idc-groups.png` | IAM Identity Center > Groups | The 3 `cobble-` groups |
| | `02b-idc-users.png` | IAM Identity Center > Users | The `max.gosling` user |
| | `03-idc-permission-sets.png` | IAM Identity Center > Permission sets | The 3 `Cobble` permission sets |
| | `04-idc-mfa.png` | IAM Identity Center > Settings > Authentication | MFA required, email OTP on |
| | `05-org-tree.png` | Organizations > AWS accounts (hierarchy) | The folders, each with its account |
| | `06-scps.png` | Organizations > Policies > Service control policies | The 4 guardrails |
| | `06b-org-policy-types.png` | Organizations > Policies | Service control policies enabled |
| | `07-scps-root-targets.png` | Root > Policies tab | All 4 attached to Root |
| `cobble-dev`, **PlatformAdmin** | `08-scp-deny.png` | Region US West (Oregon) > S3 > Create bucket | The SCP explicit-deny error, with role and region in view |
| `cobble-security`, ReadOnly | `09-cloudtrail-org-trail.png` | CloudTrail > Trails | Organisation trail, multi-region, log file validation on |
| | `10-s3-object-lock.png` | S3 > `cobble-audit-logs-…` > Properties | Object Lock enabled, with retention |
| | `11-guardduty-accounts.png` | GuardDuty > Accounts | The 4 other Cobble accounts, Enabled |
| | `12-securityhub-standards.png` | Security Hub > Security standards | Both standards enabled |
| | `12b-securityhub-summary.png` | Security Hub > Summary | Findings across accounts |
| | `13-securityhub-members.png` | Security Hub > Settings > Accounts | The Cobble accounts as members |
| | `14-config-aggregator.png` | Config > Aggregators | All accounts |
| | `15-sample-finding.png` | GuardDuty > Findings | The `[SAMPLE]` finding (optional) |
| | `15b-sample-finding-cli.png` | PowerShell or CloudShell | The `create-sample-findings` command (optional) |
| Email | `16-alert-email.png` | `n11543027@qut.edu.au` inbox | The alert for that finding (optional) |
| `cobble-dev`, ReadOnly | `17-vpc-subnets.png` | VPC > Subnets | 6 subnets in 3 layers |
| | `18-vpc-flow-logs.png` | VPC > dev VPC > Flow logs | Flow log active |
| | `19-ecs-cluster-tasks.png` | ECS > cluster > service > Tasks, then a task's Networking | Tasks running, private IP only |
| | `20-ecs-autoscaling.png` | ECS > service > auto scaling | Max 2 tasks |
| | `21-rds-connectivity.png` | RDS > database > Connectivity & security | Publicly accessible: No |
| | `22-rds-encryption.png` | RDS > database > Configuration | Encryption on, with the KMS key |
| | `23-secrets-db.png` | Secrets Manager | The database secret (don't show its value) |
| | `24-s3-data-props.png` | S3 > data bucket > Properties | KMS encryption, versioning on |
| | `25-s3-data-perms.png` | S3 > data bucket > Permissions | Block all public access: On |
| | `26-budget.png` | Billing > Budgets | The dev budget and its alert |
| Browser | `27-app-url.png` | `terraform output app_url` | The page, with the load balancer address visible |
| GitHub | `28-ci-green.png` | Actions | A green run on `main` |
| Management, ReadOnly | `29-cost-explorer.png` | Cost Explorer, the next day ([7.7](#7-tear-down-same-day)) | Cost of the demo day |
| | `30-accounts-closed.png` | Organizations, after [7.4](#7-tear-down-same-day) | The 5 accounts closed |
| Terminal | `31-teardown-dev.png`, `32-teardown-security.png`, `33-teardown-org.png` | After [7.1](#7-tear-down-same-day) to 7.3 | Each `Apply complete! ... destroyed` line |

If Budgets or Cost Explorer refuse access under ReadOnly, use PlatformAdmin
for that shot.

---

## 7. Tear down (same day)

Do these in order. Each one removes something the next one depends on.

**7.1 Dev environment**

```powershell
cd "$repo\infrastructure\solution-a\workload"
cmd /c "terraform plan -destroy -no-color $devArgs -out dev-destroy.tfplan 2>&1" | Tee-Object "$ev\7-dev_destroy-plan.txt"
cmd /c "terraform apply -no-color dev-destroy.tfplan 2>&1"                       | Tee-Object "$ev\7-dev_destroy.txt"
terraform state list    # should print nothing
```

**7.2 Security step: only the parts in the management account.** These are
the organisation trail and the management account's safety settings.
Everything else lives inside the Security account and goes when that
account is closed. The locked audit bucket refuses deletion anyway, by
design.

```powershell
cd "$lz\2-security"
cmd /c "terraform plan -destroy -no-color -var security_account_id=$($ids.security) -target=aws_cloudtrail.organization -target=module.management_account_baseline -out security-destroy.tfplan 2>&1" | Tee-Object "$ev\7-security_destroy-plan.txt"
cmd /c "terraform apply -no-color security-destroy.tfplan 2>&1" | Tee-Object "$ev\7-security_destroy.txt"
```

**7.3 Organisation step: everything except the organisation, folders and
accounts.** This removes the guardrails, the sign-in roles, the security
delegation, and GuardDuty and Security Hub in the management account.

```powershell
cd "$lz\1-organization"
$targets = "-target=aws_organizations_policy_attachment.guardrail -target=aws_organizations_policy.guardrail -target=aws_ssoadmin_account_assignment.this -target=aws_ssoadmin_managed_policy_attachment.this -target=aws_ssoadmin_permission_set.this -target=aws_guardduty_organization_admin_account.this -target=aws_securityhub_organization_admin_account.this -target=aws_organizations_delegated_administrator.config -target=aws_organizations_delegated_administrator.access_analyzer -target=aws_guardduty_detector.management -target=aws_securityhub_account.management"
cmd /c "terraform plan -destroy -no-color $targets -out org-destroy.tfplan 2>&1" | Tee-Object "$ev\7-org_destroy-plan.txt"
```

**Check the plan:** it must not list `aws_organizations_organization`,
`aws_organizations_account` or `aws_organizations_organizational_unit`.
Then:

```powershell
cmd /c "terraform apply -no-color org-destroy.tfplan 2>&1" | Tee-Object "$ev\7-org_destroy.txt"
```

**7.4 Close the 5 accounts.** This stops their charges.

```powershell
foreach ($name in "dev","staging","prod","shared_services","security") {
  aws organizations close-account --account-id $ids.$name
  Start-Sleep -Seconds 30
}
aws organizations list-accounts --query "Accounts[].[Name,Id,Status]" --output table | Tee-Object "$ev\7-accounts_closed.txt"
terraform state rm aws_organizations_account.this   # stop Terraform tracking the closed accounts
```

They show as `SUSPENDED`, or `CLOSED` in the console. If AWS says too many
requests, wait a minute and close the rest.

**7.5 People (optional).** Removes the `max.gosling` login and the groups:

```powershell
cd "$lz\identity"
terraform plan -destroy -out people-destroy.tfplan
terraform apply people-destroy.tfplan
```

**7.6 Give GuardDuty back to Solution B.** Set `enable_guardduty = true` in
`infrastructure/solution-b/poc.auto.tfvars`, then plan and apply in that
folder.

**7.7 Next day:** check Billing > Bills, and screenshot Cost Explorer for the
demo day as cost evidence.

---

## If you closed the PowerShell window

Recreate the saved values:

```powershell
$repo = "C:\Users\maxgo\dev\IFB398---Cobble-AWS---T235"
$lz   = "$repo\infrastructure\solution-a\landing-zone"
$ev   = "$repo\infrastructure\solution-a\evidence"
$ids       = terraform -chdir="$lz\1-organization" output -json account_ids | ConvertFrom-Json
$cfgBucket = terraform -chdir="$lz\2-security" output -raw config_bucket_name
$cfgKey    = terraform -chdir="$lz\2-security" output -raw config_kms_key_arn
$devArgs   = "-var-file=dev.tfvars -var account_id=$($ids.dev) -var assume_role_name=OrganizationAccountAccessRole -var container_image=public.ecr.aws/nginx/nginx:stable -var read_only_root_filesystem=false -var enable_github_deploy=false -var app_max_count=2 -var alert_email=n11543027@qut.edu.au -var config_bucket_name=$cfgBucket -var config_kms_key_arn=$cfgKey"
```

---

## If something goes wrong

| Symptom | Step | Cause | Fix |
|---|---|---|---|
| GuardDuty detector already exists | 2 | Solution B still has GuardDuty on | Do the Solution B item in [step 0](#0-before-you-start) |
| Security Hub already enabled | 2 | It was switched on by hand earlier | `terraform import aws_securityhub_account.management 669591255093`, then plan again |
| Account limit reached | 2 | Organisation quota too low | Request an increase in Service Quotas, wait, apply again |
| Email address already in use | 2 | That plus address belongs to another AWS account | Change it in `1-organization/settings.auto.tfvars` (e.g. `+dev2`) |
| `AccessDenied` assuming `OrganizationAccountAccessRole` | 3, 4 | New account still settling | Wait five minutes and retry |
| `aws_ssoadmin_instances` returns nothing | 1, 2 | Identity Center not enabled | Enable it in the console |
| A `cobble-` group or user already exists | 1 | Added by hand earlier | Delete it in the console, or import it |
| Sample finding never shows in `cobble-security` | 5 | It was created in another account, usually the management account | Create it in `cobble-security`, from CloudShell or the PowerShell block in [step 5](#5-what-to-record) |
| `Missing expression after unary operator '--'` | 5 | The bash command (with `\` line breaks) was pasted into PowerShell | Use the PowerShell block in [step 5](#5-what-to-record), or run the bash one in CloudShell |
| GuardDuty > Accounts in `cobble-security` lists no members | 3 | Step 3 applied before the GuardDuty member resources existed | Plan and apply step 3 again: it adds the 4 accounts as members |
| GuardDuty banner: management account "has not allowed the delegated administrator" for Malware Protection | 5 | Optional add-on, not used here | Ignore it, or run `aws iam create-service-linked-role --aws-service-name malware-protection.guardduty.amazonaws.com` once as the management admin |
| 503 from `app_url` for more than 5 minutes | 4 | Web server not starting | ECS > the service > Tasks > a stopped task: read the reason |
| Tear down 7.3 lists an account or the organisation | 7 | Wrong targets | Don't apply. Re-run the plan exactly as written |
