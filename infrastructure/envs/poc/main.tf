# Root config for the PoC environment. Each block below wires up one module
# from ../../modules/. See each module's README for what it creates.

# --- Foundation: identity, security baseline, cost guardrail ---------------

module "oidc_deploy_role" {
  source = "../../modules/oidc-deploy-role"

  project_name = var.project_name
  github_org   = var.github_org
  github_repo  = var.github_repo
}

module "security_baseline" {
  source = "../../modules/security-baseline"

  project_name = var.project_name
}

module "budget" {
  source = "../../modules/budget"

  project_name    = var.project_name
  alert_email     = var.alert_email
  budget_limit    = var.budget_limit
  budget_currency = var.budget_currency
}

# --- Workload: network and data -------------------------------------------

module "network" {
  source = "../../modules/network"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  kms_key_arn          = module.security_baseline.kms_key_arn
}

module "data" {
  source = "../../modules/data"

  project_name         = var.project_name
  kms_key_arn          = module.security_baseline.kms_key_arn
  access_log_bucket_id = module.security_baseline.access_log_bucket_id
}

# --- State migration ------------------------------------------------------

# The security-baseline module was previously called "logging". This tells
# Terraform it's the same set of resources under a new name, so the rename
# doesn't destroy and recreate CloudTrail, KMS or GuardDuty.
moved {
  from = module.logging
  to   = module.security_baseline
}
