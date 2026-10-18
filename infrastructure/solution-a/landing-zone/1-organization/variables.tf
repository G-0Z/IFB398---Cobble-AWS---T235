variable "management_account_id" {
  description = "The management account's ID. Terraform refuses to run against any other account."
  type        = string
}

variable "aws_region" {
  description = "Home region for the organisation."
  type        = string
  default     = "ap-southeast-2"
}

variable "account_emails" {
  description = "A unique, monitored email address for each new account's root user. Use a shared team mailbox, never a personal address (ADR 0001, D10). shared_services may be left out until step 3 is needed: that account is then not created."
  type = object({
    security        = string
    shared_services = optional(string)
    dev             = string
    staging         = string
    prod            = string
  })

  validation {
    condition     = alltrue([for e in values(var.account_emails) : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e)) && !endswith(e, "@example.com") if e != null])
    error_message = "Each account needs a real email address (the example.com placeholders must be replaced)."
  }
}

variable "allowed_regions" {
  description = "Regions member accounts may use. Everything else is blocked by an SCP. us-east-1 is included because some global services (such as certificates for CloudFront) live there."
  type        = list(string)
  default     = ["ap-southeast-2", "us-east-1"]
}
