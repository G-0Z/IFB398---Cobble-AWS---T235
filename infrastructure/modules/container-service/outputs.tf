output "url" {
  description = "Address to open in a browser."
  value       = "${var.certificate_arn != null ? "https" : "http"}://${aws_lb.this.dns_name}"
}

output "load_balancer_dns_name" {
  description = "Load balancer DNS name, for a Route 53 alias record."
  value       = aws_lb.this.dns_name
}

output "load_balancer_zone_id" {
  description = "Load balancer hosted zone ID, for a Route 53 alias record."
  value       = aws_lb.this.zone_id
}

output "task_security_group_id" {
  description = "The containers' security group, so a database can accept connections from them."
  value       = aws_security_group.tasks.id
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "web_acl_arn" {
  description = "WAF web ACL ARN, or null when enable_waf is false."
  value       = var.enable_waf ? aws_wafv2_web_acl.this[0].arn : null
}
