# Mock-based end-to-end test of one whole environment: every module wired
# together, no AWS credentials or real resources needed. The detailed
# behaviour of each building block is tested in that module's own tests; this
# file checks they are connected correctly.

mock_provider "aws" {
  override_data {
    target = data.aws_caller_identity.current
    values = { account_id = "111111111111" }
  }

  override_data {
    target = data.aws_region.current
    values = { name = "ap-southeast-2" }
  }

  override_data {
    target = module.network.data.aws_availability_zones.available
    values = { names = ["ap-southeast-2a", "ap-southeast-2b"] }
  }

  override_data {
    target = module.network.data.aws_region.current
    values = { name = "ap-southeast-2" }
  }

  override_data {
    target = module.app.data.aws_region.current
    values = { name = "ap-southeast-2" }
  }

  override_data {
    target = module.access_logs.data.aws_elb_service_account.current
    values = { arn = "arn:aws:iam::783225319266:root" }
  }

  # Resources whose ARNs other resources validate at plan time.
  override_resource {
    target = aws_kms_key.this
    values = { arn = "arn:aws:kms:ap-southeast-2:111111111111:key/mock-env-key" }
  }

  override_resource {
    target = module.network.module.flow_log_destination.aws_cloudwatch_log_group.this
    values = { arn = "arn:aws:logs:ap-southeast-2:111111111111:log-group:/cobble-dev/vpc-flow-logs" }
  }

  override_resource {
    target = module.network.module.flow_log_destination.aws_iam_role.this
    values = { arn = "arn:aws:iam::111111111111:role/cobble-dev-vpc-flow-logs" }
  }

  override_resource {
    target = module.app.aws_lb.this
    values = {
      arn      = "arn:aws:elasticloadbalancing:ap-southeast-2:111111111111:loadbalancer/app/cobble-dev-alb/abc"
      dns_name = "cobble-dev-alb-123.ap-southeast-2.elb.amazonaws.com"
    }
  }

  override_resource {
    target = module.app.aws_lb_target_group.this
    values = { arn = "arn:aws:elasticloadbalancing:ap-southeast-2:111111111111:targetgroup/cobble-dev-tg/abc" }
  }

  override_resource {
    target = module.app.aws_wafv2_web_acl.this
    values = { arn = "arn:aws:wafv2:ap-southeast-2:111111111111:regional/webacl/cobble-dev-waf/abc" }
  }

  override_resource {
    target = module.app.aws_iam_role.execution
    values = { arn = "arn:aws:iam::111111111111:role/cobble-dev-task-execution" }
  }

  override_resource {
    target = module.app.aws_iam_role.task
    values = { arn = "arn:aws:iam::111111111111:role/cobble-dev-task" }
  }

  override_resource {
    target = module.data_bucket.aws_s3_bucket.this
    values = { arn = "arn:aws:s3:::cobble-dev-data-111111111111" }
  }

  override_resource {
    target = module.account_baseline.aws_iam_role.config
    values = { arn = "arn:aws:iam::111111111111:role/cobble-dev-config-recorder" }
  }

  override_resource {
    target = module.github_deploy.aws_iam_openid_connect_provider.github
    values = { arn = "arn:aws:iam::111111111111:oidc-provider/token.actions.githubusercontent.com" }
  }

  override_resource {
    target = module.app.aws_security_group.tasks
    values = { id = "sg-0app000000000000" }
  }

  override_resource {
    target = module.database.aws_security_group.this
    values = { id = "sg-0db0000000000000" }
  }

  override_resource {
    target = module.database.aws_db_instance.this
    values = {
      address = "cobble-dev.abc.ap-southeast-2.rds.amazonaws.com"
      port    = 5432
      master_user_secret = [{
        secret_arn    = "arn:aws:secretsmanager:ap-southeast-2:111111111111:secret:rds-abc123"
        secret_status = "active"
        kms_key_id    = "arn:aws:kms:ap-southeast-2:111111111111:key/mock-env-key"
      }]
    }
  }
}

mock_provider "tls" {
  override_data {
    target = module.github_deploy.data.tls_certificate.github
    values = {
      certificates = [{
        sha1_fingerprint     = "6938fd4d98bab03faadb97b34396831e3780aea1"
        cert_pem             = "mock"
        is_ca                = true
        issuer               = "mock"
        max_path_length      = 0
        not_after            = "2030-01-01T00:00:00Z"
        not_before           = "2020-01-01T00:00:00Z"
        public_key_algorithm = "RSA"
        serial_number        = "1"
        signature_algorithm  = "SHA256-RSA"
        subject              = "mock"
        version              = 3
      }]
    }
  }
}

# Dev-style settings.
variables {
  environment           = "dev"
  protect_from_deletion = false

  vpc_cidr              = "10.28.0.0/16"
  public_subnet_cidrs   = ["10.28.0.0/24", "10.28.1.0/24"]
  private_subnet_cidrs  = ["10.28.10.0/24", "10.28.11.0/24"]
  database_subnet_cidrs = ["10.28.20.0/24", "10.28.21.0/24"]
  nat_gateway_mode      = "single"

  container_image           = "111111111111.dkr.ecr.ap-southeast-2.amazonaws.com/cobble-module:1.0.0"
  app_cpu                   = 256
  app_memory                = 512
  app_desired_count         = 1
  enable_waf                = false
  enable_container_insights = false
  log_retention_days        = 30

  db_instance_class        = "db.t4g.micro"
  db_multi_az              = false
  db_backup_retention_days = 7
  db_performance_insights  = false

  budget_limit = 100
  alert_email  = "platform-alerts@cobble.test"

  github_org        = "example-org"
  github_repo       = "example-repo"
  state_bucket_name = "cobble-tfstate-000000000000"
  state_key         = "solution-a/4-workloads/dev/terraform.tfstate"

  config_bucket_name = "cobble-config-999999999999"
  config_kms_key_arn = "arn:aws:kms:ap-southeast-2:999999999999:key/mock-security-key"
}

run "database_only_accepts_the_app" {
  command = apply

  assert {
    condition     = module.database.allowed_security_group_ids == [module.app.task_security_group_id]
    error_message = "Only the app's containers should be allowed to connect to the database"
  }

  assert {
    condition     = output.database_endpoint == "cobble-dev.abc.ap-southeast-2.rds.amazonaws.com"
    error_message = "The database endpoint should be passed through"
  }
}

run "dev_tears_down_cleanly" {
  command = apply

  assert {
    condition     = aws_kms_key.this.deletion_window_in_days == 7
    error_message = "Without deletion protection the key should use the shortest deletion window"
  }
}

run "prod_turns_on_safeguards" {
  command = apply

  variables {
    environment           = "prod"
    protect_from_deletion = true
    nat_gateway_mode      = "one_per_az"
    enable_waf            = true
    db_multi_az           = true
  }

  assert {
    condition     = aws_kms_key.this.deletion_window_in_days == 30
    error_message = "Production keys should have the longest deletion window"
  }

  assert {
    condition     = module.app.web_acl_arn != null
    error_message = "Production should have WAF in front of the load balancer"
  }
}

run "budget_alerts_on_actual_and_forecast_spend" {
  command = apply

  assert {
    condition     = length(aws_budgets_budget.monthly.notification) == 2
    error_message = "The budget should alert on actual and on forecast spend"
  }
}

run "rejects_unknown_environment_names" {
  command = plan

  variables {
    environment = "test"
  }

  expect_failures = [var.environment]
}
