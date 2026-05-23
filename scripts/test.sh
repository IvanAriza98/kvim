#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

MINIMAL_INIT="$REPO_ROOT/tests/minimal_init.lua"
TEST_DIR="$REPO_ROOT/tests"
OUTPUT_FILE="$(mktemp)"
CLEAN_OUTPUT_FILE="$(mktemp)"

cleanup() {
  rm -f "$OUTPUT_FILE" "$CLEAN_OUTPUT_FILE"
}

summarize_results() {
  local file="$1"

  SUCCESS_COUNT="$(awk '/^[[:space:]]*Success:/ { total += $2 } END { print total + 0 }' "$file")"
  FAILED_COUNT="$(awk '/^[[:space:]]*Failed[[:space:]]*:/ { total += $3 } END { print total + 0 }' "$file")"
  ERROR_COUNT="$(awk '/^[[:space:]]*Errors[[:space:]]*:/ { total += $3 } END { print total + 0 }' "$file")"
  TOTAL_COUNT=$((SUCCESS_COUNT + FAILED_COUNT + ERROR_COUNT))

  echo
  echo "========================================"
  echo "KVIM Test Summary"
  echo "========================================"
  echo "Success: $SUCCESS_COUNT"
  echo "Failed : $FAILED_COUNT"
  echo "Errors : $ERROR_COUNT"
  echo "Total  : $TOTAL_COUNT"
  echo "========================================"
}

trap cleanup EXIT

if [ ! -f "$MINIMAL_INIT" ]; then
  echo "Error: minimal_init.lua not found at $MINIMAL_INIT" >&2
  exit 1
fi

if [ ! -d "$TEST_DIR" ]; then
  echo "Error: test directory not found at $TEST_DIR" >&2
  exit 1
fi

echo "Running KVIM tests..."
echo

set +e

nvim --headless \
  -u "$MINIMAL_INIT" \
  -c "PlenaryBustedDirectory $TEST_DIR" \
  -c "qa!" 2>&1 | tee "$OUTPUT_FILE"

NVIM_EXIT_CODE=${PIPESTATUS[0]}

set -e

# Remove ANSI color escape codes before parsing.
perl -pe 's/\e\[[0-9;]*[mK]//g' "$OUTPUT_FILE" > "$CLEAN_OUTPUT_FILE"

summarize_results "$CLEAN_OUTPUT_FILE"

if [ "$NVIM_EXIT_CODE" -ne 0 ] || [ "$FAILED_COUNT" -ne 0 ] || [ "$ERROR_COUNT" -ne 0 ]; then
  echo "Tests failed."
  exit 1
fi

echo "Tests finished successfully."
