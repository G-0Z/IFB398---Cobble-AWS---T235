# VPC Flow Logs: a record of every network connection attempt in the VPC,
# accepted or rejected (Guide section 4.3).

module "flow_log_destination" {
  source = "../log-delivery"

  log_group_name    = "/${var.project_name}/vpc-flow-logs"
  retention_in_days = 30
  kms_key_arn       = var.kms_key_arn
  role_name         = "${var.project_name}-vpc-flow-logs"
  service_principal = "vpc-flow-logs.amazonaws.com"
}

resource "aws_flow_log" "this" {
  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = module.flow_log_destination.log_group_arn
  iam_role_arn             = module.flow_log_destination.role_arn
  max_aggregation_interval = 60
}
