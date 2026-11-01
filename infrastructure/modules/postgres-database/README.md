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

## Good to know

- The Implementation Guide specifies SQL Server. We use PostgreSQL for now to keep cost down, with the same security controls. The reasons are in [deliverable 2's key decisions](../../../docs/deliverables/landing-zone-design.md#key-decisions).
- Further reading: [RDS security best practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.Security.html), [RDS and Secrets Manager](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-secrets-manager.html), [Multi-AZ deployments](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html).

## Usage

How it's called in [`solution-a/workload/main.tf`](../../solution-a/workload/main.tf):

```hcl
module "database" {
  source = "../../modules/postgres-database"

  identifier                 = local.name
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.database_subnet_ids
  allowed_security_group_ids = [module.app.task_security_group_id]
  kms_key_arn                = aws_kms_key.this.arn

  instance_class        = var.db_instance_class
  multi_az              = var.db_multi_az
  backup_retention_days = var.db_backup_retention_days
  deletion_protection   = var.protect_from_deletion
  performance_insights  = var.db_performance_insights
}
```

## Reference

Generated from the module's code by [terraform-docs](https://terraform-docs.io/), so it's always
complete. Don't edit it by hand: run `terraform-docs -c ../.terraform-docs.yml .`
in this folder after changing a variable or output.

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.10 |
| aws | ~> 5.0 |

### Providers

| Name | Version |
| ---- | ------- |
| aws | ~> 5.0 |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| allowed\_security\_group\_ids | Security groups allowed to connect on the PostgreSQL port, e.g. the application containers. | `list(string)` | n/a | yes |
| backup\_retention\_days | Days of automatic daily backups kept (point-in-time recovery window). | `number` | n/a | yes |
| deletion\_protection | Refuse to delete the database until this is turned off. true for production. | `bool` | n/a | yes |
| identifier | Name of the database instance, e.g. "cobble-dev". | `string` | n/a | yes |
| instance\_class | Size of the database server, e.g. db.t4g.micro (smallest) or db.t4g.small. | `string` | n/a | yes |
| kms\_key\_arn | KMS key that encrypts the database storage, its backups and its admin password secret. | `string` | n/a | yes |
| multi\_az | Keep a live standby copy in a second AZ that takes over automatically if the primary fails. Recommended for production. | `bool` | n/a | yes |
| subnet\_ids | Database subnets (no internet route), at least two AZs. | `list(string)` | n/a | yes |
| vpc\_id | VPC the database lives in. | `string` | n/a | yes |
| allocated\_storage\_gb | Starting disk size, in GB. | `number` | `20` | no |
| database\_name | Name of the first database created inside the instance. | `string` | `"cobble"` | no |
| engine\_version | PostgreSQL major version. Minor updates are applied automatically in the maintenance window. | `string` | `"16"` | no |
| max\_allocated\_storage\_gb | Storage grows automatically up to this size, in GB. | `number` | `100` | no |
| performance\_insights | Turn on Performance Insights (query-level monitoring, 7 days free). | `bool` | `false` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| admin\_secret\_arn | Secrets Manager secret holding the admin username and password (JSON keys "username" and "password"). |
| allowed\_security\_group\_ids | Security groups that can connect to the database (for audits and the security controls document). |
| database\_name | Name of the database inside the instance. |
| endpoint | Hostname the application connects to. |
| port | PostgreSQL port. |
| security\_group\_id | The database's security group. |
<!-- END_TF_DOCS -->
