# PROD: what tenants use. Every safeguard on: a NAT gateway and a standby
# database in each AZ, 2-10 containers, WAF, longer backups and logs, and
# protection against accidental deletion.

# REPLACE values come from the landing zone: account_id from
# 1-organization (account_ids), container_image from 3-shared-services,
# config_* from 2-security.

environment           = "prod"
account_id            = "REPLACE: account_ids.prod"
protect_from_deletion = true
criticality           = "High"

# Network: 10.30.0.0/16, two AZs.
vpc_cidr              = "10.30.0.0/16"
public_subnet_cidrs   = ["10.30.0.0/24", "10.30.1.0/24"]
private_subnet_cidrs  = ["10.30.10.0/24", "10.30.11.0/24"]
database_subnet_cidrs = ["10.30.20.0/24", "10.30.21.0/24"]
nat_gateway_mode      = "one_per_az"

container_image = "REPLACE: <container_registry_url>:1.0.0"
# certificate_arn         = "arn:aws:acm:ap-southeast-2:<account>:certificate/..." # once the domain is ready
app_cpu                   = 512
app_memory                = 1024
app_desired_count         = 2
app_max_count             = 10
enable_waf                = true
enable_container_insights = true
log_retention_days        = 90

db_instance_class        = "db.t4g.small"
db_multi_az              = true
db_backup_retention_days = 35
db_performance_insights  = true

config_bucket_name = "REPLACE: config_bucket_name"
config_kms_key_arn = "REPLACE: config_kms_key_arn"

github_org  = "G-0Z"
github_repo = "IFB398---Cobble-AWS---T235"

alert_email  = "t235cobbleaws@gmail.com"
budget_limit = 300 # US$ (AWS budgets are USD-only), about A$430
