# Solution A's workload: one complete Cobble environment. Read top to bottom:
# this is everything an environment contains. Each building block is a module
# in ../../modules/ with its own README and tests.
#
# The same code builds every environment. Only the values differ, and they
# live in one file each: demo.tfvars, dev.tfvars, staging.tfvars, prod.tfvars.
# See README.md for the commands.

locals {
  name       = "${var.project_name}-${var.environment}"
  account_id = data.aws_caller_identity.current.account_id

  # Must match the key given to `terraform init` (see README.md). The GitHub
  # deploy roles may only touch this file.
  state_key = "solution-a/workload/${var.environment}/terraform.tfstate"
}

# --- Account safety settings -----------------------------------------------
# Public access block, EBS encryption, password policy, AWS Config.
# Account-wide, so off in the demo, where the account also holds Solution B
# and the team's IAM users.

module "account_baseline" {
  count  = var.manage_account_settings ? 1 : 0
  source = "../../modules/account-baseline"

  name               = local.name
  config_bucket_name = var.config_bucket_name
  config_kms_key_arn = var.config_kms_key_arn
}

# --- Access logs --------------------------------------------------------------
# Collects S3 and load balancer access logs for this account.

module "access_logs" {
  source = "../../modules/access-log-bucket"

  bucket_name              = "${local.name}-access-logs-${local.account_id}"
  force_destroy            = !var.protect_from_deletion
  allow_load_balancer_logs = true
}

# --- Network ------------------------------------------------------------------
# Three tiers across two AZs: public (load balancer, NAT), private (app),
# database (no internet route).

module "network" {
  source = "../../modules/network"

  project_name                    = local.name
  vpc_cidr                        = var.vpc_cidr
  public_subnet_cidrs             = var.public_subnet_cidrs
  private_subnet_cidrs            = var.private_subnet_cidrs
  database_subnet_cidrs           = var.database_subnet_cidrs
  nat_gateway_mode                = var.nat_gateway_mode
  enable_s3_gateway_endpoint      = true
  restrict_default_security_group = true
  kms_key_arn                     = aws_kms_key.this.arn
}

# --- Tenant data bucket -------------------------------------------------------

module "data_bucket" {
  source = "../../modules/s3-bucket"

  bucket_name                        = "${local.name}-data-${local.account_id}"
  kms_key_arn                        = aws_kms_key.this.arn
  access_log_bucket_id               = module.access_logs.bucket_id
  access_log_prefix                  = "data-bucket/"
  force_destroy                      = !var.protect_from_deletion
  noncurrent_version_expiration_days = 90
}

# --- Application --------------------------------------------------------------
# Cobble module containers on ECS Fargate, behind a load balancer (and WAF).

module "app" {
  source = "../../modules/container-service"

  name                     = local.name
  vpc_id                   = module.network.vpc_id
  load_balancer_subnet_ids = module.network.public_subnet_ids
  task_subnet_ids          = module.network.private_subnet_ids

  container_image           = var.container_image
  container_port            = var.container_port
  cpu                       = var.app_cpu
  memory                    = var.app_memory
  desired_count             = var.app_desired_count
  max_count                 = var.app_max_count
  health_check_path         = var.health_check_path
  read_only_root_filesystem = var.read_only_root_filesystem

  # Connection details for the database and data bucket. The password is
  # read from Secrets Manager when the container starts; it is never stored
  # in the task definition. The app currently signs in as the database admin
  # user; a separate, least-privilege app user is a Phase 2 task.
  environment_variables = {
    DB_HOST     = module.database.endpoint
    DB_PORT     = tostring(module.database.port)
    DB_NAME     = module.database.database_name
    DATA_BUCKET = module.data_bucket.bucket_name
  }
  secrets = {
    DB_USERNAME = "${module.database.admin_secret_arn}:username::"
    DB_PASSWORD = "${module.database.admin_secret_arn}:password::"
  }
  secrets_kms_key_arn = aws_kms_key.this.arn

  # What the app itself may do in AWS: read and write its data bucket.
  task_role_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = module.data_bucket.bucket_arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${module.data_bucket.bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = aws_kms_key.this.arn
      },
    ]
  })

  certificate_arn            = var.certificate_arn
  enable_waf                 = var.enable_waf
  access_log_bucket_id       = module.access_logs.bucket_id
  enable_deletion_protection = var.protect_from_deletion
  kms_key_arn                = aws_kms_key.this.arn
  log_retention_days         = var.log_retention_days
  enable_container_insights  = var.enable_container_insights
}

# --- Database -----------------------------------------------------------------
# PostgreSQL in the database subnets; only the app's containers can connect.

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

# --- Deployment roles ---------------------------------------------------------
# GitHub Actions: read-only plan role for pull requests, apply role for the
# approved GitHub environment. No stored AWS keys.

module "github_deploy" {
  count  = var.enable_github_deploy ? 1 : 0
  source = "../../modules/github-oidc"

  name               = local.name
  github_org         = var.github_org
  github_repo        = var.github_repo
  github_environment = var.environment
  state_bucket_name  = var.state_bucket_name
  state_key          = local.state_key
}

# --- Cost guardrail -----------------------------------------------------------
# Emails alert_email at 80% of actual spend and when the month's forecast
# passes 100%.

resource "aws_budgets_budget" "monthly" {
  name         = "${local.name}-monthly-cost"
  budget_type  = "COST"
  limit_amount = tostring(var.budget_limit)
  limit_unit   = var.budget_currency
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}
