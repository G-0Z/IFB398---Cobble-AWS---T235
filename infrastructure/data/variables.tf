variable "project_name" {
  description = "Naming prefix."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt the bucket. Consumed from foundation/logging's output."
  type        = string
}
