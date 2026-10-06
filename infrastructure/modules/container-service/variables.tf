# --- Naming and placement ---------------------------------------------------

variable "name" {
  description = "Prefix for every resource name, e.g. \"cobble-dev\"."
  type        = string
}

variable "vpc_id" {
  description = "VPC the service runs in."
  type        = string
}

variable "load_balancer_subnet_ids" {
  description = "Public subnets for the load balancer (at least two AZs)."
  type        = list(string)
}

variable "task_subnet_ids" {
  description = "Subnets the containers run in. Private subnets with a NAT gateway in Solution A; public subnets in Solution B's demo (no NAT, to save cost)."
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Give each container a public IP. Only needed when task_subnet_ids are public subnets (Solution B's demo). The security group still only accepts traffic from the load balancer."
  type        = bool
  default     = false
}

# --- The container ----------------------------------------------------------

variable "container_image" {
  description = "Container image to run, e.g. \"<account>.dkr.ecr.ap-southeast-2.amazonaws.com/cobble-module:1.4.0\". Use a fixed version tag, not \"latest\"."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 80
}

variable "cpu" {
  description = "CPU units per container (256 = 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory per container, in MiB. Must be a valid pairing with cpu (see AWS Fargate task sizes)."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "How many copies of the container to run. 2 or more for production, so one can fail without downtime."
  type        = number
  default     = 1
}

variable "health_check_path" {
  description = "Path the load balancer requests to check a container is healthy."
  type        = string
  default     = "/"
}

variable "read_only_root_filesystem" {
  description = "Stop the container writing to its own filesystem (best practice). Some images, such as the stock nginx demo, need to write and won't start with this on."
  type        = bool
  default     = true
}

variable "environment_variables" {
  description = "Plain (non-secret) settings passed to the container."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secret settings, as name => Secrets Manager reference (secret ARN, optionally followed by :json-key::). Read at start-up; never stored in the task definition."
  type        = map(string)
  default     = {}
}

variable "secrets_kms_key_arn" {
  description = "KMS key the secrets are encrypted with, so the containers can decrypt them. null if secrets use the AWS-managed key."
  type        = string
  default     = null
}

variable "task_role_policy_json" {
  description = "Optional IAM policy (JSON) for what the application itself may do in AWS, e.g. read its data bucket. null gives the app no AWS permissions."
  type        = string
  default     = null
}

# --- Front door -------------------------------------------------------------

variable "certificate_arn" {
  description = "ACM certificate for HTTPS. With a certificate: HTTPS on 443, and HTTP redirects to HTTPS. null (no domain yet): plain HTTP only, for demos."
  type        = string
  default     = null
}

variable "enable_waf" {
  description = "Put an AWS WAF web firewall in front of the load balancer (AWS managed rules plus a rate limit)."
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Maximum requests from one IP address in any 5-minute window before WAF blocks it."
  type        = number
  default     = 2000
}

variable "access_log_bucket_id" {
  description = "Bucket for load balancer access logs (must accept them; see access-log-bucket's allow_load_balancer_logs). null turns them off."
  type        = string
  default     = null
}

variable "enable_deletion_protection" {
  description = "Stop the load balancer being deleted by accident. false for test environments so they tear down cleanly."
  type        = bool
  default     = false
}

# --- Monitoring -------------------------------------------------------------

variable "kms_key_arn" {
  description = "KMS key that encrypts the container log group. Its policy must allow the CloudWatch Logs service."
  type        = string
}

variable "log_retention_days" {
  description = "How long container logs are kept."
  type        = number
  default     = 30
}

variable "enable_container_insights" {
  description = "Detailed CPU and memory metrics for the cluster (small extra cost)."
  type        = bool
  default     = false
}
