# Solution A only. Lets each environment's GitHub Actions roles, which live
# in the member accounts, read and write their state in this bucket. Each
# role's own IAM policy then narrows it to that environment's state file
# (modules/github-oidc). Nothing here is created unless organization_id is
# set, so Solution B's state bucket is unchanged.

resource "aws_s3_bucket_policy" "org_state_access" {
  count  = var.organization_id != null ? 1 : 0
  bucket = aws_s3_bucket.tfstate.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "WorkloadDeployRolesListState"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.tfstate.arn
        Condition = {
          StringEquals = { "aws:PrincipalOrgID" = var.organization_id }
          ArnLike      = { "aws:PrincipalArn" = "arn:aws:iam::*:role/cobble-*-terraform-*" }
        }
      },
      {
        Sid       = "WorkloadDeployRolesUseState"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource  = "${aws_s3_bucket.tfstate.arn}/solution-a/4-workloads/*"
        Condition = {
          StringEquals = { "aws:PrincipalOrgID" = var.organization_id }
          ArnLike      = { "aws:PrincipalArn" = "arn:aws:iam::*:role/cobble-*-terraform-*" }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.tfstate.arn, "${aws_s3_bucket.tfstate.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.tfstate]
}
