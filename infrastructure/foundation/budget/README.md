## Purpose

Cost guardrail for the shared student AWS account: one monthly budget with
email alerts at 80% and 100% of spend.

## Resources created

- `aws_budgets_budget` — whole-account monthly cost budget, two notification
  thresholds (both `ACTUAL` spend, not forecast).

## Inputs

| Name | Description | Default |
|---|---|---|
| `project_name` | Naming prefix | none, required |
| `alert_email` | Where alerts go | none, required |
| `budget_limit` | Monthly limit | `25` |
| `budget_currency` | Currency | `USD` |

## Outputs

| Name | Description |
|---|---|
| `budget_name` | Name of the created budget |
