output "endpoint" {
  description = "Hostname the application connects to."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "PostgreSQL port."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Name of the database inside the instance."
  value       = aws_db_instance.this.db_name
}

output "admin_secret_arn" {
  description = "Secrets Manager secret holding the admin username and password (JSON keys \"username\" and \"password\")."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "security_group_id" {
  description = "The database's security group."
  value       = aws_security_group.this.id
}

output "allowed_security_group_ids" {
  description = "Security groups that can connect to the database (for audits and the security controls document)."
  value       = aws_vpc_security_group_ingress_rule.from_allowed[*].referenced_security_group_id
}
