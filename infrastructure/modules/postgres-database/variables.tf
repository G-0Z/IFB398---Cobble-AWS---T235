variable "identifier" {
  description = "Name of the database instance, e.g. \"cobble-dev\"."
  type        = string
}

variable "vpc_id" {
  description = "VPC the database lives in."
  type        = string
}

variable "subnet_ids" {
  description = "Database subnets (no internet route), at least two AZs."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect on the PostgreSQL port, e.g. the application containers."
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key that encrypts the database storage, its backups and its admin password secret."
  type        = string
}

variable "database_name" {
  description = "Name of the first database created inside the instance."
  type        = string
  default     = "cobble"
}

variable "engine_version" {
  description = "PostgreSQL major version. Minor updates are applied automatically in the maintenance window."
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "Size of the database server, e.g. db.t4g.micro (smallest) or db.t4g.small."
  type        = string
}

variable "allocated_storage_gb" {
  description = "Starting disk size, in GB."
  type        = number
  default     = 20
}

variable "max_allocated_storage_gb" {
  description = "Storage grows automatically up to this size, in GB."
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Keep a live standby copy in a second AZ that takes over automatically if the primary fails. Recommended for production."
  type        = bool
}

variable "backup_retention_days" {
  description = "Days of automatic daily backups kept (point-in-time recovery window)."
  type        = number
}

variable "deletion_protection" {
  description = "Refuse to delete the database until this is turned off. true for production."
  type        = bool
}

variable "performance_insights" {
  description = "Turn on Performance Insights (query-level monitoring, 7 days free)."
  type        = bool
  default     = false
}
