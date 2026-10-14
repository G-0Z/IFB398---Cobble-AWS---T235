# Everything that differs between environments is an input here. Each
# environment's values are in its own <environment>.tfvars file.

# --- Where it runs ------------------------------------------------------------

variable "account_id" {
  description = "The environment's AWS account. Terraform refuses to run against any other, so the wrong .tfvars can't touch the wrong account."
  type        = string
}

variable "aws_region" {
  description = "Home region."
  type        = string
  default     = "ap-southeast-2"
}

variable "assume_role_name" {
  description = "Role to assume inside account_id. Set it on the command line (-var assume_role_name=OrganizationAccountAccessRole) when a person runs this from the management account. null when already in the account (the demo, or GitHub Actions)."
  type        = string
  default     = null
}

variable "criticality" {
  description = "Criticality tag (Implementation Guide naming standard)."
  type        = string
  default     = "Low"
}

variable "project_name" {
  description = "Prefix for every resource name."
  type        = string
  default     = "cobble"
}

variable "environment" {
  description = "Which environment this is."
  type        = string

  validation {
    condition     = contains(["demo", "dev", "staging", "prod"], var.environment)
    error_message = "environment must be \"demo\", \"dev\", \"staging\" or \"prod\"."
  }
}

variable "protect_from_deletion" {
  description = "Production safeguards: the database, load balancer and buckets refuse to be deleted, and the database keeps a final backup. false for dev and staging so they tear down cleanly."
  type        = bool
}

# --- Network ----------------------------------------------------------------

variable "vpc_cidr" {
  description = "IP range for the environment's VPC. Must not overlap with any other environment."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "One public subnet per AZ (load balancer and NAT gateways)."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "One private subnet per AZ (application containers)."
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "One database subnet per AZ (no internet route)."
  type        = list(string)
}

variable "nat_gateway_mode" {
  description = "\"single\" (dev, staging) or \"one_per_az\" (prod). See modules/network."
  type        = string
}

# --- Application ------------------------------------------------------------

variable "container_image" {
  description = "Cobble module image, with a fixed version tag, from the Shared Services ECR repository."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 80
}

variable "app_cpu" {
  description = "CPU units per container (256 = 0.25 vCPU)."
  type        = number
}

variable "app_memory" {
  description = "Memory per container, in MiB."
  type        = number
}

variable "app_desired_count" {
  description = "How many copies of the container to run (the minimum when auto scaling is on)."
  type        = number
}

variable "app_max_count" {
  description = "Most copies auto scaling may add under CPU load. null = fixed at app_desired_count."
  type        = number
  default     = null
}

variable "health_check_path" {
  description = "Path the load balancer uses to check the app is healthy."
  type        = string
  default     = "/"
}

variable "read_only_root_filesystem" {
  description = "Stop the container writing to its own filesystem. Turn off only for images that need it."
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = "ACM certificate for the environment's domain (e.g. dev.cobble.com). null serves plain HTTP: only acceptable before a domain is set up."
  type        = string
  default     = null
}

variable "enable_waf" {
  description = "Put AWS WAF in front of the load balancer."
  type        = bool
}

variable "enable_container_insights" {
  description = "Detailed container metrics (small extra cost)."
  type        = bool
}

variable "log_retention_days" {
  description = "How long application and network logs are kept in CloudWatch."
  type        = number
}

# --- Database ---------------------------------------------------------------

variable "db_instance_class" {
  description = "Database server size."
  type        = string
}

variable "db_multi_az" {
  description = "Standby database copy in a second AZ."
  type        = bool
}

variable "db_backup_retention_days" {
  description = "Days of automatic database backups."
  type        = number
}

variable "db_performance_insights" {
  description = "Query-level database monitoring."
  type        = bool
}

# --- Cost -------------------------------------------------------------------

variable "budget_limit" {
  description = "Monthly budget for this environment's account. Alerts at 80% (actual) and 100% (forecast)."
  type        = number
}

variable "budget_currency" {
  description = "Currency for budget_limit. AWS bills in USD by default."
  type        = string
  default     = "USD"
}

variable "alert_email" {
  description = "Who receives budget alerts."
  type        = string
}

# --- Deployment pipeline ----------------------------------------------------

variable "enable_github_deploy" {
  description = "Create the GitHub OIDC provider and plan/apply roles. An account can only have one GitHub OIDC provider, so false in an account that already has one (the single-account demo, alongside Solution B)."
  type        = bool
  default     = true
}

variable "github_org" {
  description = "GitHub organisation or user that owns the repo. Needed when enable_github_deploy is true."
  type        = string
  default     = null
}

variable "github_repo" {
  description = "GitHub repository that deploys this environment. Needed when enable_github_deploy is true."
  type        = string
  default     = null

  validation {
    condition     = !var.enable_github_deploy || (var.github_org != null && var.github_repo != null)
    error_message = "With enable_github_deploy, set github_org and github_repo."
  }
}

variable "state_bucket_name" {
  description = "Terraform state bucket (infrastructure/bootstrap). Must match backend.tf."
  type        = string
  default     = "cobble-tfstate-669591255093"
}

# --- Account-wide settings and central security services --------------------

variable "manage_account_settings" {
  description = "Apply account-wide settings (S3 public access block, EBS encryption, IAM password policy, AWS Config). true when the environment has its own account; false in the single-account demo, where the account also holds Solution B and the team's IAM users."
  type        = bool
  default     = true
}

variable "config_bucket_name" {
  description = "Central AWS Config bucket (output of landing-zone/2-security). Needed when manage_account_settings is true."
  type        = string
  default     = null
}

variable "config_kms_key_arn" {
  description = "Key for the central AWS Config bucket. Needed when manage_account_settings is true."
  type        = string
  default     = null

  validation {
    condition     = !var.manage_account_settings || (var.config_bucket_name != null && var.config_kms_key_arn != null)
    error_message = "With manage_account_settings, set config_bucket_name and config_kms_key_arn (outputs of landing-zone/2-security)."
  }
}
