# Plan/mock-based tests: no AWS credentials or real resources needed, so
# these run free in CI on every PR. See infrastructure/modules/network/README.md
# for what this module is supposed to do.

mock_provider "aws" {
  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
    }
  }

  # aws_flow_log validates log_destination/iam_role_arn look like real ARNs
  # at plan time; the mock's fabricated arn for brand-new resources doesn't
  # pass that check.
  override_resource {
    target = module.flow_log_destination.aws_cloudwatch_log_group.this
    values = {
      arn = "arn:aws:logs:ap-southeast-2:123456789012:log-group:/test/vpc-flow-logs"
    }
  }

  override_resource {
    target = module.flow_log_destination.aws_iam_role.this
    values = {
      arn = "arn:aws:iam::123456789012:role/test-vpc-flow-logs"
    }
  }
}

variables {
  project_name         = "test"
  vpc_cidr             = "10.99.0.0/16"
  public_subnet_cidrs  = ["10.99.0.0/24", "10.99.1.0/24"]
  private_subnet_cidrs = ["10.99.10.0/24", "10.99.11.0/24"]
  kms_key_arn          = "arn:aws:kms:ap-southeast-2:123456789012:key/mock-key-id"
}

run "vpc_has_correct_cidr" {
  command = apply

  assert {
    condition     = aws_vpc.this.cidr_block == var.vpc_cidr
    error_message = "VPC CIDR block does not match the vpc_cidr input"
  }
}

run "creates_one_subnet_per_cidr_entry" {
  command = apply

  assert {
    condition     = length(aws_subnet.public) == length(var.public_subnet_cidrs)
    error_message = "Expected one public subnet per public_subnet_cidrs entry"
  }

  assert {
    condition     = length(aws_subnet.private) == length(var.private_subnet_cidrs)
    error_message = "Expected one private subnet per private_subnet_cidrs entry"
  }
}

run "public_subnets_assign_public_ip_private_do_not" {
  command = apply

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch])
    error_message = "All public subnets must auto-assign a public IP"
  }

  assert {
    condition     = alltrue([for s in aws_subnet.private : s.map_public_ip_on_launch != true])
    error_message = "Private subnets must not auto-assign a public IP"
  }
}

run "private_route_table_has_no_internet_route" {
  command = apply

  assert {
    condition     = length(aws_route_table.private.route) == 0
    error_message = "Private route table should have no routes while there's no NAT gateway — if this now fails because a route was added, update this test alongside that work"
  }
}

run "public_route_table_routes_to_internet_gateway" {
  command = apply

  assert {
    condition = anytrue([
      for r in aws_route_table.public.route :
      r.cidr_block == "0.0.0.0/0" && r.gateway_id == aws_internet_gateway.this.id
    ])
    error_message = "Public route table must route 0.0.0.0/0 to the internet gateway"
  }
}

run "vpc_flow_logs_capture_all_traffic_to_the_vpc" {
  command = apply

  assert {
    condition     = aws_flow_log.this.vpc_id == aws_vpc.this.id
    error_message = "Flow log must be attached to this module's VPC"
  }

  assert {
    condition     = aws_flow_log.this.traffic_type == "ALL"
    error_message = "Flow log should capture ALL traffic, not just ACCEPT or REJECT"
  }

  assert {
    condition     = aws_flow_log.this.log_destination_type == "cloud-watch-logs"
    error_message = "Flow log should deliver to CloudWatch Logs"
  }
}

# The log group's encryption and the delivery role's scope are tested once
# in modules/log-delivery. This checks the flow log is wired to them.
run "vpc_flow_logs_deliver_via_the_log_delivery_module" {
  command = apply

  assert {
    condition     = aws_flow_log.this.log_destination == module.flow_log_destination.log_group_arn
    error_message = "Flow log must deliver to the flow_log_destination log group"
  }

  assert {
    condition     = aws_flow_log.this.iam_role_arn == module.flow_log_destination.role_arn
    error_message = "Flow log must use the flow_log_destination role"
  }
}

# --- Optional extras used by Solution A --------------------------------------
# The runs above use the defaults (no NAT, no database tier, no endpoint),
# which is exactly what Solution B deploys.

run "defaults_create_no_nat_database_tier_or_endpoint" {
  command = apply

  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_subnet.database) == 0 && length(aws_vpc_endpoint.s3) == 0
    error_message = "With default inputs the module must not create NAT gateways, database subnets or an S3 endpoint (Solution B depends on this)"
  }
}

run "single_nat_gateway_serves_every_private_subnet" {
  command = apply

  variables {
    nat_gateway_mode = "single"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1 && length(aws_route.private_to_nat) == 1
    error_message = "\"single\" mode should create one NAT gateway and one route to it"
  }

  assert {
    condition     = alltrue([for a in aws_route_table_association.private : a.route_table_id == aws_route_table.private.id])
    error_message = "In \"single\" mode every private subnet should use the shared private route table"
  }
}

run "one_nat_gateway_per_az_with_its_own_route_table" {
  command = apply

  variables {
    nat_gateway_mode = "one_per_az"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == length(var.private_subnet_cidrs)
    error_message = "\"one_per_az\" mode should create one NAT gateway per private subnet"
  }

  assert {
    condition     = aws_route_table_association.private[1].route_table_id == aws_route_table.private_extra_az[0].id
    error_message = "The second AZ's private subnet should use its own route table"
  }

  assert {
    condition     = aws_route.private_extra_az_to_nat[0].nat_gateway_id == aws_nat_gateway.this[1].id
    error_message = "The second AZ's route table should send traffic to the second AZ's NAT gateway"
  }
}

run "database_subnets_have_no_internet_route" {
  command = apply

  variables {
    nat_gateway_mode      = "single"
    database_subnet_cidrs = ["10.99.20.0/24", "10.99.21.0/24"]
  }

  assert {
    condition     = length(aws_subnet.database) == 2
    error_message = "Expected one database subnet per database_subnet_cidrs entry"
  }

  assert {
    condition     = length(aws_route_table.database[0].route) == 0
    error_message = "The database route table must have no internet route, not even through NAT"
  }
}

run "rejects_unknown_nat_gateway_mode" {
  command = plan

  variables {
    nat_gateway_mode = "two"
  }

  expect_failures = [var.nat_gateway_mode]
}

run "default_security_group_can_be_locked_down" {
  command = apply

  variables {
    restrict_default_security_group = true
  }

  assert {
    condition     = length(aws_default_security_group.this[0].ingress) == 0 && length(aws_default_security_group.this[0].egress) == 0
    error_message = "The default security group should have no rules"
  }
}
