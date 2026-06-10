package main

import rego.v1

# Every taggable resource must carry the repo-standard tags. Modules merge
# `{ ManagedBy = "opentofu", Region = data.aws_region.current.region }` into
# `local.tags`, so a missing key means a resource skipped `tags = local.tags`.
required_tags := {"ManagedBy", "Region"}

# A resource is taggable when the provider exposes `tags_all` in the planned
# values (known or unknown-until-apply). Non-taggable resources are skipped.
taggable(resource) if {
	is_object(resource.change.after)
	"tags_all" in object.keys(resource.change.after)
}

taggable(resource) if {
	is_object(resource.change.after_unknown)
	"tags_all" in object.keys(resource.change.after_unknown)
}

has_tag(resource, tag) if {
	resource.change.after.tags_all[tag]
}

has_tag(resource, tag) if {
	resource.change.after.tags[tag]
}

# Tag maps (or individual values) that are not known until apply still count
# as present - e.g. Region resolved from a data source mid-apply.
has_tag(resource, tag) if {
	resource.change.after_unknown.tags_all == true
}

has_tag(resource, tag) if {
	resource.change.after_unknown.tags_all[tag]
}

has_tag(resource, tag) if {
	resource.change.after_unknown.tags == true
}

has_tag(resource, tag) if {
	resource.change.after_unknown.tags[tag]
}

deny contains msg if {
	resource := input.resource_changes[_]
	is_create_or_update(resource)
	taggable(resource)
	some tag in required_tags
	not has_tag(resource, tag)
	msg := sprintf("%s %q is missing required tag %q (taggable resources must carry ManagedBy and Region)", [resource.type, resource.address, tag])
}
