# Plan/mock-based tests: no AWS credentials or real resources needed.
# See infrastructure/foundation/budget/README.md for what this module does.

mock_provider "aws" {}

variables {
  project_name    = "test"
  alert_email     = "alerts@example.com"
  budget_limit    = 25
  budget_currency = "USD"
}

run "budget_has_correct_name_and_limit" {
  command = apply

  assert {
    condition     = aws_budgets_budget.monthly.name == "test-monthly-cost"
    error_message = "Budget name should be <project_name>-monthly-cost"
  }

  assert {
    condition     = aws_budgets_budget.monthly.limit_amount == "25"
    error_message = "Budget limit should match the budget_limit variable"
  }

  assert {
    condition     = aws_budgets_budget.monthly.limit_unit == "USD"
    error_message = "Budget currency should match the budget_currency variable"
  }
}

run "budget_has_80_and_100_percent_alerts" {
  command = apply

  assert {
    condition     = length(aws_budgets_budget.monthly.notification) == 2
    error_message = "Budget should have exactly two notification thresholds"
  }

  assert {
    condition     = anytrue([for n in aws_budgets_budget.monthly.notification : n.threshold == 80])
    error_message = "Budget must alert at 80% of the limit"
  }

  assert {
    condition     = anytrue([for n in aws_budgets_budget.monthly.notification : n.threshold == 100])
    error_message = "Budget must alert at 100% of the limit"
  }
}

run "alerts_go_to_the_configured_email" {
  command = apply

  assert {
    condition     = alltrue([for n in aws_budgets_budget.monthly.notification : contains(n.subscriber_email_addresses, "alerts@example.com")])
    error_message = "Every notification must include the configured alert_email"
  }
}
