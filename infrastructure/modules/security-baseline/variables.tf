variable "project_name" {
  description = "Naming prefix."
  type        = string
}

variable "enable_guardduty" {
  description = "Turn on GuardDuty in this account. false when something else already manages the account's detector (Solution A's landing zone)."
  type        = bool
  default     = true
}
