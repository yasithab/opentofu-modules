#!/usr/bin/env bash
# Detect modules affected by a change set and print them comma-separated.
#
# Usage: detect-changed-modules.sh <base_sha> [head_sha]
#
# Two directions are covered:
#   UP:   a change inside a submodule re-tests every ancestor directory that
#         contains a main.tf - a parent module embedding a changed submodule
#         must be re-planned too, not just the nearest module.
#   DOWN: a change in a module re-tests every consumer that references it via
#         a local `source = "../..."` module call (wrappers and submodule
#         consumers). The consumer map is built at runtime by grepping module
#         sources across the repo, so new wrappers are picked up automatically.
#
# Kept bash-3.2 compatible (no associative arrays) so it dry-runs on macOS.
set -euo pipefail

BASE_SHA="$1"
HEAD_SHA="${2:-HEAD}"

cd "$(git rev-parse --show-toplevel)"

SELECTED_FILE=$(mktemp)
trap 'rm -f "$SELECTED_FILE"' EXIT

normpath() {
	python3 -c 'import os, sys; print(os.path.normpath(sys.argv[1]))' "$1"
}

# ── UP: changed dirs and all their module ancestors ──────────────────────────
# Wrappers are not seeded directly (the test harness skips them in discovery);
# they are only added when pulled in as consumers of a changed module below.
git diff --name-only "$BASE_SHA" "$HEAD_SHA" -- '*.tf' |
	xargs -r -n1 dirname | sort -u |
	while IFS= read -r dir; do
		d="$dir"
		while [ "$d" != "." ] && [ "$d" != "/" ]; do
			if [ -f "$d/main.tf" ] && [[ "$d" != *wrappers* ]]; then
				echo "$d"
			fi
			d=$(dirname "$d")
		done
	done | sort -u >"$SELECTED_FILE"

# ── DOWN: build "consumer target" edges from local module sources ────────────
EDGES=$(grep -rEo --include='*.tf' --exclude-dir='.terraform' \
	'source[[:space:]]*=[[:space:]]*"\.\.?/[^"]*"' . 2>/dev/null |
	while IFS=: read -r file match; do
		src=$(sed -E 's/.*"([^"]*)".*/\1/' <<<"$match")
		consumer=$(dirname "${file#./}")
		target=$(normpath "$consumer/$src")
		# Only keep edges between real module dirs inside the repo.
		[ -f "$consumer/main.tf" ] || continue
		[ -f "$target/main.tf" ] || continue
		[[ "$target" == ../* || "$target" == ".." ]] && continue
		echo "$consumer $target"
	done | sort -u)

# Propagate to consumers until a fixed point is reached (a wrapper of a
# wrapper would otherwise be missed).
if [ -n "$EDGES" ]; then
	while :; do
		NEW=$(while read -r consumer target; do
			if grep -qxF "$target" "$SELECTED_FILE" && ! grep -qxF "$consumer" "$SELECTED_FILE"; then
				echo "$consumer"
			fi
		done <<<"$EDGES" | sort -u)
		[ -z "$NEW" ] && break
		printf '%s\n' "$NEW" >>"$SELECTED_FILE"
		sort -u "$SELECTED_FILE" -o "$SELECTED_FILE"
	done
fi

if [ -s "$SELECTED_FILE" ]; then
	paste -sd ',' "$SELECTED_FILE"
fi
