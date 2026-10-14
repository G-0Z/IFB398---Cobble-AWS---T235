# STAGING: a dress rehearsal for prod. Same security as prod (WAF on), but
# smaller and single-AZ. Can be torn down between releases.

# REPLACE values come from the landing zone: account_id from
# 1-organization (account_ids), container_image from 3-shared-services,
# config_* from 2-security.

environment           = "staging"
account_id            = "REPLACE: account_ids.staging"
protect_from_deletion = false
criticality           = "Low"

# Network: 10.29.0.0/16, two AZs.
vpc_cidr              = "10.29.0.0/16"
public_subnet_cidrs   = ["10.29.0.0/24", "10.29.1.0/24"]
private_subnet_cidrs  = ["10.29.10.0/24", "10.29.11.0/24"]
database_subnet_cidrs = ["10.29.20.0/24", "10.29.21.0/24"]
nat_gateway_mode      = "single"

container_image = "REPLACE: <container_registry_url>:1.0.0"
# certificate_arn         = "arn:aws:acm:ap-southeast-2:<account>:certificate/..." # once the domain is ready
app_cpu                   = 256
app_memory                = 512
app_desired_count         = 1
app_max_count             = 2
enable_waf                = true
enable_container_insights = false
log_retention_days        = 30

db_instance_class        = "db.t4g.micro"
db_multi_az              = false
db_backup_retention_days = 7
db_performance_insights  = false

config_bucket_name = "REPLACE: config_bucket_name"
config_kms_key_arn = "REPLACE: config_kms_key_arn"

github_org  = "G-0Z"
github_repo = "IFB398---Cobble-AWS---T235"

alert_email  = "t235cobbleaws@gmail.com"
budget_limit = 150 # US$ (AWS budgets are USD-only), about A$215
