# ECS on Fargate: runs the containers without any servers to patch.

data "aws_region" "current" {}

#tfsec:ignore:aws-ecs-enable-container-insight -- a per-environment choice (enable_container_insights): on in prod, off in dev, staging and Solution B's demo to save cost.
resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/${var.name}/app"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

# The recipe for one copy of the container: image, size, settings, logging.
resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name                   = "app"
    image                  = var.container_image
    essential              = true
    readonlyRootFilesystem = var.read_only_root_filesystem

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = [for k, v in var.environment_variables : { name = k, value = v }]
    secrets     = [for k, v in var.secrets : { name = k, valueFrom = v }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "app"
      }
    }
  }])
}

# Keeps desired_count copies running behind the load balancer, replacing any
# that fail. A deployment that can't start healthy containers rolls back
# automatically.
resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  propagate_tags  = "SERVICE"

  health_check_grace_period_seconds = 60

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.task_subnet_ids
    security_groups  = [aws_security_group.tasks.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "app"
    container_port   = var.container_port
  }

  # The load balancer must be listening before the service registers with it.
  depends_on = [aws_lb_listener.https, aws_lb_listener.http_forward]
}
