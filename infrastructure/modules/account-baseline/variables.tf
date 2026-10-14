variable "name" {
  description = "Prefix for resource names, e.g. \"cobble-dev\"."
  type        = string
}

variable "config_bucket_name" {
  description = "Central AWS Config bucket in the Security account (output of solution-a/landing-zone/2-security)."
  type        = string
}

variable "config_kms_key_arn" {
  description = "KMS key that encrypts the central Config bucket (output of solution-a/landing-zone/2-security)."
  type        = string
}
