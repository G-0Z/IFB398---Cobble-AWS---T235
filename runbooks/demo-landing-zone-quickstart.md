# Quickstart: run the landing zone demo

One script builds the landing zone with a working dev environment, and one
command removes it again. The AWS accounts are reused every time: nothing
here creates or closes an account.

| | |
|---|---|
| **Build** | `.\lz-dev.ps1 up`: about 15 minutes (13 on 18 October 2026, mostly the database), a few minutes if it's already up |
| **Remove** | `.\lz-dev.ps1 down`: about 10 minutes |
| **Cost** | About A$0.35 an hour while it's up, nothing after `down` |

This is the Solution A demo we show. The 18 October 2026 run (up, console
tour, down) was recorded, and its logs are
[`lz-dev-up-20261018-2147.txt`](../infrastructure/solution-a/evidence/lz-dev-up-20261018-2147.txt)
and
[`lz-dev-down-20261018-2219.txt`](../infrastructure/solution-a/evidence/lz-dev-down-20261018-2219.txt).

For what each step does, or to run it by hand, see the
[full runbook](demo-landing-zone-dev.md).

---

## 1. Set up your computer (once)

1. Install [Terraform](https://developer.hashicorp.com/terraform/install) 1.10 or later and the [AWS CLI](https://aws.amazon.com/cli/).
2. Clone this repository.
3. **Get the settings files from Max.** They hold email addresses and are kept off GitHub. Put each one in the folder shown:

   | File | Folder |
   |---|---|
   | `settings.auto.tfvars` and `users.csv` | `infrastructure/solution-a/landing-zone/identity/` |
   | `settings.auto.tfvars` | `infrastructure/solution-a/landing-zone/1-organization/` |
   | `settings.auto.tfvars` | `infrastructure/solution-a/landing-zone/2-security/` |

   If one is missing, the script stops and names it.

4. **Set up your AWS sign-in.** You need the `AdministratorAccess` role on the management account (`669591255093`) in IAM Identity Center. Ask Max if you don't have it. Then, in PowerShell:

   ```powershell
   aws configure sso
   ```

   Enter the start URL `https://d-97679ebd7b.awsapps.com/start` and the region `ap-southeast-2`. Pick account `669591255093` and the `AdministratorAccess` role. Accept the suggested profile name, `AdministratorAccess-669591255093`.

## 2. Build it

Open PowerShell and run:

```powershell
aws sso login --profile AdministratorAccess-669591255093
cd <where you cloned it>\infrastructure\solution-a
Set-ExecutionPolicy -Scope Process Bypass      # lets this window run the script
.\lz-dev.ps1 up
```

Leave it running. It finishes with:

```text
Up. App: http://cobble-dev-alb-....elb.amazonaws.com
```

If it stops with an error instead, see [If it stops](#if-it-stops).

**After the first build only:** open the email "AWS Notification -
Subscription Confirmation" in the `n11543027@qut.edu.au` inbox and click
**Confirm subscription**. Otherwise no security alerts arrive. `down` deletes
this subscription, so confirm again after every build.

## 3. Check it's working

| Check | How | Working if |
|---|---|---|
| The website | Open the `App:` address in a browser | The nginx welcome page loads. A 503 means it's still starting: wait a minute |
| The security services | `.\lz-dev.ps1 status` | Every account shows `GuardDuty: True` and `SecurityHub: True`. `Config` is True for dev and security only, which is expected |
| The console | Sign in at https://d-97679ebd7b.awsapps.com/start, expand an account, click **CobblePlatformAdmin** | The 5 accounts are listed (4 Cobble accounts and the management account) and you can open each one |

Click the role that matches your group. Platform admins (`max.gosling`) get
**CobblePlatformAdmin** everywhere. **CobbleReadOnly** belongs to the
auditors group: if you're not in it, it shows "Account sign in error … No
access", which is the access control working, not a fault.

Keep the console region on **Asia Pacific (Sydney)**. In any other region
the buckets and services look missing, and S3 shows "can't be found in the
US East (Ohio) region" before redirecting.

For what to show in the console, see
[What to record](demo-landing-zone-dev.md#5-what-to-record).

## 4. Remove it

**Always do this after the demo**, or it keeps costing money.

```powershell
aws sso login --profile AdministratorAccess-669591255093   # if it's been a few hours
.\lz-dev.ps1 down
```

It ends with a table. **Every column must read `False`.** If one says
`True`, run `.\lz-dev.ps1 down` again.

The accounts, sign-in and guardrails stay. They're free, and the next
`up` reuses them.

---

## If it stops

The error names a log file in `infrastructure/solution-a/evidence/`.
Open it and look at the last `Error:` line.

| Message | What to do |
|---|---|
| `Missing settings files` | Get the named files from Max (see [step 1](#1-set-up-your-computer-once)) |
| `Signed in to '…', not 669591255093`, or `token has expired` | Run `aws sso login --profile AdministratorAccess-669591255093`, then run the same command again |
| `Detach the hand-made SCP first` | Run the command the message shows, then run `up` again |
| `Step 2 plan would delete …` | Stop and ask Max. Someone changed the organisation by hand |
| `AccessDenied` assuming `OrganizationAccountAccessRole` | An account is still settling. Wait five minutes and run it again |
| `cannot be loaded because running scripts is disabled` | Run `Set-ExecutionPolicy -Scope Process Bypass` in that window first |
| `BucketNotEmpty` during `down` | Run `.\lz-dev.ps1 down` again |
| Anything else | Run the same command again. Both `up` and `down` pick up where they stopped. If it fails the same way twice, check the full runbook's [troubleshooting table](demo-landing-zone-dev.md#if-something-goes-wrong) |
