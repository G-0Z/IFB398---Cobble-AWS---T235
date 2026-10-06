variable "management_account_id" {
  description = "Management account ID."
  type        = string
}

variable "security_account_id" {
  description = "Security account ID (step 1 output account_ids.security)."
  type        = string
}

variable "aws_region" {
  description = "Home region."
  type        = string
  default     = "ap-southeast-2"
}

variable "security_alert_email" {
  description = "Who is emailed about high and critical security findings. Use a monitored team mailbox."
  type        = string
}

variable "audit_log_retention_days" {
  description = "Audit logs (CloudTrail) are locked against change or deletion for this many days."
  type        = number
  default     = 365
}

variable "audit_log_lock_mode" {
  description = "\"GOVERNANCE\" (a specially permitted admin can remove a lock; good while the design settles) or \"COMPLIANCE\" (nobody can, not even root)."
  type        = string
  default     = "GOVERNANCE"
}
