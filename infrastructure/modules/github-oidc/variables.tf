variable "name" {
  description = "Prefix for the role names, e.g. \"cobble-dev\". Roles are called <name>-terraform-plan and <name>-terraform-apply."
  type        = string
}

variable "github_org" {
  description = "GitHub organisation or user that owns the repo."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
}

variable "github_environment" {
  description = "GitHub environment that must approve an apply, e.g. \"dev\" or \"prod\". Set required reviewers on it in the repo settings."
  type        = string
}

variable "state_bucket_name" {
  description = "Terraform state bucket (created by infrastructure/bootstrap)."
  type        = string
}

variable "state_key" {
  description = "This environment's state file inside the bucket, e.g. \"solution-a/workload/terraform.tfstate\"."
  type        = string
}
