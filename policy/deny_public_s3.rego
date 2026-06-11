package main

import rego.v1

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_s3_bucket_public_access_block"
	resource.change.after.block_public_acls == false
	msg := sprintf("S3 bucket %q must have block_public_acls enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_s3_bucket_public_access_block"
	resource.change.after.block_public_policy == false
	msg := sprintf("S3 bucket %q must have block_public_policy enabled", [resource.address])
}
