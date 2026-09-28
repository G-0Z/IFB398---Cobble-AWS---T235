# VPC Flow Logs — section 4.3 of the engineering guide calls this out
# explicitly ("Enable VPC Flow Logs to the central log account").

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/cobble/${var.project_name}/vpc-flow-logs"
  retention_in_days = 30
  kms_key_id        = var.kms_key_arn
}

data "aws_iam_policy_document" "flow_logs_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow_logs" {
  name               = "${var.project_name}-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume.json
}

#tfsec:ignore:aws-iam-no-policy-wildcards -- the "*" here is scoped to this one log group's own streams (arn:*), not a blanket resource wildcard; this is AWS's own documented pattern for granting CloudWatch Logs write access.
data "aws_iam_policy_document" "flow_logs_permissions" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"]
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  name   = "${var.project_name}-vpc-flow-logs"
  role   = aws_iam_role.flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs_permissions.json
}

resource "aws_flow_log" "this" {
  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn             = aws_iam_role.flow_logs.arn
  max_aggregation_interval = 60
}
