output "config_recorder_name" {
  description = "AWS Config recorder name."
  value       = aws_config_configuration_recorder.this.name
}
