################################################################################
# S3 Object
################################################################################

output "object_id" {
  description = "Key of the S3 object"
  value       = try(aws_s3_object.this.id, "")
}

output "object_arn" {
  description = "ARN of the S3 object"
  value       = try(aws_s3_object.this.arn, "")
}

output "object_etag" {
  description = "ETag of the S3 object"
  value       = try(aws_s3_object.this.etag, "")
}

output "object_version_id" {
  description = "Version ID of the S3 object (if versioning is enabled on the bucket)"
  value       = try(aws_s3_object.this.version_id, "")
}

output "object_bucket" {
  description = "Name of the bucket containing the object"
  value       = try(aws_s3_object.this.bucket, "")
}

output "object_key" {
  description = "Key (path) of the object in the bucket"
  value       = try(aws_s3_object.this.key, "")
}

output "object_storage_class" {
  description = "Storage class of the object"
  value       = try(aws_s3_object.this.storage_class, "")
}

output "object_content_type" {
  description = "Content type of the object"
  value       = try(aws_s3_object.this.content_type, "")
}

output "object_server_side_encryption" {
  description = "Server-side encryption algorithm used"
  value       = try(aws_s3_object.this.server_side_encryption, "")
}

output "object_kms_key_id" {
  description = "ARN of the KMS key used for encryption"
  value       = try(aws_s3_object.this.kms_key_id, "")
}

################################################################################
# S3 Object Copy
################################################################################

output "object_copy_id" {
  description = "Key of the copied S3 object"
  value       = try(aws_s3_object_copy.this.id, "")
}

output "object_copy_etag" {
  description = "ETag of the copied S3 object"
  value       = try(aws_s3_object_copy.this.etag, "")
}

output "object_copy_version_id" {
  description = "Version ID of the copied S3 object"
  value       = try(aws_s3_object_copy.this.version_id, "")
}

output "object_copy_last_modified" {
  description = "Last modified date of the copied object"
  value       = try(aws_s3_object_copy.this.last_modified, "")
}

output "object_copy_source_version_id" {
  description = "Version ID of the source object that was copied"
  value       = try(aws_s3_object_copy.this.source_version_id, "")
}

################################################################################
# Bucket Notification
################################################################################

output "bucket_notification_id" {
  description = "ID of the bucket notification configuration (bucket name)"
  value       = try(aws_s3_bucket_notification.this.id, "")
}
