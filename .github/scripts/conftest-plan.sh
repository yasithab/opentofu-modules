#!/usr/bin/env bash
# Plan each module with its CI fixture and evaluate the plan JSON against the
# OPA policies in policy/ via conftest.
#
# Usage: conftest-plan.sh <comma-separated module dirs>
#
# For every module fixture (test/test.tfvars plus any standalone
# test/fixtures/plan-*.tfvars variants):
#   tofu init -backend=false && tofu plan -out=... && tofu show -json
# The plan JSON is annotated with the module's repo-relative path as
# `module_path` (so policies can apply documented per-module exceptions) and
# piped through `conftest test --policy policy/`.
# Modules without any plan fixture are skipped - there is nothing to plan.
set -uo pipefail

MODULES="${1:-}"
ROOT=$(pwd)
FAILED=0
TESTED=0
SKIPPED=0

if [ -z "$MODULES" ]; then
	echo "No modules to check"
	exit 0
fi

check_fixture() {
	local mod="$1" tfvars="$2"
	local workdir
	workdir=$(mktemp -d)
	echo "::group::conftest: $mod ($tfvars)"
	if (
		cd "$ROOT/$mod" &&
			tofu init -backend=false -input=false -no-color >"$workdir/init.log" 2>&1 &&
			tofu plan -input=false -lock=false -no-color -var-file="$tfvars" -out="$workdir/plan.bin" >"$workdir/plan.log" 2>&1 &&
			tofu show -json "$workdir/plan.bin" >"$workdir/plan.json" 2>"$workdir/show.log" &&
			jq --arg module_path "$mod" '. + {module_path: $module_path}' \
				"$workdir/plan.json" >"$workdir/plan-annotated.json"
	); then
		if conftest test --policy "$ROOT/policy" "$workdir/plan-annotated.json"; then
			TESTED=$((TESTED + 1))
		else
			echo "Policy violations in $mod ($tfvars)"
			FAILED=1
		fi
	else
		echo "Failed to produce a plan JSON for $mod ($tfvars):"
		tail -n 40 "$workdir/init.log" "$workdir/plan.log" "$workdir/show.log" 2>/dev/null
		FAILED=1
	fi
	rm -rf "$workdir"
	echo "::endgroup::"
}

for mod in ${MODULES//,/ }; do
	fixtures=()
	[ -f "$ROOT/$mod/test/test.tfvars" ] && fixtures+=("test/test.tfvars")
	for f in "$ROOT/$mod"/test/fixtures/plan-*.tfvars; do
		[ -f "$f" ] && fixtures+=("test/fixtures/$(basename "$f")")
	done

	if [ "${#fixtures[@]}" -eq 0 ]; then
		echo "skip: $mod (no plan fixture)"
		SKIPPED=$((SKIPPED + 1))
		continue
	fi

	for tfvars in "${fixtures[@]}"; do
		check_fixture "$mod" "$tfvars"
	done
done

echo ""
echo "Conftest summary: $TESTED module(s) checked, $SKIPPED skipped (no fixture), exit=$FAILED"
exit "$FAILED"
