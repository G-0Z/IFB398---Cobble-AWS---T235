# S3 gateway endpoint: lets private and database subnets reach S3 inside the
# AWS network. It's free, and keeps S3 traffic off the (paid) NAT gateway.
# Only created when enable_s3_gateway_endpoint is true.

data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_s3_gateway_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.private.id],
    aws_route_table.private_extra_az[*].id,
    aws_route_table.database[*].id,
  )

  tags = {
    Name = "${var.project_name}-s3-endpoint"
  }
}
