# A PostgreSQL database (Amazon RDS), private, encrypted, and backed up.
# Nobody ever sees the admin password: RDS creates it and keeps it in
# Secrets Manager, where only the application's start-up role can read it.

resource "aws_db_subnet_group" "this" {
  name       = var.identifier
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "this" {
  name        = "${var.identifier}-db"
  description = "Database: accepts PostgreSQL connections only from the application"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.identifier}-db"
  }
}

resource "aws_vpc_security_group_ingress_rule" "from_allowed" {
  count                        = length(var.allowed_security_group_ids)
  security_group_id            = aws_security_group.this.id
  description                  = "PostgreSQL from the application"
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

# Database settings: refuse unencrypted connections, and log connections and
# slow queries for troubleshooting and security investigation.
resource "aws_db_parameter_group" "this" {
  name   = "${var.identifier}-postgres${var.engine_version}"
  family = "postgres${var.engine_version}"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
    # AWS stores it as pending-reboot; "immediate" would show as a change on every plan.
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # log any query slower than 1 second
  }
}

#tfsec:ignore:aws-rds-enable-performance-insights -- set per environment (performance_insights): on in prod; off elsewhere to save cost.
resource "aws_db_instance" "this" {
  identifier     = var.identifier
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class
  db_name        = var.database_name
  username       = "cobble_admin"

  # RDS generates the password and stores it in Secrets Manager.
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  # Where it runs: private subnets, no public address.
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false
  multi_az               = var.multi_az
  parameter_group_name   = aws_db_parameter_group.this.name

  # Storage: encrypted with the environment's key, grows automatically.
  storage_type          = "gp3"
  allocated_storage     = var.allocated_storage_gb
  max_allocated_storage = var.max_allocated_storage_gb
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  # Sign-in with IAM roles instead of passwords is available to the app.
  iam_database_authentication_enabled = true

  # Backups and updates.
  backup_retention_period    = var.backup_retention_days
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true
  #tfsec:ignore:aws-rds-enable-deletion-protection -- set per environment: on in prod; off in dev and staging so they tear down cleanly.
  deletion_protection = var.deletion_protection

  # Production keeps a final backup when the database is deleted; test
  # environments skip it so they tear down cleanly.
  skip_final_snapshot       = !var.deletion_protection
  final_snapshot_identifier = var.deletion_protection ? "${var.identifier}-final" : null

  # Database logs go to CloudWatch Logs.
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  performance_insights_enabled          = var.performance_insights
  performance_insights_kms_key_id       = var.performance_insights ? var.kms_key_arn : null
  performance_insights_retention_period = var.performance_insights ? 7 : null
}
