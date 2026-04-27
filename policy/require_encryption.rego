package main

import rego.v1

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_db_instance"
	change := resource.change.after
	change.storage_encrypted == false
	msg := sprintf("RDS instance %q must have storage encryption enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_rds_cluster"
	change := resource.change.after
	change.storage_encrypted == false
	msg := sprintf("RDS cluster %q must have storage encryption enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_redshift_cluster"
	change := resource.change.after
	change.encrypted == false
	msg := sprintf("Redshift cluster %q must have encryption enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_elasticache_replication_group"
	change := resource.change.after
	change.at_rest_encryption_enabled == false
	msg := sprintf("ElastiCache replication group %q must have at-rest encryption enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_neptune_cluster"
	change := resource.change.after
	change.storage_encrypted == false
	msg := sprintf("Neptune cluster %q must have storage encryption enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_docdb_cluster"
	change := resource.change.after
	change.storage_encrypted == false
	msg := sprintf("DocumentDB cluster %q must have storage encryption enabled", [resource.address])
}
