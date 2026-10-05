variable "project_name" {
  description = "Naming prefix."
  type        = string
}

variable "alert_email" {
  description = "Email address that receives the 80%/100% budget alerts."
  type        = string
}

variable "budget_limit" {
  description = "Monthly cost budget in budget_currency."
  type        = number
  default     = 25
}

variable "budget_currency" {
  description = "Currency for budget_limit."
  type        = string
  default     = "USD"
}
