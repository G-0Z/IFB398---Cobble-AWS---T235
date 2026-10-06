# DEV: where developers try changes. Smallest sizes, one NAT gateway, no
# WAF, and everything can be torn down at the end of the day.
#
# Compare with ../staging/main.tf and ../prod/main.tf: only the values below
# differ between environments. Everything else is built identically by
# modules/cobble-environment.

module "environment" {
  source = "../../../modules/cobble-environment"

  environment           = "dev"
  protect_from_deletion = false

  # Network: 10.28.0.0/16, two AZs, one shared NAT gateway.
  vpc_cidr              = "10.28.0.0/16"
  public_subnet_cidrs   = ["10.28.0.0/24", "10.28.1.0/24"]
  private_subnet_cidrs  = ["10.28.10.0/24", "10.28.11.0/24"]
  database_subnet_cidrs = ["10.28.20.0/24", "10.28.21.0/24"]
  nat_gateway_mode      = "single"

  # Application: one small container, no WAF.
  container_image           = var.container_image
  certificate_arn           = var.certificate_arn
  app_cpu                   = 256
  app_memory                = 512
  app_desired_count         = 1
  enable_waf                = false
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
  state_key         = "solution-a/4-workloads/dev/terraform.tfstate"

  config_bucket_name = var.config_bucket_name
  config_kms_key_arn = var.config_kms_key_arn
}
