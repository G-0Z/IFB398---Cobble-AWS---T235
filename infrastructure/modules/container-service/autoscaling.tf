# Adds and removes containers with load (Implementation Guide section 6.3:
# 2-10 tasks, target 55-65% CPU). Off unless max_count is set. desired_count
# is the floor, so at idle it costs the same as a fixed-size service.
#
# Each apply resets the running count to desired_count, and the scaler brings
# it back up within a few minutes. That's fine for applies made out of hours.

resource "aws_appautoscaling_target" "this" {
  count = var.max_count != null ? 1 : 0

  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  min_capacity       = var.desired_count
  max_capacity       = var.max_count
}

# Target tracking: AWS creates and manages the CloudWatch alarms itself.
resource "aws_appautoscaling_policy" "cpu" {
  count = var.max_count != null ? 1 : 0

  name               = "${var.name}-cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  resource_id        = aws_appautoscaling_target.this[0].resource_id

  target_tracking_scaling_policy_configuration {
    target_value = var.target_cpu_percent

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
