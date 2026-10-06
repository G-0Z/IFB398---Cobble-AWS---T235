# Shared Services: things every environment uses, kept out of the
# environments themselves. For now that is the private container registry
# where Cobble module images are stored.

data "aws_organizations_organization" "this" {}

# --- Account safety settings -----------------------------------------------

module "account_baseline" {
  source = "../../modules/account-baseline"

  name               = "cobble-shared"
  config_bucket_name = var.config_bucket_name
  config_kms_key_arn = var.config_kms_key_arn
}

# --- Container registry (Amazon ECR) ---------------------------------------
# Immutable tags: once "cobble-module:1.4.0" is pushed it can never be
# replaced, so what was tested is exactly what runs in prod. Every image is
# scanned for known vulnerabilities when it's pushed.

#tfsec:ignore:aws-ecr-repository-customer-key -- AWS-managed encryption keeps cross-account image pulls simple (no key sharing). Images contain code, not tenant data.
resource "aws_ecr_repository" "cobble_module" {
  name                 = "cobble-module"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# Keep the 30 most recent images; delete untagged leftovers after 7 days.
resource "aws_ecr_lifecycle_policy" "cobble_module" {
  repository = aws_ecr_repository.cobble_module.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the 30 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = { type = "expire" }
      },
    ]
  })
}

# Any account in the organisation can pull images (read-only). Nobody
# outside the organisation can.
#tfsec:ignore:aws-ecr-no-public-access -- not public: the aws:PrincipalOrgID condition limits pulls to accounts in this organisation. tfsec doesn't evaluate conditions.
resource "aws_ecr_repository_policy" "cobble_module" {
  repository = aws_ecr_repository.cobble_module.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "OrganizationCanPull"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer", "ecr:BatchCheckLayerAvailability"]
      Condition = { StringEquals = { "aws:PrincipalOrgID" = data.aws_organizations_organization.this.id } }
    }]
  })
}

# --- Cost guardrail ---------------------------------------------------------

resource "aws_budgets_budget" "monthly" {
  name         = "cobble-shared-monthly-cost"
  budget_type  = "COST"
  limit_amount = tostring(var.budget_limit)
  limit_unit   = var.budget_currency
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}
