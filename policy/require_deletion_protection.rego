package main

import rego.v1

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_db_instance"
	resource.change.after.deletion_protection == false
	msg := sprintf("RDS instance %q must have deletion protection enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_rds_cluster"
	resource.change.after.deletion_protection == false
	msg := sprintf("RDS cluster %q must have deletion protection enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_neptune_cluster"
	resource.change.after.deletion_protection == false
	msg := sprintf("Neptune cluster %q must have deletion protection enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_docdb_cluster"
	resource.change.after.deletion_protection == false
	msg := sprintf("DocumentDB cluster %q must have deletion protection enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_dynamodb_table"
	resource.change.after.deletion_protection_enabled == false
	msg := sprintf("DynamoDB table %q must have deletion protection enabled", [resource.address])
}
