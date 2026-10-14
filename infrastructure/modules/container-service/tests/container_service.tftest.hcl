# Mock-based tests: no AWS credentials or real resources needed.

mock_provider "aws" {
  override_data {
    target = data.aws_region.current
    values = { name = "ap-southeast-2" }
  }

  # The load balancer and listeners check for real-looking ARNs at plan time.
  override_resource {
    target = aws_lb.this
    values = {
      arn      = "arn:aws:elasticloadbalancing:ap-southeast-2:123456789012:loadbalancer/app/test-alb/abc123"
      dns_name = "test-alb-123.ap-southeast-2.elb.amazonaws.com"
    }
  }

  override_resource {
    target = aws_lb_target_group.this
    values = { arn = "arn:aws:elasticloadbalancing:ap-southeast-2:123456789012:targetgroup/test-tg/abc123" }
  }

  override_resource {
    target = aws_wafv2_web_acl.this
    values = { arn = "arn:aws:wafv2:ap-southeast-2:123456789012:regional/webacl/test-waf/abc123" }
  }

  override_resource {
    target = aws_iam_role.execution
    values = { arn = "arn:aws:iam::123456789012:role/test-task-execution" }
  }

  override_resource {
    target = aws_iam_role.task
    values = { arn = "arn:aws:iam::123456789012:role/test-task" }
  }
}

variables {
  name                     = "test"
  vpc_id                   = "vpc-12345678"
  load_balancer_subnet_ids = ["subnet-aaaa1111", "subnet-bbbb2222"]
  task_subnet_ids          = ["subnet-cccc3333", "subnet-dddd4444"]
  container_image          = "public.ecr.aws/nginx/nginx:stable"
  kms_key_arn              = "arn:aws:kms:ap-southeast-2:123456789012:key/mock-key-id"
}

run "containers_only_accept_traffic_from_the_load_balancer" {
  command = apply

  assert {
    condition     = aws_vpc_security_group_ingress_rule.tasks_from_load_balancer.referenced_security_group_id == aws_security_group.load_balancer.id
    error_message = "Containers must only accept traffic from the load balancer's security group"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.tasks_from_load_balancer.cidr_ipv4 == null
    error_message = "Containers must not accept traffic from an IP range"
  }
}

run "containers_have_no_public_ip_by_default" {
  command = apply

  assert {
    condition     = one(aws_ecs_service.this.network_configuration).assign_public_ip == false
    error_message = "Containers should not get a public IP unless assign_public_ip is set"
  }
}

run "without_a_certificate_serves_plain_http_only" {
  command = apply

  assert {
    condition     = length(aws_lb_listener.http_forward) == 1 && length(aws_lb_listener.https) == 0
    error_message = "With no certificate there should be one plain HTTP listener and no HTTPS listener"
  }

  assert {
    condition     = startswith(output.url, "http://")
    error_message = "The URL should be http:// without a certificate"
  }
}

run "with_a_certificate_uses_https_and_redirects_http" {
  command = apply

  variables {
    certificate_arn = "arn:aws:acm:ap-southeast-2:123456789012:certificate/mock"
  }

  assert {
    condition     = length(aws_lb_listener.https) == 1 && length(aws_lb_listener.http_forward) == 0
    error_message = "With a certificate there should be an HTTPS listener and no plain HTTP forwarding"
  }

  assert {
    condition     = one(one(aws_lb_listener.http_redirect[0].default_action).redirect).protocol == "HTTPS"
    error_message = "HTTP must redirect to HTTPS"
  }

  assert {
    condition     = aws_lb_listener.https[0].ssl_policy == "ELBSecurityPolicy-TLS13-1-2-2021-06"
    error_message = "HTTPS must allow only TLS 1.2 and 1.3"
  }
}

run "load_balancer_drops_invalid_headers" {
  command = apply

  assert {
    condition     = aws_lb.this.drop_invalid_header_fields
    error_message = "The load balancer should drop invalid HTTP headers"
  }
}

run "waf_is_off_by_default" {
  command = apply

  assert {
    condition     = length(aws_wafv2_web_acl.this) == 0
    error_message = "WAF should only be created when enable_waf is true"
  }
}

run "waf_uses_managed_rules_and_a_rate_limit" {
  command = apply

  variables {
    enable_waf = true
  }

  assert {
    condition     = length(aws_wafv2_web_acl.this[0].rule) == 4
    error_message = "WAF should have three AWS managed rule groups plus a rate limit"
  }

  assert {
    condition     = aws_wafv2_web_acl_association.this[0].resource_arn == aws_lb.this.arn
    error_message = "WAF must be attached to this load balancer"
  }
}

run "execution_role_reads_only_its_own_secrets" {
  command = apply

  variables {
    secrets = {
      DB_PASSWORD = "arn:aws:secretsmanager:ap-southeast-2:123456789012:secret:rds-abc123:password::"
    }
  }

  assert {
    condition     = jsondecode(aws_iam_role_policy.execution_secrets[0].policy).Statement[0].Resource == ["arn:aws:secretsmanager:ap-southeast-2:123456789012:secret:rds-abc123"]
    error_message = "The execution role should be allowed to read exactly the given secret, without the JSON-key suffix"
  }
}

run "application_has_no_aws_permissions_by_default" {
  command = apply

  assert {
    condition     = length(aws_iam_role_policy.task) == 0
    error_message = "The task role should have no permissions unless task_role_policy_json is given"
  }
}

run "container_logs_are_encrypted" {
  command = apply

  assert {
    condition     = aws_cloudwatch_log_group.this.kms_key_id == var.kms_key_arn
    error_message = "The container log group must be encrypted with kms_key_arn"
  }
}

run "failed_deployments_roll_back" {
  command = apply

  assert {
    condition     = one(aws_ecs_service.this.deployment_circuit_breaker).rollback
    error_message = "A deployment that can't start healthy containers should roll back automatically"
  }
}

run "auto_scaling_is_off_by_default" {
  command = plan

  assert {
    condition     = length(aws_appautoscaling_target.this) == 0
    error_message = "Auto scaling must be off unless max_count is set"
  }
}

run "auto_scaling_keeps_desired_count_as_the_floor" {
  command = plan

  variables {
    desired_count = 2
    max_count     = 10
  }

  assert {
    condition     = aws_appautoscaling_target.this[0].min_capacity == 2 && aws_appautoscaling_target.this[0].max_capacity == 10
    error_message = "Auto scaling must run between desired_count and max_count"
  }

  assert {
    condition     = aws_appautoscaling_policy.cpu[0].target_tracking_scaling_policy_configuration[0].target_value == 60
    error_message = "Auto scaling must target 60% CPU by default"
  }
}

run "max_count_below_desired_count_is_rejected" {
  command = plan

  variables {
    desired_count = 2
    max_count     = 1
  }

  expect_failures = [var.max_count]
}
