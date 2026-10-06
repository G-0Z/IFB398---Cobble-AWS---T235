# Mock-based tests: no AWS credentials or real resources needed.

mock_provider "aws" {
  override_resource {
    target = aws_db_instance.this
    values = {
      master_user_secret = [{
        secret_arn    = "arn:aws:secretsmanager:ap-southeast-2:123456789012:secret:rds-abc123"
        secret_status = "active"
        kms_key_id    = "arn:aws:kms:ap-southeast-2:123456789012:key/mock-key-id"
      }]
    }
  }
}

variables {
  identifier                 = "test"
  vpc_id                     = "vpc-12345678"
  subnet_ids                 = ["subnet-aaaa1111", "subnet-bbbb2222"]
  allowed_security_group_ids = ["sg-app12345"]
  kms_key_arn                = "arn:aws:kms:ap-southeast-2:123456789012:key/mock-key-id"
  instance_class             = "db.t4g.micro"
  multi_az                   = false
  backup_retention_days      = 7
  deletion_protection        = false
}

run "database_is_private_and_encrypted" {
  command = apply

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "The database must not be reachable from the internet"
  }

  assert {
    condition     = aws_db_instance.this.storage_encrypted && aws_db_instance.this.kms_key_id == var.kms_key_arn
    error_message = "Storage must be encrypted with kms_key_arn"
  }
}

run "password_is_managed_by_secrets_manager" {
  command = apply

  assert {
    condition     = aws_db_instance.this.manage_master_user_password
    error_message = "RDS should generate and store the admin password, so it never appears in code"
  }
}

run "only_the_application_can_connect" {
  command = apply

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.from_allowed) == 1 && aws_vpc_security_group_ingress_rule.from_allowed[0].referenced_security_group_id == "sg-app12345"
    error_message = "Only the allowed security groups should be able to connect"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.from_allowed[0].from_port == 5432
    error_message = "Only the PostgreSQL port should be open"
  }
}

run "connections_must_use_tls" {
  command = apply

  assert {
    condition     = anytrue([for p in aws_db_parameter_group.this.parameter : p.name == "rds.force_ssl" && p.value == "1"])
    error_message = "The database must refuse unencrypted connections"
  }
}

run "test_environments_tear_down_cleanly" {
  command = apply

  assert {
    condition     = aws_db_instance.this.skip_final_snapshot == true
    error_message = "Without deletion protection, deletion should not wait for a final snapshot"
  }
}

run "production_keeps_a_final_backup" {
  command = apply

  variables {
    multi_az              = true
    backup_retention_days = 35
    deletion_protection   = true
  }

  assert {
    condition     = aws_db_instance.this.skip_final_snapshot == false && aws_db_instance.this.final_snapshot_identifier == "test-final"
    error_message = "With deletion protection, a final snapshot must be taken on delete"
  }

  assert {
    condition     = aws_db_instance.this.multi_az && aws_db_instance.this.backup_retention_period == 35
    error_message = "Production settings should pass through to the database"
  }
}
