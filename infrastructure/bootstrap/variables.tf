variable "aws_region" {
  description = "AWS region for the state bucket."
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Naming prefix for bootstrap resources."
  type        = string
  default     = "cobble"
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform state. Must match the bucket hardcoded in infrastructure/envs/poc/backend.tf."
  type        = string
  default     = "cobble-tfstate-669591255093"
}
