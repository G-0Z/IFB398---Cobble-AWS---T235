# `cobble-environment` module

**In one sentence:** one complete Cobble environment (dev, staging or prod)
in its own AWS account, built from the other modules.

**Used by:** `solution-a/4-workloads/dev`, `staging` and `prod`. Each of
those folders just sets this module's inputs, so the three environments are
built the same way and only differ where they are meant to.

## What one environment contains

| Building block | Module | Purpose |
|---|---|---|
| Account safety settings | `account-baseline` | Public access block, EBS encryption, AWS Config |
| Encryption key | (`kms.tf`) | Encrypts this environment's data and logs only |
| Access-log bucket | `access-log-bucket` | S3 and load balancer access logs |
| Network | `network` | Public, private and database subnets in 2 AZs; NAT; S3 endpoint |
| Tenant data bucket | `s3-bucket` | Encrypted, versioned storage |
| Application | `container-service` | Containers behind a load balancer (and WAF) |
| Database | `postgres-database` | PostgreSQL; only the app can connect |
| Deployment roles | `github-oidc` | Plan and apply roles for GitHub Actions |
| Budget | (`main.tf`) | Monthly cost alerts |

## How the environments differ

| Setting | dev | staging | prod |
|---|---|---|---|
| `nat_gateway_mode` | single | single | one_per_az |
| `enable_waf` | false | true | true |
| `app_desired_count` | 1 | 1 | 2 |
| `db_multi_az` | false | false | true |
| `db_backup_retention_days` | 7 | 7 | 35 |
| `protect_from_deletion` | false | false | true |

## Why one composite module

ADR 0001 (D3) preferred roots composing small modules directly. With three
environments that would mean copying about 150 lines three times, and the
copies could drift apart. One composite module keeps the environments
identical by construction (see ADR 0003).
