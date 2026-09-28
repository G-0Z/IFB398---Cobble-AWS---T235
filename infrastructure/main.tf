module "oidc_deploy_role" {
  source = "./foundation/oidc-deploy-role"

  project_name = var.project_name
  github_org   = var.github_org
  github_repo  = var.github_repo
}

module "logging" {
  source = "./foundation/logging"

  project_name = var.project_name
}

module "budget" {
  source = "./foundation/budget"

  project_name    = var.project_name
  alert_email     = var.alert_email
  budget_limit    = var.budget_limit
  budget_currency = var.budget_currency
}

module "network" {
  source = "./network"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "data" {
  source = "./data"

  project_name = var.project_name
  kms_key_arn  = module.logging.kms_key_arn
}
