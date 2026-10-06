output "plan_role_arn" {
  description = "Role for pull request plans. Put it in the workflow's role-to-assume for pull_request runs."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "Role for approved applies. Put it in the workflow's role-to-assume for the GitHub environment."
  value       = aws_iam_role.apply.arn
}
