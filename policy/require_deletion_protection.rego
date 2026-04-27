package main

import rego.v1

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_db_instance"
	change := resource.change.after
	change.deletion_protection == false
	msg := sprintf("RDS instance %q must have deletion protection enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_rds_cluster"
	change := resource.change.after
	change.deletion_protection == false
	msg := sprintf("RDS cluster %q must have deletion protection enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_neptune_cluster"
	change := resource.change.after
	change.deletion_protection == false
	msg := sprintf("Neptune cluster %q must have deletion protection enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_docdb_cluster"
	change := resource.change.after
	change.deletion_protection == false
	msg := sprintf("DocumentDB cluster %q must have deletion protection enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_dynamodb_table"
	change := resource.change.after
	change.deletion_protection_enabled == false
	msg := sprintf("DynamoDB table %q must have deletion protection enabled", [resource.address])
}
