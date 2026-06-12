#!/bin/bash
# Generate GitHub Step Summary from Terratest output
# Usage: terratest-summary.sh <output-file>
# The file contains the output of a single `go test` run covering the
# plan and plan-fixture suites.

set -euo pipefail

summary() {
  local file="$1"
  local test_name="$2"
  local label="$3"

  if [ ! -f "$file" ]; then
    echo "### $label: ⏭️ Not run"
    echo ""
    return
  fi

  local passed failed total
  passed=$(grep -c "PASS: ${test_name}/" "$file" 2>/dev/null) || passed=0
  failed=$(grep -c "FAIL: ${test_name}/" "$file" 2>/dev/null) || failed=0
  total=$((passed + failed))

  if [ "$total" -eq 0 ]; then
    echo "### $label: ⏭️ Skipped"
  elif [ "$failed" -eq 0 ]; then
    echo "### $label: ✅ $passed/$total passed"
  else
    echo "### $label: ❌ $failed/$total failed"
  fi
  echo ""

  if [ "$total" -gt 0 ]; then
    echo "| Module | Status | Duration |"
    echo "|--------|--------|----------|"
    grep "PASS: ${test_name}/\|FAIL: ${test_name}/" "$file" 2>/dev/null | while IFS= read -r line; do
      mod=$(echo "$line" | sed "s/.*${test_name}\///" | sed 's/ (.*//')
      duration=$(echo "$line" | grep -oE '\([0-9.]+s\)' || echo "")
      if echo "$line" | grep -q "PASS:"; then
        echo "| \`$mod\` | ✅ | $duration |"
      else
        echo "| \`$mod\` | ❌ | $duration |"
      fi
    done
    echo ""

    if [ "$failed" -gt 0 ]; then
      echo "<details><summary>❌ Failure details</summary>"
      echo ""
      echo '```'
      grep "FAIL: ${test_name}/" "$file" 2>/dev/null | sed "s/.*FAIL: ${test_name}\///" | sed 's/ (.*//' | while read -r mod; do
        echo "--- $mod ---"
        grep "${test_name}/$mod " "$file" 2>/dev/null | grep 'Error:' | grep -v 'Trace\|Should\|exit' | sed 's/.*Error: /  /' | head -3
      done
      echo '```'
      echo "</details>"
      echo ""
    fi
  fi
}

echo "## Terratest Results"
echo ""

summary "$1" "TestPlanAllModules" "Plan"
summary "$1" "TestPlanFixtures" "Plan Fixtures"
