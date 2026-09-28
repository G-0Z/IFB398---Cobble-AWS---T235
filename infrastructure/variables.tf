variable "project_name" {
  description = "Naming prefix applied to every resource this config creates."
  type        = string
  default     = "cobble"
}

variable "aws_region" {
  description = "AWS region to deploy the PoC into. Matches the primary region proposed in the Cobbled AWS Platform Engineering Implementation Guide."
  type        = string
  default     = "ap-southeast-2"
}

variable "alert_email" {
  description = "Email address that receives AWS Budgets alerts. No default: set it in terraform.tfvars."
  type        = string
}

variable "budget_limit" {
  description = "Monthly cost budget in budget_currency. Alerts fire at 80% and 100% of this."
  type        = number
  default     = 25
}

variable "budget_currency" {
  description = "Currency for budget_limit."
  type        = string
  default     = "USD"
}

variable "github_org" {
  description = "GitHub org/user that owns the repo allowed to assume the CI deploy role."
  type        = string
  default     = "G-0Z"
}

variable "github_repo" {
  description = "GitHub repo name allowed to assume the CI deploy role."
  type        = string
  default     = "IFB398---Cobble-AWS---T235"
}

variable "vpc_cidr" {
  description = "CIDR block for the PoC VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ used."
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ used. No NAT gateway yet, see ADR 0003, so these have no internet egress."
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]
}
