#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/test_helper.bash"

test_start "CLI has valid Bash syntax"
assert_exit 0 bash -n "$CYBERPUNK_BIN"

test_start "CLI reports its version"
assert_exit 0 "$CYBERPUNK_BIN" --version
assert_contains "$COMMAND_OUTPUT" "Cyberpunk CLI"

test_start "CLI reports usage"
assert_exit 0 "$CYBERPUNK_BIN" --help
assert_contains "$COMMAND_OUTPUT" "USAGE"

echo "PASS: smoke tests"
