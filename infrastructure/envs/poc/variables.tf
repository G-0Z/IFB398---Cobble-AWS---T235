# Declarations only. Every value is set in poc.auto.tfvars, so there is one
# place to read or change them.

# --- Where to deploy -------------------------------------------------------

variable "account_id" {
  description = "AWS account to deploy into. The provider refuses to run against any other account."
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy into (Guide section 3.1 proposes ap-southeast-2, Sydney)."
  type        = string
}

variable "project_name" {
  description = "Prefix for every resource name."
  type        = string
}

# --- Cost guardrail --------------------------------------------------------

variable "alert_email" {
  description = "Email address that receives budget alerts."
  type        = string
}

variable "budget_limit" {
  description = "Monthly cost budget, in budget_currency. Alerts fire at 80% and 100%."
  type        = number
}

variable "budget_currency" {
  description = "Currency for budget_limit."
  type        = string
}

# --- Deploy identity -------------------------------------------------------

variable "github_org" {
  description = "GitHub org or user that owns the repo allowed to assume the deploy role."
  type        = string
}

variable "github_repo" {
  description = "GitHub repo allowed to assume the deploy role (main branch only)."
  type        = string
}

# --- Network ---------------------------------------------------------------

variable "vpc_cidr" {
  description = "IP range for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "One IP range per public subnet; one subnet per availability zone."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "One IP range per private subnet; one subnet per availability zone. No internet access (no NAT gateway)."
  type        = list(string)
}

# --- Required tags (Guide naming standard) ---------------------------------

variable "owner" {
  description = "Owner tag: who is accountable for these resources."
  type        = string
}

variable "cost_centre" {
  description = "CostCentre tag."
  type        = string
}

variable "data_class" {
  description = "DataClass tag: the most sensitive data these resources hold."
  type        = string
}

variable "criticality" {
  description = "Criticality tag."
  type        = string
}

# --- Demo app ----------------------------------------------------------------

variable "enable_demo_app" {
  description = "Deploy the optional demo web app (load balancer and one container). false keeps the PoC at its usual near-zero cost."
  type        = bool
}
