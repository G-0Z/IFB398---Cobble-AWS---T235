# Two roles, kept separate on purpose (least privilege):
#   - execution role: what ECS itself needs to START the container
#     (pull the image, write logs, read secrets)
#   - task role: what the APPLICATION may do once running (nothing, unless
#     task_role_policy_json grants something)

locals {
  ecs_tasks_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  # A secret reference can end in ":json-key::" to pick one field. IAM needs
  # the plain secret ARN, which is the first 7 colon-separated parts.
  secret_arns = distinct([for ref in values(var.secrets) : join(":", slice(split(":", ref), 0, 7))])
}

resource "aws_iam_role" "execution" {
  name               = "${var.name}-task-execution"
  assume_role_policy = local.ecs_tasks_trust_policy
}

# AWS's managed policy for starting containers: pull images from ECR and
# write to CloudWatch Logs.
resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Read only the secrets this service is given, nothing else.
resource "aws_iam_role_policy" "execution_secrets" {
  count = length(var.secrets) > 0 ? 1 : 0
  name  = "${var.name}-read-secrets"
  role  = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = local.secret_arns
      }],
      var.secrets_kms_key_arn != null ? [{
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = var.secrets_kms_key_arn
      }] : [],
    )
  })
}

resource "aws_iam_role" "task" {
  name               = "${var.name}-task"
  assume_role_policy = local.ecs_tasks_trust_policy
}

resource "aws_iam_role_policy" "task" {
  count  = var.task_role_policy_json != null ? 1 : 0
  name   = "${var.name}-app-permissions"
  role   = aws_iam_role.task.id
  policy = var.task_role_policy_json
}
