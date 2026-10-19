output "groups" {
  description = "Group name => group ID."
  value       = { for k, g in aws_identitystore_group.this : g.display_name => g.group_id }
}

output "users" {
  description = "Sign-in names created from users.csv."
  value       = keys(aws_identitystore_user.this)
}
