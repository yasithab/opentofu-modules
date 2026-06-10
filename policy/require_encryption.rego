package main

import rego.v1

# Encryption-at-rest must stay enabled wherever the resource exposes a flag
# in the plan JSON. Rules only fire on an explicit `false` (or "NONE"), so
# values that are unknown until apply never produce false positives.

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_db_instance"
	resource.change.after.storage_encrypted == false
	msg := sprintf("RDS instance %q must have storage encryption enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_rds_cluster"
	resource.change.after.storage_encrypted == false
	msg := sprintf("RDS cluster %q must have storage encryption enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_redshift_cluster"
	resource.change.after.encrypted == false
	msg := sprintf("Redshift cluster %q must have encryption enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_elasticache_replication_group"
	resource.change.after.at_rest_encryption_enabled == false
	msg := sprintf("ElastiCache replication group %q must have at-rest encryption enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_neptune_cluster"
	resource.change.after.storage_encrypted == false
	msg := sprintf("Neptune cluster %q must have storage encryption enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_docdb_cluster"
	resource.change.after.storage_encrypted == false
	msg := sprintf("DocumentDB cluster %q must have storage encryption enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_efs_file_system"
	resource.change.after.encrypted == false
	msg := sprintf("EFS file system %q must have encryption enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_ebs_volume"
	resource.change.after.encrypted == false
	msg := sprintf("EBS volume %q must have encryption enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_opensearch_domain"
	some encrypt_at_rest in resource.change.after.encrypt_at_rest
	encrypt_at_rest.enabled == false
	msg := sprintf("OpenSearch domain %q must have encryption at rest enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_kinesis_stream"
	resource.change.after.encryption_type == "NONE"
	msg := sprintf("Kinesis stream %q must have server-side encryption enabled", [resource.address])
}
