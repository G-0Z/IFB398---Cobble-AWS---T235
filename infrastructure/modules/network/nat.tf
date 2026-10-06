# Outbound internet for the private subnets, through NAT gateways.
# Nothing in this file is created unless nat_gateway_mode is "single" or
# "one_per_az" (see variables.tf). Solution B leaves it at "none".
#
# Each NAT gateway sits in a public subnet and needs a fixed public IP
# (an Elastic IP). Traffic can go out, but nothing can start a connection in.

locals {
  az_count = length(var.private_subnet_cidrs)

  nat_gateway_count = {
    none       = 0
    single     = 1
    one_per_az = local.az_count
  }[var.nat_gateway_mode]

  # The existing private route table serves the first AZ (or every AZ in
  # "single" mode). "one_per_az" adds one more table for each other AZ, so
  # each AZ can send its traffic to its own NAT gateway.
  extra_private_route_tables = var.nat_gateway_mode == "one_per_az" ? local.az_count - 1 : 0

  # Shared table first, then one per extra AZ: AZ number i uses entry i.
  private_route_table_ids = concat([aws_route_table.private.id], aws_route_table.private_extra_az[*].id)
}

resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-${count.index}"
  }
}

resource "aws_nat_gateway" "this" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-${count.index}"
  }

  # A NAT gateway only works once the VPC has its internet gateway.
  depends_on = [aws_internet_gateway.this]
}

# Route table for each private subnet after the first ("one_per_az" only).
resource "aws_route_table" "private_extra_az" {
  count  = local.extra_private_route_tables
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-private-rt-${count.index + 1}"
  }
}

# Internet-bound traffic from the shared private route table goes to the
# first NAT gateway.
resource "aws_route" "private_to_nat" {
  count                  = local.nat_gateway_count > 0 ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

# Each extra route table sends traffic to the NAT gateway in its own AZ.
resource "aws_route" "private_extra_az_to_nat" {
  count                  = local.extra_private_route_tables
  route_table_id         = aws_route_table.private_extra_az[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index + 1].id
}
