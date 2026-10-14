variable "shared_services_account_id" {
  description = "Shared Services account ID (step 1 output account_ids.shared_services)."
  type        = string
}

variable "aws_region" {
  description = "Home region."
  type        = string
  default     = "ap-southeast-2"
}

variable "config_bucket_name" {
  description = "Central AWS Config bucket (step 2 output)."
  type        = string
}

variable "config_kms_key_arn" {
  description = "Key for the central Config bucket (step 2 output)."
  type        = string
}

variable "budget_limit" {
  description = "Monthly budget for this account, in budget_currency."
  type        = number
}

variable "budget_currency" {
  description = "Currency for budget_limit. AWS budgets only work in US dollars (about A$1.44 per US$1 in July 2026)."
  type        = string
  default     = "USD"
}

variable "alert_email" {
  description = "Who receives budget alerts."
  type        = string
}
