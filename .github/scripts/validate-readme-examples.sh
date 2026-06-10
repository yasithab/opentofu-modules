#!/usr/bin/env bash
# Extract every ```hcl code block from module README.md files into a scratch
# dir and run `tofu init -backend=false && tofu validate` on each usage
# example. Remote git sources pointing back at this repo are rewritten to
# local paths, so examples validate against the working tree (no network
# clone, and unreleased changes are covered).
#
# Usage: validate-readme-examples.sh [failures-file] [module-dir ...]
#   failures-file: markdown bullet list of failing examples is written here
#                  (default /tmp/failed-readme-examples.txt)
#   module-dir:    optional list of module dirs to limit the run to (handy for
#                  local debugging); defaults to every module README in the repo
#
# Exit code 0 when every example validates, 1 otherwise.
set -uo pipefail

FAILURES_FILE="${1:-/tmp/failed-readme-examples.txt}"
shift $(($# > 0 ? 1 : 0))
ROOT=$(pwd)
# Example dirs are created at <root>/.readme-examples/<slug>/example-<n>, i.e.
# three levels below the repo root, so rewritten local sources are ../../../<mod>.
WORK="$ROOT/.readme-examples"

rm -rf "$WORK"
mkdir -p "$WORK"
: >"$FAILURES_FILE"

TOTAL=0
FAILED=0

cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

list_readmes() {
	if [ "$#" -gt 0 ]; then
		for m in "$@"; do echo "./${m#./}/README.md"; done
	else
		find . -name README.md -not -path '*/.terraform/*' -not -path './.readme-examples/*' | sort
	fi
}

for readme in $(list_readmes "$@"); do
	[ -f "$readme" ] || continue
	dir=$(dirname "$readme")
	mod=${dir#./}
	[ "$mod" = "." ] && continue      # repo root README
	[ -f "$dir/main.tf" ] || continue # only module READMEs
	slug=${mod//\//__}

	# Split the README into one main.tf per ```hcl fenced block.
	awk -v outdir="$WORK/$slug" '
		/^```hcl[[:space:]]*$/ {
			n++
			d = outdir "/example-" n
			system("mkdir -p \"" d "\"")
			f = d "/main.tf"
			inblock = 1
			next
		}
		inblock && /^```/ { inblock = 0; close(f); next }
		inblock { print > f }
	' "$readme"

	for example in "$WORK/$slug"/example-*; do
		[ -d "$example" ] || continue
		n=$(basename "$example" | sed 's/example-//')

		# Only module-call usage examples are expected to validate standalone;
		# fragments (variable/output/snippet blocks) are skipped.
		if ! grep -q '^module ' "$example/main.tf"; then
			rm -rf "$example"
			continue
		fi

		# Rewrite remote sources that reference this repo to local paths.
		sed -i.bak -E 's|git::https://github\.com/yasithab/opentofu-modules\.git//([^?"]+)(\?[^"]*)?|../../../\1|g' "$example/main.tf"
		rm -f "$example/main.tf.bak"

		TOTAL=$((TOTAL + 1))
		log="$example/validate.log"
		if (cd "$example" && tofu init -backend=false -input=false -no-color && tofu validate -no-color) >"$log" 2>&1; then
			echo "ok: $mod example $n"
		else
			FAILED=$((FAILED + 1))
			reason=$(grep -m1 -E '^.{0,4}Error:' "$log" | sed 's/[`|│]//g; s/^[[:space:]]*//' || true)
			echo "FAIL: $mod example $n${reason:+ - $reason}"
			echo "- \`$mod\` example $n${reason:+: $reason}" >>"$FAILURES_FILE"
			sed 's/^/    /' "$log" | tail -n 30
		fi
	done
done

echo ""
echo "README examples: $((TOTAL - FAILED))/$TOTAL validated"
[ "$FAILED" -eq 0 ]
