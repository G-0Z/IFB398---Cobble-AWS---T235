variable "project_name" {
  description = "Naming prefix."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ used."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ used."
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key that encrypts the flow log group (security-baseline's kms_key_arn). Its policy must allow the CloudWatch Logs service."
  type        = string
}

# --- Optional extras (off by default) ---------------------------------------
# Solution B (solution-b) leaves all of these at their defaults, so it deploys
# exactly what it always has. Solution A turns them on per environment.

variable "nat_gateway_mode" {
  description = <<-EOT
    How private subnets reach the internet (outbound only):
      "none"       - no internet access at all (cheapest; Solution B)
      "single"     - one NAT gateway shared by every AZ (dev and staging)
      "one_per_az" - one NAT gateway per AZ, so losing an AZ doesn't cut off
                     the others (production; AWS Well-Architected REL10)
  EOT
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "single", "one_per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be \"none\", \"single\" or \"one_per_az\"."
  }
}

variable "database_subnet_cidrs" {
  description = "One IP range per database subnet, one per AZ. These subnets never get an internet route. Leave empty for no database tier."
  type        = list(string)
  default     = []
}

variable "enable_s3_gateway_endpoint" {
  description = "Add a free S3 gateway endpoint, so private and database subnets reach S3 without going through a NAT gateway."
  type        = bool
  default     = false
}

variable "restrict_default_security_group" {
  description = "Remove every rule from the VPC's default security group, so anything accidentally placed in it can't send or receive traffic (CIS 5.4)."
  type        = bool
  default     = false
}
