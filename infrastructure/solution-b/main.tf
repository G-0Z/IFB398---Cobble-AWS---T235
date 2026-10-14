# Solution B: everything `terraform apply` creates, top to bottom.
# Values come from poc.auto.tfvars. Building blocks live in ../modules/,
# each with a README explaining what it creates.

# --- Security baseline -----------------------------------------------------
# KMS key, CloudTrail (all API calls, all regions), GuardDuty (threat
# detection), and the bucket that collects S3 access logs.

module "security_baseline" {
  source = "../modules/security-baseline"

  project_name     = var.project_name
  enable_guardduty = var.enable_guardduty
}

# --- Deploy identity -------------------------------------------------------
# Lets GitHub Actions deploy without stored AWS keys (OIDC): a read-only plan
# role for pull requests and the main branch, and an apply role only an
# approved run of the GitHub environment "poc" can use. The same module as
# Solution A's workload.

module "github_deploy" {
  source = "../modules/github-oidc"

  name               = var.project_name
  github_org         = var.github_org
  github_repo        = var.github_repo
  github_environment = "poc"
  state_bucket_name  = "cobble-tfstate-${var.account_id}"
  state_key          = "poc/terraform.tfstate"
}

# --- Network ---------------------------------------------------------------
# One VPC across two AZs: public subnets, private subnets (no NAT, so no
# internet access), and flow logs.

module "network" {
  source = "../modules/network"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  kms_key_arn          = module.security_baseline.kms_key_arn
}

# --- Platform data ---------------------------------------------------------
# One encrypted bucket for platform data. Stands in for the RDS data tier in
# the target architecture (Guide section 9), which is out of PoC scope.

module "platform_data_bucket" {
  source = "../modules/s3-bucket"

  bucket_name          = "${var.project_name}-platform-data-${var.account_id}"
  kms_key_arn          = module.security_baseline.kms_key_arn
  access_log_bucket_id = module.security_baseline.access_log_bucket_id
  access_log_prefix    = "platform-data-bucket-logs/"
  force_destroy        = true # PoC only: lets teardown remove a non-empty bucket
}

# --- Cost guardrail --------------------------------------------------------
# Emails alert_email when actual spend this month passes 80% and 100% of
# budget_limit. Covers the whole account, not just these resources.

resource "aws_budgets_budget" "monthly" {
  name         = "${var.project_name}-monthly-cost"
  budget_type  = "COST"
  limit_amount = tostring(var.budget_limit)
  limit_unit   = var.budget_currency
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = [80, 100]

    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = [var.alert_email]
    }
  }
}

# --- Demo app (optional, off by default) ----------------------------------
# Switch on with enable_demo_app = true in poc.auto.tfvars to show the MVP
# hosting a real web page: a load balancer in front of one small container
# (a stock nginx page standing in for a Cobble module).
#
# Cost-saving trade-offs, both fixed in Solution A:
#   - the container runs in a public subnet with a public IP, because there
#     is no NAT gateway (about US$43/month in Sydney). Its firewall still
#     only accepts traffic from the load balancer.
#   - plain HTTP, because there is no domain or certificate yet.
# Switch it off (or tear down) after the demo: while it's on it costs
# roughly US$1.30 a day (load balancer, container and public IP addresses).

module "demo_app" {
  count  = var.enable_demo_app ? 1 : 0
  source = "../modules/container-service"

  name                     = "${var.project_name}-demo"
  vpc_id                   = module.network.vpc_id
  load_balancer_subnet_ids = module.network.public_subnet_ids
  task_subnet_ids          = module.network.public_subnet_ids
  assign_public_ip         = true

  container_image           = "public.ecr.aws/nginx/nginx:stable"
  container_port            = 80
  read_only_root_filesystem = false # the stock nginx image writes to its own filesystem

  kms_key_arn        = module.security_baseline.kms_key_arn
  log_retention_days = 7
}
