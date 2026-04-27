package main

import rego.v1

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket_public_access_block"
	change := resource.change.after
	not change.block_public_acls
	msg := sprintf("S3 bucket %q must have block_public_acls enabled", [resource.address])
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket_public_access_block"
	change := resource.change.after
	not change.block_public_policy
	msg := sprintf("S3 bucket %q must have block_public_policy enabled", [resource.address])
}
