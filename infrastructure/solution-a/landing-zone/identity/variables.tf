variable "identity_center_account_id" {
  description = "The account that administers IAM Identity Center (management or delegated administrator). Terraform refuses to run against any other account."
  type        = string
}

variable "aws_region" {
  description = "Region IAM Identity Center was enabled in."
  type        = string
  default     = "ap-southeast-2"
}
