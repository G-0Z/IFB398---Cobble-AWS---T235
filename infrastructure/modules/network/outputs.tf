output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "Database subnet IDs (empty if database_subnet_cidrs is empty)."
  value       = aws_subnet.database[*].id
}

output "vpc_cidr" {
  description = "The VPC's IP range, for security group rules."
  value       = aws_vpc.this.cidr_block
}
