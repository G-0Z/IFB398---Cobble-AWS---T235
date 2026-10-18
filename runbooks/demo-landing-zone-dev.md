# Runbook: demo the Solution A landing zone with one environment (dev)

**What it does:** builds the real Solution A landing zone in the team's
organisation (`o-b60hme0nfl`, managed from `669591255093`) and one
environment (dev) inside it, so it can be recorded. Then it tears down
everything that costs money, leaving the empty accounts ready for the next
run.

Unlike the [single-account demo](demo-solution-a.md), this shows the parts
that need an organisation: separate accounts, guardrails that block even an
administrator, single sign-on, and central security.

> [!IMPORTANT]
> **This creates 5 real AWS accounts, once.** They are permanent: the teardown empties them but never closes them. Closing an account burns its email address for good and keeps it counted against the organisation's 10-account limit for 90 days, which is what broke earlier re-runs. Close them only when the project ends ([Decommission](#decommission-end-of-project-only)).

> [!NOTE]
> **For now there are 4, not 5.** `cobble-shared-services` is left out of `1-organization/settings.auto.tfvars`: the 5 accounts closed on 2026-10-17 fill the organisation's 10-account limit until about 2027-01-15, and this demo doesn't use that account. Wherever this runbook says 5 accounts (6 with management), read 4 (5). To add it later, uncomment its email and re-run step 2.

| | |
|---|---|
| **Builds** | Single sign-on for one person, 5 member accounts in their folders, 4 guardrails, central audit trail, GuardDuty, Security Hub, Config, alerts, and the dev environment (network, web server, database, data bucket) |
| **Skips** | Step 3 (container registry): dev runs a stock nginx image instead. Staging and prod environments: their accounts are created, but nothing is deployed in them |
| **Time** | First run: about half a day, mostly waiting for AWS. Re-runs: about an hour (steps 3 and 4 only) |
| **Cost** | About A$0.30 to A$0.40 an hour while it's up, so roughly A$10 to A$15 for the session. Nothing after the teardown |

**Which parts stay, which come and go:**

| Step | Builds | Torn down after each demo? |
|---|---|---|
| 1. People | Groups and your login | No. Free |
| 2. Organisation | Account folders, the 5 accounts, guardrails, who can sign in where | No. Free, and the accounts can't be recreated cheaply |
| 3. Security | Audit trail, log buckets, GuardDuty, Security Hub, Config, alerts | Yes: `terraform destroy` |
| 4. Dev | The dev environment | Yes: `terraform destroy` |

Re-running steps 1 and 2 is always safe: with nothing changed, their plans
show `No changes`.

Every step ends with a **Check**. Don't start the next step until it
passes. Each one re-plans the step (exit code `0` means what's in AWS
matches the code exactly) and then asks AWS directly.

The settings files are already filled in. They're kept off GitHub by
`.gitignore`:

| File | Holds |
|---|---|
| `landing-zone/identity/settings.auto.tfvars` | The management account ID |
| `landing-zone/identity/users.csv` | One login: `max.gosling`, emailed at `t235cobbleaws+max@gmail.com`. Add teammates as extra rows if wanted |
| `landing-zone/1-organization/settings.auto.tfvars` | The management account ID and an email for each new account (`t235cobbleaws+security2@gmail.com` and so on: the `+…` addresses without a 2 belong to closed accounts and can't be reused) |
| `landing-zone/2-security/settings.auto.tfvars` | The security alert email (`n11543027@qut.edu.au` for now), a 1-day audit log lock, deletable log buckets, and Solution B keeping the management account's GuardDuty |

Dev uses the committed `workload/dev.tfvars`, with a few demo values set on
the command line in [step 4](#4-dev-environment), including sending its
budget alerts to `n11543027@qut.edu.au`.

---

## 0. Before you start

**Re-run?** Do this step (sign in, set the values), then skip to
[Running it again](#running-it-again).

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
- [ ] **Room for any accounts still missing.** Closed (`SUSPENDED`) accounts count against the limit for 90 days. Compare the limit with the total, then add the Cobble accounts not yet created:

  ```powershell
  aws service-quotas get-service-quota --service-code organizations --quota-code L-E619E033 --region us-east-1 --query Quota.Value
  aws organizations list-accounts --query "length(Accounts)"
  ```

  If there isn't room: `aws service-quotas request-service-quota-increase --service-code organizations --quota-code L-E619E033 --desired-value 15 --region us-east-1`, and wait for it to be approved (hours to days)
- [ ] **No stale delegated administrator.** `aws organizations list-delegated-administrators --query "DelegatedAdministrators[].[Id,Name,Status]" --output table` must show nothing, or only the `ACTIVE` `cobble-security`. A `SUSPENDED` one (a closed account) blocks step 3. Remove it, then check again (GuardDuty's and Security Hub's own "disable admin" commands report it as already gone, but Organizations still holds it):

  ```powershell
  foreach ($s in "guardduty.amazonaws.com", "securityhub.amazonaws.com", "config.amazonaws.com", "access-analyzer.amazonaws.com") {
    aws organizations deregister-delegated-administrator --account-id <id> --service-principal $s   # "not registered" errors are fine
  }
  ```

Solution B keeps the management account's GuardDuty detector the whole
time (`enable_management_guardduty = false` in `2-security/settings.auto.tfvars`),
so nothing has to be handed over between the two.

Then set up the values and the helper the rest of the runbook uses:

```powershell
$repo = "C:\Users\maxgo\dev\IFB398---Cobble-AWS---T235"
$lz   = "$repo\infrastructure\solution-a\landing-zone"
$ev   = "$repo\infrastructure\solution-a\evidence"
$env:AWS_REGION = "ap-southeast-2"
New-Item -ItemType Directory -Force $ev | Out-Null

# Runs a block of commands inside a member account, then switches back to the management account.
function Invoke-InAccount($account, [scriptblock]$do) {
  $c = aws sts assume-role --role-arn "arn:aws:iam::${account}:role/OrganizationAccountAccessRole" --role-session-name runbook --query Credentials --output json | ConvertFrom-Json
  $env:AWS_ACCESS_KEY_ID = $c.AccessKeyId; $env:AWS_SECRET_ACCESS_KEY = $c.SecretAccessKey; $env:AWS_SESSION_TOKEN = $c.SessionToken
  try { & $do } finally { Remove-Item Env:AWS_ACCESS_KEY_ID, Env:AWS_SECRET_ACCESS_KEY, Env:AWS_SESSION_TOKEN }
}
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

If one exists but `terraform state list` doesn't show it, import it rather
than deleting it (deleting a group drops its account access):

```powershell
terraform import 'aws_identitystore_group.this[\"platform-admins\"]' "$store/<GroupId>"   # likewise developers, auditors
terraform import 'aws_identitystore_user.this[\"max.gosling\"]'      "$store/<UserId>"
```

```powershell
cmd /c "terraform plan -no-color -out people.tfplan 2>&1"  | Tee-Object "$ev\1-people_plan.txt"   # 3 groups, 1 user, 1 membership
cmd /c "terraform apply -no-color people.tfplan 2>&1"      | Tee-Object "$ev\1-people_apply.txt"
```

**Check:**

```powershell
terraform plan -detailed-exitcode -no-color > $null; $LASTEXITCODE   # 0
$store = aws sso-admin list-instances --query "Instances[0].IdentityStoreId" --output text
aws identitystore list-groups --identity-store-id $store --query "Groups[?starts_with(DisplayName,'cobble-')].DisplayName"   # the 3 cobble- groups
```

**Afterwards:** open the AWS access portal (IAM Identity Center > Settings >
*AWS access portal URL*). Sign in as `max.gosling`. The one-time code goes to
the team inbox. Set a password and an MFA device. You'll see no accounts yet:
step 2 grants them.

---

## 2. Organisation, accounts and guardrails

**The first run creates the 5 accounts. They are permanent.**

```powershell
cd "$lz\1-organization"
terraform init
# Brings the existing organisation under Terraform once; does nothing if it already is.
if (-not (terraform state list | Select-String -SimpleMatch 'aws_organizations_organization.this')) { terraform import aws_organizations_organization.this o-b60hme0nfl }
cmd /c "terraform plan -no-color -out org.tfplan 2>&1" | Tee-Object "$ev\2-org_plan.txt"
```

**Read the plan before applying.** On a re-run it should say `No changes`.
On the first run you should see:

- the organisation: **update in-place** only (switching on SCPs and trusted access). If it says *destroy* or *replace*, stop
- in that update, no lines starting with `-` under `aws_service_access_principals` or `enabled_policy_types`. Terraform turns off anything not in [organization.tf](../infrastructure/solution-a/landing-zone/1-organization/organization.tf), so a `-` means something switched on by hand would be switched off. If you see one, add it to the list in that file and plan again
- 5 `aws_organizations_account` and 5 organisational units to add
- 4 policies and 4 attachments (the guardrails)
- permission sets and account assignments (who can sign in where)

```powershell
cmd /c "terraform apply -no-color org.tfplan 2>&1" | Tee-Object "$ev\2-org_apply.txt"   # 10 to 20 minutes the first time
$ids = terraform output -json account_ids | ConvertFrom-Json
$ids
aws organizations list-accounts --query "Accounts[?Status=='ACTIVE'].[Name,Id]" --output table | Tee-Object "$ev\2-org_accounts.txt"
```

All 5 accounts should be listed, with the IDs in `$ids`. Refresh the access
portal: under `max.gosling` you now see all six accounts.

**Check:**

```powershell
terraform plan -detailed-exitcode -no-color > $null; $LASTEXITCODE   # 0
$ids.PSObject.Properties.Name   # dev, prod, security, staging (and shared_services once it's created)
$root = aws organizations list-roots --query "Roots[0].Id" --output text
aws organizations list-policies-for-target --target-id $root --filter SERVICE_CONTROL_POLICY --query "Policies[].Name"   # the 4 guardrails (plus AWS's FullAWSAccess)
```

---

## 3. Security account

If this fails with `AccessDenied` assuming `OrganizationAccountAccessRole`,
the new account is still settling. Wait five minutes and run it again.

If `$lz` or `$ev` is empty (new PowerShell window), run
[If you closed the PowerShell window](#if-you-closed-the-powershell-window) first.

```powershell
cd "$lz\2-security"
$ids = terraform -chdir="$lz\1-organization" output -json account_ids | ConvertFrom-Json
$ids.security   # must print a 12-digit ID; if blank, step 2 hasn't been applied
terraform init
cmd /c "terraform plan -no-color -var security_account_id=$($ids.security) -out security.tfplan 2>&1" | Tee-Object "$ev\3-security_plan.txt"
cmd /c "terraform apply -no-color security.tfplan 2>&1" | Tee-Object "$ev\3-security_apply.txt"
$cfgBucket = terraform output -raw config_bucket_name
$cfgKey    = terraform output -raw config_kms_key_arn
```

This also makes the Security account the delegated administrator for
GuardDuty, Security Hub, Config and Access Analyzer, and adds the other four
Cobble accounts as members of GuardDuty and Security Hub. Their auto-enable
settings only cover accounts that join later, and these already exist.

**Check:**

```powershell
cmd /c "terraform plan -detailed-exitcode -no-color -var security_account_id=$($ids.security) > nul 2>&1"; $LASTEXITCODE   # 0
aws guardduty list-organization-admin-accounts --query "AdminAccounts[].AdminAccountId"     # only $ids.security
aws securityhub list-organization-admin-accounts --query "AdminAccounts[].AccountId"        # only $ids.security
Invoke-InAccount $ids.security { aws guardduty list-members --detector-id (aws guardduty list-detectors --query "DetectorIds[0]" --output text) --query "Members[].[AccountId,RelationshipStatus]" --output table }   # the other Cobble accounts, Enabled
```

**Afterwards:** in the `n11543027@qut.edu.au` inbox, open "AWS Notification
- Subscription Confirmation" and click **Confirm subscription**. Otherwise no
alerts arrive. The teardown deletes the topic, so confirm again after every
rebuild.

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

**Check:**

```powershell
cmd /c "terraform plan -detailed-exitcode -no-color $devArgs > nul 2>&1"; $LASTEXITCODE   # 0
(Invoke-WebRequest (terraform output -raw app_url) -UseBasicParsing).StatusCode           # 200
```

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
   the management account, so run it inside Security. The bash command
   above doesn't work in PowerShell.

   ```powershell
   Invoke-InAccount $ids.security {
     aws sts get-caller-identity --query Account --output text    # must print the Security account ID
     $det = aws guardduty list-detectors --query 'DetectorIds[0]' --output text
     aws guardduty create-sample-findings --detector-id $det --finding-types 'Backdoor:EC2/C&CActivity.B!DNS'
   }
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
| Management, ReadOnly | `29-cost-explorer.png` | Cost Explorer, the next day ([7.4](#7-tear-down-same-day)) | Cost of the demo day |
| Terminal | `31-teardown-dev.png`, `32-teardown-security.png` | After [7.1](#7-tear-down-same-day) and 7.2 | Each `Apply complete! ... destroyed` line |

If Budgets or Cost Explorer refuse access under ReadOnly, use PlatformAdmin
for that shot.

---

## 7. Tear down (same day)

Two destroys, newest first. The accounts, folders, guardrails and sign-in
stay: they cost nothing, and the next run reuses them.

**7.1 Dev environment**

```powershell
cd "$repo\infrastructure\solution-a\workload"
cmd /c "terraform plan -destroy -no-color $devArgs -out dev-destroy.tfplan 2>&1" | Tee-Object "$ev\7-dev_destroy-plan.txt"
cmd /c "terraform apply -no-color dev-destroy.tfplan 2>&1"                       | Tee-Object "$ev\7-dev_destroy.txt"
terraform state list    # should print nothing
```

**7.2 Security.** Everything step 3 built, in both the Security and
management accounts. It hands the security services back from the Security
account first (AWS won't switch a service off in its delegated
administrator), then switches them off and deletes the log buckets, audit
logs included. `force_destroy_buckets = true` in `2-security/settings.auto.tfvars`
allows that. The audit logs are only under a 1-day GOVERNANCE lock in this
demo, which an administrator may bypass.

```powershell
cd "$lz\2-security"
cmd /c "terraform plan -destroy -no-color -var security_account_id=$($ids.security) -out security-destroy.tfplan 2>&1" | Tee-Object "$ev\7-security_destroy-plan.txt"
cmd /c "terraform apply -no-color security-destroy.tfplan 2>&1" | Tee-Object "$ev\7-security_destroy.txt"   # 5 to 10 minutes
terraform state list    # should print only data sources (data.*), or nothing
```

**Check the plan** before applying: it must not list any
`aws_organizations_account`. Step 3 doesn't manage accounts, so it can't.

**7.3 Switch off what AWS left running in the member accounts.** Handing
GuardDuty and Security Hub back only disconnects the member accounts: AWS
leaves both switched on (and billing) in each one.

```powershell
foreach ($a in $ids.dev, $ids.staging, $ids.prod, $ids.shared_services) {
  if (-not $a) { continue }
  Invoke-InAccount $a {
    foreach ($d in (aws guardduty list-detectors --query "DetectorIds" --output text) -split '\s+') { if ($d) { aws guardduty delete-detector --detector-id $d } }
    cmd /c "aws securityhub disable-security-hub 2>nul"
  }
}
```

**Check** that nothing from step 3 or 4 is still running, in any account:

```powershell
aws organizations list-delegated-administrators --query "DelegatedAdministrators[].Id"   # empty
foreach ($p in $ids.PSObject.Properties) {
  Invoke-InAccount $p.Value {
    $gd  = aws guardduty list-detectors --query "DetectorIds" --output text
    $sh  = cmd /c "aws securityhub describe-hub --query HubArn --output text 2>nul"
    $cfg = aws configservice describe-configuration-recorders --query "ConfigurationRecorders[].name" --output text
    "{0,-16} GuardDuty: {1,-6} SecurityHub: {2,-6} Config: {3}" -f $p.Name, [bool]$gd, [bool]$sh, [bool]$cfg   # all False
  }
}
```

If anything shows `True`, run 7.3 again for that account (Config: re-run
7.1 or 7.2, whichever step built it).

**7.4 Next day:** check Billing > Bills, and screenshot Cost Explorer for the
demo day as cost evidence.

---

## Running it again

Steps 1 and 2 are already in place, so a re-run is:

1. [Step 0](#0-before-you-start): sign in, run the checklist, and run the
   values block.
2. **Keep the last run's evidence.** The steps overwrite the files in
   `infrastructure/solution-a/evidence`. Commit them first, or copy them to
   a folder named after the run.
3. Load the account IDs: `$ids = terraform -chdir="$lz\1-organization" output -json account_ids | ConvertFrom-Json`
4. Optional: plan steps 1 and 2 to show they're unchanged. Each should say
   `No changes`. If one doesn't, read it: something was changed by hand.
5. [Step 3](#3-security-account), then [step 4](#4-dev-environment), as
   written. Confirm the alert email subscription again.
6. Steps 5 to 7 as before.

---

## Decommission (end of project only)

This closes the 5 accounts. **Only do it when the landing zone won't be
needed again.** Closing is effectively one-way: each account stays
`SUSPENDED` for 90 days and counts against the organisation's account limit,
and its email address can never be used again. A later rebuild needs 5 new
email addresses in `1-organization/settings.auto.tfvars`, and room for
5 more accounts under the limit.

1. Tear down as in [step 7](#7-tear-down-same-day), including its checks.
   The delegated administrator list must be empty: a closed account left
   in it blocks the next landing zone's step 3.
2. Remove the guardrails and sign-in assignments. Leave the accounts,
   folders and organisation:

   ```powershell
   cd "$lz\1-organization"
   terraform plan -destroy -target=aws_organizations_policy_attachment.guardrail -target=aws_organizations_policy.guardrail -target=aws_ssoadmin_account_assignment.this -target=aws_ssoadmin_managed_policy_attachment.this -target=aws_ssoadmin_permission_set.this -out org-destroy.tfplan
   terraform apply org-destroy.tfplan
   ```

3. Close the accounts, and stop Terraform tracking them:

   ```powershell
   foreach ($name in "dev","staging","prod","shared_services","security") {
     aws organizations close-account --account-id $ids.$name
     Start-Sleep -Seconds 30
   }
   terraform state rm aws_organizations_account.this
   ```

4. Optional: remove the people with `terraform destroy` in `$lz\identity`.

---

## If you closed the PowerShell window

Run the values block at the end of [step 0](#0-before-you-start) again
(it also defines `Invoke-InAccount`), then:

```powershell
$ids       = terraform -chdir="$lz\1-organization" output -json account_ids | ConvertFrom-Json
$cfgBucket = terraform -chdir="$lz\2-security" output -raw config_bucket_name
$cfgKey    = terraform -chdir="$lz\2-security" output -raw config_kms_key_arn
$devArgs   = "-var-file=dev.tfvars -var account_id=$($ids.dev) -var assume_role_name=OrganizationAccountAccessRole -var container_image=public.ecr.aws/nginx/nginx:stable -var read_only_root_filesystem=false -var enable_github_deploy=false -var app_max_count=2 -var alert_email=n11543027@qut.edu.au -var config_bucket_name=$cfgBucket -var config_kms_key_arn=$cfgKey"
```

---

## If something goes wrong

| Symptom | Step | Cause | Fix |
|---|---|---|---|
| GuardDuty detector already exists (management account) | 3 | `enable_management_guardduty` is `true`, but Solution B owns the detector | Set it to `false` in `2-security/settings.auto.tfvars` |
| Plan wants to destroy `aws_guardduty_detector.management` | 3 | It's left in step 3's state from an older run, but Solution B owns it | `terraform state rm aws_guardduty_detector.management` (forgets it, doesn't delete it), then plan again |
| Security Hub already enabled | 3 | It was switched on by hand earlier | In `2-security`: `terraform import -var security_account_id=$($ids.security) aws_securityhub_account.management 669591255093`, then plan again |
| "another account is already enabled as delegated administrator", or "exceeded the allowed number of delegated administrators" | 3 | An old Security account (often a closed one) is still registered | Do the delegated administrator item in [step 0](#0-before-you-start), then plan step 3 again |
| `BucketNotEmpty` during 7.2 | 7 | A last log file landed while the bucket was being emptied | Run 7.2's plan and apply again |
| `Saved plan is stale` | any | State changed after the plan was saved (e.g. an import or a second plan in between) | Run that step's `plan` again, then `apply` |
| Account limit reached | 2 | Organisation quota too low (closed accounts still count for 90 days) | Request an increase in Service Quotas, wait, apply again |
| Email address already in use | 2 | That plus address belongs to another AWS account, closed ones included | Change it in `1-organization/settings.auto.tfvars` (e.g. `+dev3`) |
| `AccessDenied` assuming `OrganizationAccountAccessRole` | 3, 4 | New account still settling | Wait five minutes and retry |
| `aws_ssoadmin_instances` returns nothing | 1, 2 | Identity Center not enabled | Enable it in the console |
| A `cobble-` group or user already exists | 1 | Added by hand, or lost from state | Import it: see [step 1](#1-people-single-sign-on) |
| Sample finding never shows in `cobble-security` | 5 | It was created in another account, usually the management account | Create it in `cobble-security`, from CloudShell or the PowerShell block in [step 5](#5-what-to-record) |
| `Missing expression after unary operator '--'` | 5 | The bash command (with `\` line breaks) was pasted into PowerShell | Use the PowerShell block in [step 5](#5-what-to-record), or run the bash one in CloudShell |
| GuardDuty > Accounts in `cobble-security` lists no members | 3 | Step 3 applied before the GuardDuty member resources existed | Plan and apply step 3 again: it adds the 4 accounts as members |
| GuardDuty banner: management account "has not allowed the delegated administrator" for Malware Protection | 5 | Optional add-on, not used here | Ignore it, or run `aws iam create-service-linked-role --aws-service-name malware-protection.guardduty.amazonaws.com` once as the management admin |
| 503 from `app_url` for more than 5 minutes | 4 | Web server not starting | ECS > the service > Tasks > a stopped task: read the reason |
