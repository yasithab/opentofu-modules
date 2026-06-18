output "arn" {
  description = "ARN of the SSM document."
  value       = try(aws_ssm_document.this.arn, "")
}

output "name" {
  description = "Name of the SSM document."
  value       = try(aws_ssm_document.this.name, "")
}

output "document_version" {
  description = "Document version created by this resource."
  value       = try(aws_ssm_document.this.document_version, "")
}

output "latest_version" {
  description = "Latest version of the document."
  value       = try(aws_ssm_document.this.latest_version, "")
}

output "default_version" {
  description = "Default version of the document."
  value       = try(aws_ssm_document.this.default_version, "")
}

output "hash" {
  description = "Sha1 or Sha256 hash of the document content."
  value       = try(aws_ssm_document.this.hash, "")
}

output "hash_type" {
  description = "Hash type used for the document hash (Sha1 or Sha256)."
  value       = try(aws_ssm_document.this.hash_type, "")
}

output "owner" {
  description = "AWS account that owns the document."
  value       = try(aws_ssm_document.this.owner, "")
}

output "status" {
  description = "Status of the document (Creating, Active, Updating, Deleting, Failed)."
  value       = try(aws_ssm_document.this.status, "")
}

output "tags_all" {
  description = "All tags applied to the document, including provider default_tags."
  value       = try(aws_ssm_document.this.tags_all, {})
}
