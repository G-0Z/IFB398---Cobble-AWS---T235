# `postgres-database` module

**In one sentence:** a private, encrypted PostgreSQL database (Amazon RDS)
whose admin password nobody ever sees.

**Used by:** Solution A (`cobble-environment`). Solution B has no database, to keep cost near zero.

## What it creates

| Resource | Why |
|---|---|
| DB subnet group | Places the database in the database subnets (no internet route) |
| Security group + rules | Only the listed security groups (the app) can connect, only on port 5432 |
| Parameter group | Forces TLS on every connection; logs connections and slow queries |
| RDS PostgreSQL instance | The database: encrypted with KMS, password in Secrets Manager, automatic backups and minor updates |

## Inputs (main ones)

| Name | Meaning | Dev | Prod |
|---|---|---|---|
| `instance_class` | Server size | `db.t4g.micro` | `db.t4g.small` or larger |
| `multi_az` | Standby copy in a second AZ | false | true |
| `backup_retention_days` | Days of backups | 7 | 35 |
| `deletion_protection` | Refuse deletion; keep a final snapshot | false | true |
| `performance_insights` | Query-level monitoring | false | true |

See `variables.tf` for the full list with descriptions.

## Outputs

`endpoint`, `port`, `database_name`, `admin_secret_arn`, `security_group_id`

## Best practice

- [Security best practices for Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.Security.html)
- [Password management with RDS and Secrets Manager](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-secrets-manager.html)
- [Multi-AZ deployments](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html) (Well-Architected Reliability pillar)
