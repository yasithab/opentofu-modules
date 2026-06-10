package main

import rego.v1

# No security group ingress from the whole internet (0.0.0.0/0 or ::/0),
# except modules that intentionally expose ports to the world and document
# it (trivy:ignore in the module source, or ingress entirely caller-driven).
# The module path is injected into the plan JSON as `module_path` by
# .github/scripts/conftest-plan.sh; raw plans without it get the strict rules.
open_ingress_exceptions := {
	"security-group", # generic SG primitive - ingress is caller-controlled; fixture exercises a public HTTPS rule
	"vpc/vpc-endpoints", # fixture exercises caller-controlled ingress; rules are caller-supplied
	"headscale", # public VPN coordinator - HTTPS, ACME HTTP-01 and DERP STUN must be world-reachable (trivy:ignore documented)
}

module_excepted if {
	some exc in open_ingress_exceptions
	input.module_path == exc
}

module_excepted if {
	some exc in open_ingress_exceptions
	startswith(input.module_path, sprintf("%s/", [exc]))
}

world_cidrs := {"0.0.0.0/0", "::/0"}

world_cidr_in(cidrs) if {
	some cidr in cidrs
	cidr in world_cidrs
}

# aws_vpc_security_group_ingress_rule (one CIDR per rule)
deny contains msg if {
	not module_excepted
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_vpc_security_group_ingress_rule"
	resource.change.after.cidr_ipv4 in world_cidrs
	msg := sprintf("Security group ingress rule %q allows IPv4 ingress from the whole internet (%s)", [resource.address, resource.change.after.cidr_ipv4])
}

deny contains msg if {
	not module_excepted
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_vpc_security_group_ingress_rule"
	resource.change.after.cidr_ipv6 in world_cidrs
	msg := sprintf("Security group ingress rule %q allows IPv6 ingress from the whole internet (%s)", [resource.address, resource.change.after.cidr_ipv6])
}

# aws_security_group with inline ingress blocks
deny contains msg if {
	not module_excepted
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_security_group"
	some rule in resource.change.after.ingress
	world_cidr_in(rule.cidr_blocks)
	msg := sprintf("Security group %q has an inline ingress rule open to the whole internet (0.0.0.0/0)", [resource.address])
}

deny contains msg if {
	not module_excepted
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_security_group"
	some rule in resource.change.after.ingress
	world_cidr_in(rule.ipv6_cidr_blocks)
	msg := sprintf("Security group %q has an inline ingress rule open to the whole internet (::/0)", [resource.address])
}

# Legacy aws_security_group_rule resources
deny contains msg if {
	not module_excepted
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_security_group_rule"
	resource.change.after.type == "ingress"
	world_cidr_in(resource.change.after.cidr_blocks)
	msg := sprintf("Security group rule %q allows IPv4 ingress from the whole internet (0.0.0.0/0)", [resource.address])
}

deny contains msg if {
	not module_excepted
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	resource.type == "aws_security_group_rule"
	resource.change.after.type == "ingress"
	world_cidr_in(resource.change.after.ipv6_cidr_blocks)
	msg := sprintf("Security group rule %q allows IPv6 ingress from the whole internet (::/0)", [resource.address])
}
