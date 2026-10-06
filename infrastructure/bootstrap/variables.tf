variable "account_id" {
  description = "AWS account the state bucket lives in. The provider refuses to run against any other account."
  type        = string
  default     = "669591255093"
}

variable "aws_region" {
  description = "AWS region for the state bucket."
  type        = string
  default     = "ap-southeast-2"
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform state. Must match the bucket hardcoded in infrastructure/envs/poc/backend.tf."
  type        = string
  default     = "cobble-tfstate-669591255093"
}

variable "organization_id" {
  description = "Solution A only: the AWS Organization ID (o-...). When set, GitHub Actions deploy roles in member accounts (named cobble-<env>-terraform-plan/apply) can reach their own state under solution-a/. null (Solution B) adds no bucket policy."
  type        = string
  default     = null
}
