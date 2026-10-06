output "app_url" {
  description = "Address of the Cobble application."
  value       = module.environment.app_url
}

output "load_balancer_dns_name" {
  description = "Point this environment's domain here (Route 53 alias record)."
  value       = module.environment.load_balancer_dns_name
}

output "github_plan_role_arn" {
  description = "For the CI workflow: role for pull request plans."
  value       = module.environment.github_plan_role_arn
}

output "github_apply_role_arn" {
  description = "For the CI workflow: role for approved applies."
  value       = module.environment.github_apply_role_arn
}
