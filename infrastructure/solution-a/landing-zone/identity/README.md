# People and groups

Creates everyone's single sign-on login and puts them in the right group.
One row per person in a simple list, `users.csv`: add a row and apply to
give someone a login, delete the row to remove it.

| | |
|---|---|
| **Builds** | Three groups in IAM Identity Center (`cobble-platform-admins`, `cobble-developers`, `cobble-auditors`) and a login for each person in `users.csv` |
| **Doesn't** | Create accounts or grant access. What each group can do, and where, is set in [step 1](../1-organization/identity-center.tf) |
| **Runs in** | The account that runs Identity Center. **Run it before step 1**, which looks the groups up by name |
| **Before you run** | In the console: turn on Identity Center, require MFA, and turn on "Send email OTP" so new people can set their own password |
| **You fill in** | `users.csv` (copy `users.csv.example`) and `settings.auto.tfvars` (copy the `.example`). Both stay off GitHub, because they hold names and emails |
| **Runbook** | [deploy-solution-a.md, People and groups](../../../../runbooks/deploy-solution-a.md#people-and-groups) |

It has no step number because it isn't part of the one-off build order.
Apply it whenever someone joins or leaves.
