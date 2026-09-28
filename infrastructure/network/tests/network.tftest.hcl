# Plan/mock-based tests: no AWS credentials or real resources needed, so
# these run free in CI on every PR. See infrastructure/network/README.md
# for what this module is supposed to do.

mock_provider "aws" {
  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
    }
  }

  # aws_iam_policy_document is a local computation, not an AWS API call, but
  # mock_provider mocks it anyway (fabricating a non-JSON placeholder). The
  # consuming IAM resources validate that input as real JSON, so it needs a
  # valid stand-in — this doesn't test the policy's actual content.
  override_data {
    target = data.aws_iam_policy_document.flow_logs_assume
    values = {
      json = jsonencode({ Version = "2012-10-17", Statement = [] })
    }
  }

  override_data {
    target = data.aws_iam_policy_document.flow_logs_permissions
    values = {
      json = jsonencode({ Version = "2012-10-17", Statement = [] })
    }
  }

  # aws_flow_log validates log_destination/iam_role_arn look like real ARNs
  # at plan time; the mock's fabricated arn for brand-new resources doesn't
  # pass that check.
  override_resource {
    target = aws_cloudwatch_log_group.vpc_flow_logs
    values = {
      arn = "arn:aws:logs:ap-southeast-2:123456789012:log-group:/cobble/test/vpc-flow-logs"
    }
  }

  override_resource {
    target = aws_iam_role.flow_logs
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

run "vpc_flow_logs_group_is_encrypted" {
  command = apply

  assert {
    condition     = aws_cloudwatch_log_group.vpc_flow_logs.kms_key_id == var.kms_key_arn
    error_message = "Flow log group must be encrypted with the supplied kms_key_arn"
  }
}
