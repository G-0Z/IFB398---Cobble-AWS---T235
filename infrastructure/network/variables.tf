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
  description = "KMS key ARN used to encrypt the VPC flow logs group. Consumed from foundation/logging's output."
  type        = string
}
