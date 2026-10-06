variable "log_group_name" {
  description = "CloudWatch Logs group name, e.g. \"/cobble/cloudtrail\"."
  type        = string
}

variable "retention_in_days" {
  description = "How long CloudWatch keeps the logs."
  type        = number
}

variable "kms_key_arn" {
  description = "KMS key that encrypts the log group. Its key policy must allow the CloudWatch Logs service."
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role the delivering service assumes (also used for its inline policy)."
  type        = string
}

variable "service_principal" {
  description = "AWS service that writes the logs, e.g. \"cloudtrail.amazonaws.com\" or \"vpc-flow-logs.amazonaws.com\"."
  type        = string
}
