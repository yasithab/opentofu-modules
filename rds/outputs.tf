################################################################################
# DB Subnet Group
################################################################################

output "db_subnet_group_name" {
  description = "The db subnet group name"
  value       = local.db_subnet_group_name
}

################################################################################
# DB Instance
################################################################################

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = try(aws_db_instance.this.arn, null)
}

output "db_instance_id" {
  description = "The RDS instance identifier"
  value       = try(aws_db_instance.this.identifier, null)
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = try(aws_db_instance.this.resource_id, null)
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = try(aws_db_instance.this.address, null)
}

output "db_instance_endpoint" {
  description = "The connection endpoint in address:port format"
  value       = try(aws_db_instance.this.endpoint, null)
}

output "db_instance_engine_version_actual" {
  description = "The running version of the database"
  value       = try(aws_db_instance.this.engine_version_actual, null)
}

output "db_instance_name" {
  description = "The database name"
  value       = try(aws_db_instance.this.db_name, null)
}

output "db_instance_port" {
  description = "The database port"
  value       = try(aws_db_instance.this.port, null)
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = try(aws_db_instance.this.username, null)
  sensitive   = true
}

output "db_instance_master_user_secret" {
  description = "The master user secret when manage_master_user_password is set to true"
  value       = try(aws_db_instance.this.master_user_secret, null)
  sensitive   = true
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = try(aws_db_instance.this.hosted_zone_id, null)
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = try(aws_db_instance.this.status, null)
}

output "db_instance_availability_zone" {
  description = "The availability zone of the instance"
  value       = try(aws_db_instance.this.availability_zone, null)
}

output "db_instance_multi_az" {
  description = "Whether the RDS instance is multi-AZ"
  value       = try(aws_db_instance.this.multi_az, null)
}

output "db_instance_ca_cert_identifier" {
  description = "Specifies the identifier of the CA certificate for the DB instance"
  value       = try(aws_db_instance.this.ca_cert_identifier, null)
}

output "db_instance_latest_restorable_time" {
  description = "The latest point in time to which the database can be restored with point-in-time restore"
  value       = try(aws_db_instance.this.latest_restorable_time, null)
}

################################################################################
# Read Replica(s)
################################################################################

output "read_replicas" {
  description = "A map of read replicas and their attributes"
  value       = aws_db_instance.read_replica
  sensitive   = true
}

################################################################################
# Enhanced Monitoring
################################################################################

output "enhanced_monitoring_iam_role_name" {
  description = "The name of the enhanced monitoring role"
  value       = try(aws_iam_role.rds_enhanced_monitoring.name, null)
}

output "enhanced_monitoring_iam_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the enhanced monitoring role"
  value       = try(aws_iam_role.rds_enhanced_monitoring.arn, null)
}

output "enhanced_monitoring_iam_role_unique_id" {
  description = "Stable and unique string identifying the enhanced monitoring role"
  value       = try(aws_iam_role.rds_enhanced_monitoring.unique_id, null)
}

################################################################################
# Security Group
################################################################################

output "security_group_id" {
  description = "The security group ID of the RDS instance"
  value       = try(aws_security_group.this.id, null)
}

################################################################################
# DB Option Group
################################################################################

output "db_option_group_arn" {
  description = "The ARN of the DB option group created"
  value       = try(aws_db_option_group.this.arn, null)
}

output "db_option_group_id" {
  description = "The ID of the DB option group created"
  value       = try(aws_db_option_group.this.id, null)
}

################################################################################
# DB Parameter Group
################################################################################

output "db_parameter_group_arn" {
  description = "The ARN of the DB parameter group created"
  value       = try(aws_db_parameter_group.this.arn, null)
}

output "db_parameter_group_id" {
  description = "The ID of the DB parameter group created"
  value       = try(aws_db_parameter_group.this.id, null)
}

################################################################################
# CloudWatch Log Group
################################################################################

output "db_instance_cloudwatch_log_groups" {
  description = "Map of CloudWatch log groups created and their attributes"
  value       = aws_cloudwatch_log_group.this
}

################################################################################
# Managed Secret Rotation
################################################################################

output "db_instance_secretsmanager_secret_rotation_enabled" {
  description = "Specifies whether automatic rotation is enabled for the secret"
  value       = try(aws_secretsmanager_secret_rotation.this.rotation_enabled, null)
}
