variable "bucket_name" {
  description = "Globally unique bucket name."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key that encrypts every object in the bucket."
  type        = string
}

variable "access_log_bucket_id" {
  description = "Bucket that receives this bucket's server access logs."
  type        = string
}

variable "access_log_prefix" {
  description = "Prefix for this bucket's logs inside the access-log bucket, e.g. \"platform-data/\". Must be unique per bucket."
  type        = string
}

variable "force_destroy" {
  description = "Let `terraform destroy` delete the bucket even when it holds objects. true for the PoC; false for anything that must survive."
  type        = bool
}

variable "bucket_policy_json" {
  description = "Optional bucket policy (JSON), e.g. to let CloudTrail write to the bucket. null for no policy."
  type        = string
  default     = null
}

# --- Optional extras (off by default) ---------------------------------------

variable "object_lock_retention_days" {
  description = "Turn on Object Lock and keep every object locked for this many days. null (default) means no Object Lock. Can only be set when the bucket is first created."
  type        = number
  default     = null
}

variable "object_lock_mode" {
  description = "\"GOVERNANCE\" lets a specially permitted user remove a lock; \"COMPLIANCE\" lets nobody, not even the root user. Only used with object_lock_retention_days."
  type        = string
  default     = "GOVERNANCE"

  validation {
    condition     = contains(["GOVERNANCE", "COMPLIANCE"], var.object_lock_mode)
    error_message = "object_lock_mode must be \"GOVERNANCE\" or \"COMPLIANCE\"."
  }
}

variable "noncurrent_version_expiration_days" {
  description = "Delete old (overwritten or deleted) object versions after this many days. null keeps them forever."
  type        = number
  default     = null
}

variable "archive_after_days" {
  description = "Move objects to cheaper Glacier Instant Retrieval storage after this many days. null never archives."
  type        = number
  default     = null
}
