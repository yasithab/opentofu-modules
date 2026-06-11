package main

import rego.v1

# Run with: conftest verify --policy policy/

# ── helpers ──────────────────────────────────────────────────────────────────

plan_with(resources) := {"format_version": "1.2", "resource_changes": resources}

sg_rule(cidr) := {
	"address": "aws_vpc_security_group_ingress_rule.test",
	"mode": "managed",
	"type": "aws_vpc_security_group_ingress_rule",
	"change": {
		"actions": ["create"],
		"after": {"cidr_ipv4": cidr, "tags": {"ManagedBy": "opentofu", "Region": "us-east-1"}, "tags_all": {"ManagedBy": "opentofu", "Region": "us-east-1"}},
		"after_unknown": {},
	},
}

# ── required tags ────────────────────────────────────────────────────────────

test_tagged_resource_passes if {
	count(deny) == 0 with input as plan_with([{
		"address": "aws_sns_topic.this",
		"mode": "managed",
		"type": "aws_sns_topic",
		"change": {
			"actions": ["create"],
			"after": {"tags": {"ManagedBy": "opentofu", "Region": "us-east-1"}, "tags_all": {"ManagedBy": "opentofu", "Region": "us-east-1"}},
			"after_unknown": {},
		},
	}])
}

test_missing_region_tag_denied if {
	some msg in deny with input as plan_with([{
		"address": "aws_sns_topic.this",
		"mode": "managed",
		"type": "aws_sns_topic",
		"change": {
			"actions": ["create"],
			"after": {"tags": {"ManagedBy": "opentofu"}, "tags_all": {"ManagedBy": "opentofu"}},
			"after_unknown": {},
		},
	}])
	contains(msg, "Region")
}

test_unknown_tags_pass if {
	count(deny) == 0 with input as plan_with([{
		"address": "aws_sns_topic.this",
		"mode": "managed",
		"type": "aws_sns_topic",
		"change": {
			"actions": ["create"],
			"after": {"tags": {"ManagedBy": "opentofu"}},
			"after_unknown": {"tags_all": true},
		},
	}])
}

test_untaggable_resource_skipped if {
	count(deny) == 0 with input as plan_with([{
		"address": "aws_iam_role_policy_attachment.this",
		"mode": "managed",
		"type": "aws_iam_role_policy_attachment",
		"change": {"actions": ["create"], "after": {"role": "x"}, "after_unknown": {}},
	}])
}

test_delete_is_ignored if {
	count(deny) == 0 with input as plan_with([{
		"address": "aws_sns_topic.this",
		"mode": "managed",
		"type": "aws_sns_topic",
		"change": {"actions": ["delete"], "after": null, "after_unknown": {}},
	}])
}

# ── open ingress ─────────────────────────────────────────────────────────────

test_world_ingress_denied if {
	some msg in deny with input as plan_with([sg_rule("0.0.0.0/0")])
	contains(msg, "whole internet")
}

test_scoped_ingress_passes if {
	count(deny) == 0 with input as plan_with([sg_rule("10.0.0.0/16")])
}

test_world_ingress_excepted_module_passes if {
	plan := object.union(plan_with([sg_rule("0.0.0.0/0")]), {"module_path": "headscale"})
	count(deny) == 0 with input as plan
}

test_world_ingress_exception_is_not_a_prefix_match if {
	plan := object.union(plan_with([sg_rule("0.0.0.0/0")]), {"module_path": "headscale-clone"})
	count(deny) > 0 with input as plan
}

test_inline_sg_world_ingress_denied if {
	some msg in deny with input as plan_with([{
		"address": "aws_security_group.this",
		"mode": "managed",
		"type": "aws_security_group",
		"change": {
			"actions": ["create"],
			"after": {
				"ingress": [{"from_port": 443, "to_port": 443, "cidr_blocks": ["0.0.0.0/0"], "ipv6_cidr_blocks": []}],
				"tags": {"ManagedBy": "opentofu", "Region": "us-east-1"},
				"tags_all": {"ManagedBy": "opentofu", "Region": "us-east-1"},
			},
			"after_unknown": {},
		},
	}])
	contains(msg, "inline ingress")
}

# ── encryption at rest ───────────────────────────────────────────────────────

test_unencrypted_efs_denied if {
	some msg in deny with input as plan_with([{
		"address": "aws_efs_file_system.this",
		"mode": "managed",
		"type": "aws_efs_file_system",
		"change": {
			"actions": ["create"],
			"after": {"encrypted": false, "tags": {"ManagedBy": "opentofu", "Region": "us-east-1"}, "tags_all": {"ManagedBy": "opentofu", "Region": "us-east-1"}},
			"after_unknown": {},
		},
	}])
	contains(msg, "encryption")
}

test_encrypted_rds_passes if {
	count(deny) == 0 with input as plan_with([{
		"address": "aws_db_instance.this",
		"mode": "managed",
		"type": "aws_db_instance",
		"change": {
			"actions": ["create"],
			"after": {"storage_encrypted": true, "deletion_protection": true, "tags": {"ManagedBy": "opentofu", "Region": "us-east-1"}, "tags_all": {"ManagedBy": "opentofu", "Region": "us-east-1"}},
			"after_unknown": {},
		},
	}])
}

# ── deletion protection / s3 regression guards ───────────────────────────────

test_unprotected_dynamodb_denied if {
	some msg in deny with input as plan_with([{
		"address": "aws_dynamodb_table.this",
		"mode": "managed",
		"type": "aws_dynamodb_table",
		"change": {
			"actions": ["create"],
			"after": {"deletion_protection_enabled": false, "tags": {"ManagedBy": "opentofu", "Region": "us-east-1"}, "tags_all": {"ManagedBy": "opentofu", "Region": "us-east-1"}},
			"after_unknown": {},
		},
	}])
	contains(msg, "deletion protection")
}

test_public_access_block_delete_not_denied if {
	# Regression: deletes have after == null and must never trip the S3 rules.
	count(deny) == 0 with input as plan_with([{
		"address": "aws_s3_bucket_public_access_block.this",
		"mode": "managed",
		"type": "aws_s3_bucket_public_access_block",
		"change": {"actions": ["delete"], "after": null, "after_unknown": {}},
	}])
}

test_public_access_block_disabled_denied if {
	some msg in deny with input as plan_with([{
		"address": "aws_s3_bucket_public_access_block.this",
		"mode": "managed",
		"type": "aws_s3_bucket_public_access_block",
		"change": {
			"actions": ["update"],
			"after": {"block_public_acls": false, "block_public_policy": true},
			"after_unknown": {},
		},
	}])
	contains(msg, "block_public_acls")
}
