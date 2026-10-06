# Lets GitHub Actions deploy this account without any stored AWS keys.
# GitHub proves who it is with a short-lived OpenID Connect (OIDC) token, and
# AWS hands back temporary credentials for one of two roles:
#
#   <name>-terraform-plan   pull requests: read-only, can only run `plan`
#   <name>-terraform-apply  the GitHub environment (with required
#                           reviewers): can run `apply`
#
# This is the split ADR 0001 (D6) designed. Solution B's single deploy role
# (modules/oidc-deploy-role) is left unchanged.

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

locals {
  repo = "repo:${var.github_org}/${var.github_repo}"

  # Who may assume a role: GitHub tokens for this repo, in the given context.
  trust_policy = { for role, subject in {
    plan  = "${local.repo}:pull_request"
    apply = "${local.repo}:environment:${var.github_environment}"
    } : role => jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect    = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = subject
          }
        }
      }]
  }) }

  state_bucket_arn = "arn:aws:s3:::${var.state_bucket_name}"
}

# --- Plan role (pull requests) ---------------------------------------------

resource "aws_iam_role" "plan" {
  name                 = "${var.name}-terraform-plan"
  assume_role_policy   = local.trust_policy.plan
  max_session_duration = 3600
}

# AWS's read-only policy: can look at everything, change nothing. It does not
# include reading secret values.
resource "aws_iam_role_policy_attachment" "plan_read_only" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Read the state file, and take the state lock while planning.
resource "aws_iam_role_policy" "plan_state" {
  name = "${var.name}-terraform-state-read"
  role = aws_iam_role.plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = local.state_bucket_arn
      },
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${local.state_bucket_arn}/${var.state_key}"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${local.state_bucket_arn}/${var.state_key}.tflock"
      },
    ]
  })
}

# --- Apply role (approved GitHub environment) ------------------------------

resource "aws_iam_role" "apply" {
  name                 = "${var.name}-terraform-apply"
  assume_role_policy   = local.trust_policy.apply
  max_session_duration = 3600
}

# Applying Terraform creates IAM roles, networks, databases and more, so this
# role is an administrator of this one account. What keeps it safe:
#   - only an approved run of the GitHub environment can assume it
#   - organisation guardrails (SCPs) still stop it disabling CloudTrail,
#     GuardDuty, Config or Security Hub, or using other regions
#   - every action it takes is recorded by the organisation CloudTrail
#tfsec:ignore:aws-iam-no-policy-wildcards -- see the comment above; guarded by environment approval and SCPs.
resource "aws_iam_role_policy_attachment" "apply_admin" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy" "apply_state" {
  name = "${var.name}-terraform-state-write"
  role = aws_iam_role.apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = local.state_bucket_arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["${local.state_bucket_arn}/${var.state_key}", "${local.state_bucket_arn}/${var.state_key}.tflock"]
      },
    ]
  })
}
