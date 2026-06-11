package main

import rego.v1

# Shared helpers for all policies. Policies evaluate OpenTofu plan JSON
# (`tofu show -json <planfile>`) passed to `conftest test --policy policy/`.
#
# CI additionally injects the planned module's repo-relative path as a
# top-level `module_path` key (see .github/scripts/conftest-plan.sh) so
# policies can carve out documented per-module exceptions.

# A change that creates or updates a resource. Deletes and no-ops are never
# violations - there is nothing new to police - and `change.after` is null
# for deletes, so every deny rule must go through this guard first.
is_create_or_update(resource) if {
	resource.mode == "managed"
	some action in resource.change.actions
	action in {"create", "update"}
}
