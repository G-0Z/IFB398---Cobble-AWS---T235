# Runbook: deploy Solution A (full landing zone)

**When:** once, to build the organisation in the Cyber Security Centre's
AWS management account. After that, only step 4 changes routinely (and
eventually through CI). Solution B's runbooks ([deploy.md](deploy.md),
[teardown.md](teardown.md)) are separate and unaffected.

**Time:** about half a day for steps 0 to 3, then about an hour per
environment. Creating accounts and turning on Security Hub can take several
minutes each.

## Before you start

- [ ] [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.10 and the [AWS CLI](https://aws.amazon.com/cli/)
- [ ] Signed in to the **management account** with administrator rights, never as root
- [ ] One monitored team mailbox per new account (5), plus a security-alerts mailbox
- [ ] IAM Identity Center enabled for the organisation (console: IAM Identity Center > Enable), with **MFA required** (Settings > Authentication)
- [ ] The costs in [infrastructure/README.md](../infrastructure/README.md#what-it-costs) agreed with the client

```powershell
aws sts get-caller-identity   # Account must be the management account
```

Every step follows the same pattern:

```powershell
cd infrastructure/solution-a/<step>
Copy-Item backend.hcl.example backend.hcl                    # then edit it
Copy-Item settings.auto.tfvars.example settings.auto.tfvars  # then edit it
terraform init -backend-config=backend.hcl
terraform plan -out step.tfplan    # read it before applying
terraform apply step.tfplan
terraform output                   # note the values the next step needs
```

## Step 0: state bucket

Solution A's state bucket lives in the management account. Bootstrap keeps
its own state locally, so give Solution A its **own workspace**; otherwise
Terraform would try to replace Solution B's bucket.

```powershell
cd infrastructure/bootstrap
terraform init
terraform workspace new solution-a        # 'terraform workspace select solution-a' next time
terraform apply -var "account_id=<management-account-id>" -var "state_bucket_name=cobble-tfstate-<management-account-id>"
```

Put the bucket name into every `backend.hcl`.

## Step 1: organisation, accounts, guardrails, sign-in

```powershell
cd infrastructure/solution-a/1-organization
```

If the organisation already exists (check: `aws organizations describe-organization`),
bring it under Terraform first:

```powershell
terraform init -backend-config=backend.hcl
terraform import aws_organizations_organization.this <organization-id>
```

Then plan and apply as above. Note `organization_id` and `account_ids`.

**By hand afterwards:** in IAM Identity Center, create a user for each
person and add them to `cobble-platform-admins`, `cobble-developers` or
`cobble-auditors`. From now on, sign in through the AWS access portal
instead of any IAM user.

Re-run bootstrap (step 0, same workspace) with
`-var "organization_id=<organization-id>"` so the CI roles created in step 4
can reach their state.

## Step 2: Security account

Fill in `management_account_id`, `security_account_id` (from step 1) and
`security_alert_email`. Plan and apply. Note `config_bucket_name` and
`config_kms_key_arn`.

**By hand afterwards:** open the "AWS Notification - Subscription
Confirmation" email and click **Confirm subscription**, or no alerts arrive.

## Step 3: Shared Services account

Fill in the account ID, the two step 2 outputs, a budget and an email. Plan
and apply. Note `container_registry_url`, then push the first Cobble image:

```powershell
aws ecr get-login-password | docker login --username AWS --password-stdin <registry-host>
docker tag cobble-module:1.0.0 <container_registry_url>:1.0.0
docker push <container_registry_url>:1.0.0
```

## Step 4: dev, then staging, then prod

For each environment folder, fill in its account ID, `container_image`
(`<container_registry_url>:<version>`), the step 2 outputs, GitHub details,
budget and email. Keep `assume_role_name = "OrganizationAccountAccessRole"`
for runs by a person. Plan and apply.

Check each one:

```powershell
terraform output app_url          # open it: the Cobble module should answer
terraform plan -detailed-exitcode # exit code 0 = no drift
```

**By hand afterwards:**

1. In GitHub (Settings > Environments), create `dev`, `staging` and `prod`;
   add required reviewers to `staging` and `prod`.
2. When the domain is ready, request an ACM certificate (e.g. for
   `dev.cobble.com`), set `certificate_arn`, and re-apply. HTTP then
   redirects to HTTPS.

## Tear down

| What | How |
|---|---|
| dev or staging (to save cost) | `terraform destroy` in its folder, run by a person signed in to the management account. Rebuild later with apply. (CI can't tear down: the guardrail SCP stops its roles switching off AWS Config, by design.) |
| prod | Set `protect_from_deletion = false` in `prod/main.tf`, apply, then destroy. Deliberately two steps. |
| Steps 1 to 3 | Not torn down routinely. Member accounts are protected (`prevent_destroy`) and must be closed by hand in AWS Organizations. Audit logs stay locked for `audit_log_retention_days`. |

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `AWS account ID not allowed` | Wrong account, or wrong ID in settings | `aws sts get-caller-identity`; check `settings.auto.tfvars` |
| `AlreadyInOrganizationException` / organisation already exists | The organisation predates Terraform | Import it (step 1) |
| `AccessDenied` assuming `OrganizationAccountAccessRole` | Account still being created, or not signed in to management | Wait a few minutes; check sign-in |
| `aws_ssoadmin_instances` returns nothing | Identity Center not enabled | Enable it in the console first |
| Security Hub or GuardDuty "not a delegated administrator" | Step 1 not applied, or still propagating | Apply step 1; wait a few minutes; retry step 2 |
| Denied by an SCP (`explicit deny in a service control policy`) | A guardrail blocked the action | Expected for other regions and for turning off security services. Check `1-organization/policies/` |
| `The term 'aws' is not recognized ` | `AWS is not installed or has not been restarted after installing`  | Download AWS CLI or restart the IDE/terminal for AWS CLI to be detected |
| `The term 'terraform' is not recognized ` | `terraform is not installed or has not been restarted after installing`  | Download terraform or restart the IDE/terminal for terraform to be detected |

