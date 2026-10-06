# Step 4: the workload environments

Three folders, one per environment, each deployed into its own AWS account.
Every environment is built by the same module
([`modules/cobble-environment`](../../modules/cobble-environment/)); each
`main.tf` only sets the sizes and safeguards for that environment.

| Setting | [dev](dev/main.tf) | [staging](staging/main.tf) | [prod](prod/main.tf) |
|---|---|---|---|
| Purpose | Developers try changes | Dress rehearsal for prod | What tenants use |
| VPC range | 10.28.0.0/16 | 10.29.0.0/16 | 10.30.0.0/16 |
| NAT gateways | 1 shared | 1 shared | 1 per AZ |
| WAF | off | on | on |
| Containers | 1 × 0.25 vCPU, 0.5 GB | 1 × 0.25 vCPU, 0.5 GB | 2 × 0.5 vCPU, 1 GB |
| Database | db.t4g.micro, single AZ | db.t4g.micro, single AZ | db.t4g.small, Multi-AZ |
| Backups | 7 days | 7 days | 35 days |
| Deletion protection | off | off | on |
| Log retention | 30 days | 30 days | 90 days |
| Estimated cost | ~$110/month | ~$120/month | ~$260/month |

Dev and staging can be torn down when not in use (`terraform destroy`) and
rebuilt identically later.

## Promotion path

A change moves through the environments in order:

1. Pull request: CI runs format, validate, tests and the security scan, plus
   `terraform plan` for each environment using its read-only plan role.
2. Merge to `main`, then apply to **dev** (GitHub environment `dev`).
3. Apply to **staging** after one approval.
4. Apply to **prod** after one approval from a different person.

The CI deploy roles exist in each account (`modules/github-oidc`); wiring
the workflow to them is ADR 0001 item D6.
