# STAGING: a dress rehearsal for prod. Same security as prod (WAF on), but
# smaller and single-AZ to save cost. Can be torn down between releases.
#
# Compare with ../dev/main.tf and ../prod/main.tf: only the values below
# differ between environments. Everything else is built identically by
# modules/cobble-environment.

module "environment" {
  source = "../../../modules/cobble-environment"

  environment           = "staging"
  protect_from_deletion = false

  # Network: 10.29.0.0/16, two AZs, one shared NAT gateway.
  vpc_cidr              = "10.29.0.0/16"
  public_subnet_cidrs   = ["10.29.0.0/24", "10.29.1.0/24"]
  private_subnet_cidrs  = ["10.29.10.0/24", "10.29.11.0/24"]
  database_subnet_cidrs = ["10.29.20.0/24", "10.29.21.0/24"]
  nat_gateway_mode      = "single"

  # Application: one small container, WAF on (as in prod).
  container_image           = var.container_image
  certificate_arn           = var.certificate_arn
  app_cpu                   = 256
  app_memory                = 512
  app_desired_count         = 1
  enable_waf                = true
  enable_container_insights = false
  log_retention_days        = 30

  # Database: smallest size, single AZ, a week of backups.
  db_instance_class        = "db.t4g.micro"
  db_multi_az              = false
  db_backup_retention_days = 7
  db_performance_insights  = false

  budget_limit = var.budget_limit
  alert_email  = var.alert_email

  github_org        = var.github_org
  github_repo       = var.github_repo
  state_bucket_name = var.state_bucket_name
  state_key         = "solution-a/4-workloads/staging/terraform.tfstate"

  config_bucket_name = var.config_bucket_name
  config_kms_key_arn = var.config_kms_key_arn
}
