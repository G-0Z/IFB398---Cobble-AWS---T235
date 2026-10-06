data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restricted to this repo's main branch only. Pull requests are
    # deliberately excluded: this role has iam:*, so any PR branch able to
    # assume it could grant itself admin. PR plans, when CI does them, need
    # a separate read-only role (see docs/02-landing-zone-design/adr/0001).
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name               = "${var.project_name}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

# Scoped by service, not by resource ARN. Tightening this to specific
# resource ARNs is a documented next step, not done yet — see this
# module's README.
#tfsec:ignore:aws-iam-no-policy-wildcards -- documented PoC simplification, see comment above.
data "aws_iam_policy_document" "deploy_permissions" {
  statement {
    sid    = "PoCServiceAccess"
    effect = "Allow"
    actions = [
      "ec2:*",
      "s3:*",
      "iam:*",
      "cloudtrail:*",
      "guardduty:*",
      "budgets:*",
      "kms:*",
      "logs:*",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "${var.project_name}-github-deploy-permissions"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy_permissions.json
}
