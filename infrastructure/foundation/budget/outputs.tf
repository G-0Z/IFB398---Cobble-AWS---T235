output "budget_name" {
  description = "Name of the AWS Budgets budget."
  value       = aws_budgets_budget.monthly.name
}
