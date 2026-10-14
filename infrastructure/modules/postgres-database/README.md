# PostgreSQL database (`postgres-database`)

**What it builds:** a private, encrypted PostgreSQL database (Amazon RDS)
whose admin password no person ever sees.

**Used by:** Solution A's workload. Solution B has no database, to keep its
cost near zero.

## What you get

| Part | Why |
|---|---|
| Placement in the database subnets | The database has no route to the internet |
| Firewall rule | Only the web servers can connect, and only on the database port (5432) |
| Database settings | Every connection must be encrypted; connections and slow queries are logged |
| The database | Encrypted with the environment's key. AWS creates the password and keeps it in Secrets Manager. Automatic backups, and automatic minor version updates |

## Main settings

| Setting | Meaning | dev | prod |
|---|---|---|---|
| `instance_class` | Server size | `db.t4g.micro` | `db.t4g.small` or larger |
| `multi_az` | A standby copy in a second zone that takes over if the first fails | `false` | `true` |
| `backup_retention_days` | Days of backups you can restore from | 7 | 35 |
| `deletion_protection` | Refuse deletion, and keep a final backup if it's ever removed | `false` | `true` |
| `performance_insights` | Query-level monitoring | `false` | `true` |

The full list, with descriptions, is in `variables.tf`.

**Outputs:** `endpoint`, `port`, `database_name`, `admin_secret_arn`, `security_group_id`

## Good to know

- The Implementation Guide specifies SQL Server. We use PostgreSQL for now to keep cost down, with the same security controls. The reasons are in [deliverable 2's key decisions](../../../docs/02-landing-zone-design/README.md#key-decisions).
- Further reading: [RDS security best practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.Security.html), [RDS and Secrets Manager](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-secrets-manager.html), [Multi-AZ deployments](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html).
