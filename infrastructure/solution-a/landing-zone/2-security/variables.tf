variable "management_account_id" {
  description = "Management account ID."
  type        = string
}

variable "security_account_id" {
  description = "Security account ID (step 1 output account_ids.security)."
  type        = string

  validation {
    condition     = can(regex("^\\d{12}$", var.security_account_id))
    error_message = "security_account_id must be a 12-digit account ID. Is $ids set in this shell? See runbook step 1 output."
  }
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

variable "enable_management_guardduty" {
  description = "Run GuardDuty in the management account. false when another stack there already owns its detector (Solution B in the PoC account: AWS allows one per account and region)."
  type        = bool
  default     = true
}

variable "force_destroy_buckets" {
  description = "Let `terraform destroy` empty and delete the log buckets, including audit logs still under a GOVERNANCE lock. true only for a demo that is torn down; false for anything real (COMPLIANCE locks can't be bypassed anyway)."
  type        = bool
  default     = false
}
