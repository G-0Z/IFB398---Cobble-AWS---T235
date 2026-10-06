output "log_group_arn" {
  description = "ARN of the log group, without the trailing \":*\"."
  value       = aws_cloudwatch_log_group.this.arn
}

output "role_arn" {
  description = "ARN of the role the delivering service assumes."
  value       = aws_iam_role.this.arn
}
