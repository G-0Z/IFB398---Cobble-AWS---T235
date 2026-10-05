output "role_arn" {
  description = "ARN GitHub Actions assumes to deploy."
  value       = aws_iam_role.deploy.arn
}
