# Solution A: the workload

One complete Cobble environment: the network, web servers, database and
data bucket, built from the modules in [`../../modules/`](../../modules/).
The same code builds every environment. Only the settings differ, and each
environment's settings fit in one file.

| Environment | Values | Runs in | Used for |
|---|---|---|---|
| demo | [`demo.tfvars`](demo.tfvars) | The Solution B account | Showing Solution A working, then tearing it down ([runbook](../../../runbooks/demo-solution-a.md)) |
| dev | [`dev.tfvars`](dev.tfvars) | The dev account | Developers trying changes, and the landing zone demo ([`lz-dev.ps1`](../lz-dev.ps1)) |
| staging | [`staging.tfvars`](staging.tfvars) | The staging account | Rehearsing a prod release |
| prod | [`prod.tfvars`](prod.tfvars) | The prod account | Tenants |

## Commands

Pick the environment twice: once at `init` (where Terraform keeps its
records for it) and once at `plan` (its settings file). Each settings file
names its AWS account, and Terraform refuses to run anywhere else, so the
wrong file can't touch the wrong account.

```powershell
cd infrastructure/solution-a/workload
$e = "demo"   # or dev, staging, prod
terraform init -reconfigure -backend-config="key=solution-a/workload/$e/terraform.tfstate"
terraform plan -var-file="$e.tfvars" -out "$e.tfplan"
terraform apply "$e.tfplan"
terraform destroy -var-file="$e.tfvars"
```

When a person runs dev, staging or prod from the management account, add
`-var "assume_role_name=OrganizationAccountAccessRole"` to `plan` and
`destroy`.

## What one environment contains

Read [`main.tf`](main.tf) top to bottom.

| Building block | Module | Purpose |
|---|---|---|
| Account safety settings | `account-baseline` | Public access block, EBS encryption, password policy, AWS Config. Off in the demo |
| Encryption key | ([`kms.tf`](kms.tf)) | Encrypts this environment's data and logs only |
| Access-log bucket | `access-log-bucket` | S3 and load balancer access logs |
| Network | `network` | Public, private and database subnets in 2 AZs; NAT; S3 endpoint |
| Tenant data bucket | `s3-bucket` | Encrypted, versioned storage |
| Application | `container-service` | Containers in private subnets behind a load balancer (and WAF), with auto scaling |
| Database | `postgres-database` | PostgreSQL; only the app can connect |
| Deployment roles | `github-oidc` | Plan and apply roles for GitHub Actions. Off in the demo |
| Budget | ([`main.tf`](main.tf)) | Monthly cost alerts |

## How the environments differ

| Setting | demo | dev | staging | prod |
|---|---|---|---|---|
| `nat_gateway_mode` | single | single | single | one_per_az |
| `enable_waf` | false | false | true | true |
| `app_desired_count` / `app_max_count` | 1 / 2 | 1 / off | 1 / 2 | 2 / 10 |
| `db_multi_az` | false | false | false | true |
| `db_backup_retention_days` | 7 | 7 | 7 | 35 |
| `protect_from_deletion` | false | false | false | true |
| `manage_account_settings`, `enable_github_deploy` | false | true | true | true |

## Tests

[`tests/workload.tftest.hcl`](tests/workload.tftest.hcl) checks the
building blocks are connected correctly, for example that only the web
servers can reach the database. It uses a pretend AWS, so it needs no AWS
sign-in: `terraform init -backend=false`, then `terraform test`.
