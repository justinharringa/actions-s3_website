#!/usr/bin/env bash
# test.sh – Build the Docker image and run basic container tests.
# Usage: ./test.sh
# Requirements: Docker must be running.

set -euo pipefail

IMAGE_NAME="actions-s3_website-test"
PASS=0
FAIL=0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*"; FAIL=$((FAIL + 1)); }

assert_contains() {
  local label="$1" expected="$2" actual="$3"
  if echo "$actual" | grep -qF -- "$expected"; then
    pass "$label"
  else
    fail "$label – expected output to contain: '$expected'"
    echo "    actual output: $actual"
  fi
}

assert_exit_zero() {
  local label="$1" exit_code="$2"
  if [ "$exit_code" -eq 0 ]; then
    pass "$label (exit 0)"
  else
    fail "$label – expected exit 0, got $exit_code"
  fi
}

assert_exit_nonzero() {
  local label="$1" exit_code="$2"
  if [ "$exit_code" -ne 0 ]; then
    pass "$label (exit $exit_code)"
  else
    fail "$label – expected non-zero exit, got 0"
  fi
}

cleanup() {
  echo ""
  echo "Removing test image …"
  docker image rm -f "$IMAGE_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# 1. Build
# ---------------------------------------------------------------------------
echo "==> Building Docker image ($IMAGE_NAME) …"
docker build -t "$IMAGE_NAME" . >/dev/null
echo "    Image built successfully."

# ---------------------------------------------------------------------------
# 2. Tests
# ---------------------------------------------------------------------------
echo ""
echo "==> Running tests …"

# Test 1 – default CMD produces help output
echo "  [1] Default CMD (no arguments) shows available commands"
output=$(docker run --rm "$IMAGE_NAME" 2>&1)
status=$?
assert_exit_zero "default CMD exits 0" "$status"
assert_contains "default CMD shows 's3_website push'" "s3_website push" "$output"

# Test 2 – explicit 'help' argument
echo "  [2] Explicit 'help' argument"
output=$(docker run --rm "$IMAGE_NAME" help 2>&1)
status=$?
assert_exit_zero "'help' exits 0" "$status"
assert_contains "'help' shows 's3_website push'" "s3_website push" "$output"

# Test 3 – 'help push' shows Usage and --dry-run option
echo "  [3] 'help push' shows detailed push usage"
output=$(docker run --rm "$IMAGE_NAME" help push 2>&1)
status=$?
assert_exit_zero "'help push' exits 0" "$status"
assert_contains "'help push' shows 'Usage'" "Usage" "$output"
assert_contains "'help push' shows '--dry-run'" "--dry-run" "$output"

# Test 4 – unknown sub-command exits non-zero
echo "  [4] Unknown sub-command exits non-zero"
exit_code=0
docker run --rm "$IMAGE_NAME" unknown_command_xyz >/dev/null 2>&1 || exit_code=$?
assert_exit_nonzero "unknown sub-command exits non-zero" "${exit_code:-0}"

# Test 5 – working directory inside the container is /site
echo "  [5] Working directory inside container is /site"
output=$(docker run --rm --entrypoint pwd "$IMAGE_NAME" 2>&1)
assert_contains "WORKDIR is /site" "/site" "$output"

# Test 6 – s3_website binary is on PATH inside the container
echo "  [6] s3_website binary is on PATH"
output=$(docker run --rm --entrypoint which "$IMAGE_NAME" s3_website 2>&1)
status=$?
assert_exit_zero "'which s3_website' exits 0" "$status"
assert_contains "s3_website is on PATH" "s3_website" "$output"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "==> Results: $PASS passed, $FAIL failed"
echo ""
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
