variable "bucket_name" {
  description = "Globally unique bucket name."
  type        = string
}

variable "force_destroy" {
  description = "Let `terraform destroy` delete the bucket even when it holds logs. true for test environments; false for production."
  type        = bool
}

variable "log_retention_days" {
  description = "Delete log files after this many days."
  type        = number
  default     = 365
}

variable "allow_load_balancer_logs" {
  description = "Also accept Application Load Balancer access logs (under the alb/ prefix)."
  type        = bool
  default     = false
}
