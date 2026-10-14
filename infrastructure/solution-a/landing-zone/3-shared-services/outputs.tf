output "container_registry_url" {
  description = "Push Cobble module images here, then use <url>:<version> as container_image in step 4."
  value       = aws_ecr_repository.cobble_module.repository_url
}
