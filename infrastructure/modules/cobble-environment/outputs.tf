output "app_url" {
  description = "Address of the Cobble application."
  value       = module.app.url
}

output "load_balancer_dns_name" {
  description = "Point the environment's domain (e.g. dev.cobble.com) here with a Route 53 alias record."
  value       = module.app.load_balancer_dns_name
}

output "database_endpoint" {
  description = "Database hostname (private; reachable only from the app)."
  value       = module.database.endpoint
}

output "data_bucket_name" {
  description = "Tenant data bucket."
  value       = module.data_bucket.bucket_name
}

output "github_plan_role_arn" {
  description = "Role GitHub Actions assumes for pull request plans."
  value       = module.github_deploy.plan_role_arn
}

output "github_apply_role_arn" {
  description = "Role GitHub Actions assumes for approved applies."
  value       = module.github_deploy.apply_role_arn
}

output "kms_key_arn" {
  description = "The environment's encryption key."
  value       = aws_kms_key.this.arn
}
