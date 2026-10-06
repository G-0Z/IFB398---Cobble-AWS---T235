# Values that are specific to your organisation (account IDs, emails,
# outputs of earlier steps). Set them in settings.auto.tfvars. The sizing
# choices for this environment are in main.tf.

variable "account_id" {
  description = "This environment's AWS account ID (step 1 output account_ids)."
  type        = string
}

variable "aws_region" {
  description = "Home region."
  type        = string
  default     = "ap-southeast-2"
}

variable "assume_role_name" {
  description = "Role to assume inside the account when a person runs this from the management account. null when GitHub Actions runs it."
  type        = string
  default     = null
}

variable "container_image" {
  description = "Cobble module image with a fixed version, e.g. <step 3 container_registry_url>:1.0.0."
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate for this environment's domain. null until the domain is set up (plain HTTP)."
  type        = string
  default     = null
}

variable "alert_email" {
  description = "Who receives this environment's budget alerts."
  type        = string
}

variable "budget_limit" {
  description = "Monthly budget for this environment's account."
  type        = number
}

variable "github_org" {
  description = "GitHub organisation or user that owns the repo."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository that deploys this environment."
  type        = string
}

variable "state_bucket_name" {
  description = "Terraform state bucket (same as in backend.hcl)."
  type        = string
}

variable "config_bucket_name" {
  description = "Central AWS Config bucket (step 2 output)."
  type        = string
}

variable "config_kms_key_arn" {
  description = "Key for the central Config bucket (step 2 output)."
  type        = string
}
