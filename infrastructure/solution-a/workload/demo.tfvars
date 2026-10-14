# DEMO: Solution A in one account, deployed and torn down like Solution B.
# The real workload design (three network tiers, NAT, containers in private
# subnets, auto scaling, private PostgreSQL), in the Solution B account.
# About A$0.22 an hour: always tear it down after the demo.

environment           = "demo"
account_id            = "669591255093" # the same account as Solution B
protect_from_deletion = false
criticality           = "Low"

# Two account-wide parts are off here:
#   - account settings (password policy, AWS Config, ...): they would change
#     things for the team's IAM users and need landing-zone/2-security
#   - GitHub deploy roles: Solution B already has the account's one GitHub
#     OIDC provider
manage_account_settings = false
enable_github_deploy    = false

# Network: its own range, so it can sit beside Solution B (10.20.0.0/16).
vpc_cidr              = "10.28.0.0/16"
public_subnet_cidrs   = ["10.28.0.0/24", "10.28.1.0/24"]
private_subnet_cidrs  = ["10.28.10.0/24", "10.28.11.0/24"]
database_subnet_cidrs = ["10.28.20.0/24", "10.28.21.0/24"]
nat_gateway_mode      = "single"

# Application: a stock web server stands in for a Cobble module (no registry
# without landing-zone/3-shared-services). It writes to its own filesystem,
# so that protection is off. Auto scaling 1-2.
container_image           = "public.ecr.aws/nginx/nginx:stable"
read_only_root_filesystem = false
app_cpu                   = 256
app_memory                = 512
app_desired_count         = 1
app_max_count             = 2
enable_waf                = false
enable_container_insights = false
log_retention_days        = 7

# Database: smallest size, single AZ, a week of backups.
db_instance_class        = "db.t4g.micro"
db_multi_az              = false
db_backup_retention_days = 7
db_performance_insights  = false

alert_email  = "t235cobbleaws@gmail.com"
budget_limit = 5 # US$ (AWS budgets are USD-only), about A$7
