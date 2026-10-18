# Step 1: the organisation

Sets up the AWS Organization: the accounts, the folders they sit in, the
guardrails that apply to all of them, and who can sign in to which account.

| | |
|---|---|
| **Builds** | Account folders (Security, Infrastructure, Workloads > NonProduction / Production), 5 member accounts, 4 guardrails ([`policies/`](policies/)), and each group's access to each account. Permanent: torn-down demos leave all of this in place |
| **Runs in** | The management account. After [People and groups](../identity/), before step 2 |
| **You fill in** | `settings.auto.tfvars` (copy the `.example`): the management account ID and an email address for each new account. Leave out `shared_services` and that account isn't created (add it later and re-apply) |
| **Gives the next steps** | `account_ids`, `organization_id` |
| **Runbook** | [deploy-solution-a.md, step 1](../../../../runbooks/deploy-solution-a.md#step-1-organisation-accounts-guardrails-sign-in) |

If the organisation already exists (the team's does: `o-b60hme0nfl`), import
it before the first apply. The runbook shows how.

Handing security monitoring to the Security account is step 2's job
([`delegation.tf`](../2-security/delegation.tf)), so that step can be torn
down and rebuilt on its own.

| File | Holds |
|---|---|
| [`organization.tf`](organization.tf) | The organisation, its folders (OUs), and the Access Analyzer role step 2 needs |
| [`accounts.tf`](accounts.tf) | The five member accounts. Protected: `terraform destroy` won't remove them |
| [`guardrails.tf`](guardrails.tf) | Attaches the guardrails in `policies/` |
| [`identity-center.tf`](identity-center.tf) | Which group gets which role in which account |
