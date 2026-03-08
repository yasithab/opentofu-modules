################################################################################
# Repository (Public and Private)
################################################################################

output "repository_name" {
  description = "Name of the repository"
  value       = try(aws_ecr_repository.this.name, aws_ecrpublic_repository.this.id, null)
}

output "repository_arn" {
  description = "Full ARN of the repository"
  value       = try(aws_ecr_repository.this.arn, aws_ecrpublic_repository.this.arn, null)
}

output "repository_registry_id" {
  description = "The registry ID where the repository was created"
  value       = try(aws_ecr_repository.this.registry_id, aws_ecrpublic_repository.this.registry_id, null)
}

output "repository_url" {
  description = "The URL of the repository"
  value       = try(aws_ecr_repository.this.repository_url, aws_ecrpublic_repository.this.repository_uri, null)
}
