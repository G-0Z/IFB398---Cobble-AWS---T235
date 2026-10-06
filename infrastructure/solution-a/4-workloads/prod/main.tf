# PROD: what tenants use. Every safeguard on: a NAT gateway and a standby
# database in each AZ, two copies of the app, WAF, longer backups, and
# protection against accidental deletion.
#
# Compare with ../dev/main.tf and ../staging/main.tf: only the values below
# differ between environments. Everything else is built identically by
# modules/cobble-environment.
#
# The CIDR ranges match the high-fidelity architecture diagram.

module "environment" {
  source = "../../../modules/cobble-environment"

  environment           = "prod"
  protect_from_deletion = true

  # Network: 10.30.0.0/16, two AZs, a NAT gateway in each AZ.
  vpc_cidr              = "10.30.0.0/16"
  public_subnet_cidrs   = ["10.30.0.0/24", "10.30.1.0/24"]
  private_subnet_cidrs  = ["10.30.10.0/24", "10.30.11.0/24"]
  database_subnet_cidrs = ["10.30.20.0/24", "10.30.21.0/24"]
  nat_gateway_mode      = "one_per_az"

  # Application: two containers (one per AZ), WAF on, detailed metrics.
  container_image           = var.container_image
  certificate_arn           = var.certificate_arn
  app_cpu                   = 512
  app_memory                = 1024
  app_desired_count         = 2
  enable_waf                = true
  enable_container_insights = true
  log_retention_days        = 90

  # Database: larger, standby copy in a second AZ, five weeks of backups.
  db_instance_class        = "db.t4g.small"
  db_multi_az              = true
  db_backup_retention_days = 35
  db_performance_insights  = true

  budget_limit = var.budget_limit
  alert_email  = var.alert_email

  github_org        = var.github_org
  github_repo       = var.github_repo
  state_bucket_name = var.state_bucket_name
  state_key         = "solution-a/4-workloads/prod/terraform.tfstate"

  config_bucket_name = var.config_bucket_name
  config_kms_key_arn = var.config_kms_key_arn
}
