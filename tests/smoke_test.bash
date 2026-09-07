#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/test_helper.bash"

test_start "CLI has valid Bash syntax"
assert_exit 0 bash -n "$CYBERPUNK_BIN"
assert_exit 0 bash -n "$REPO_ROOT/lib/config.bash"

test_start "CLI reports its version"
assert_exit 0 "$CYBERPUNK_BIN" --version
assert_contains "$COMMAND_OUTPUT" "Cyberpunk CLI"
assert_contains "$COMMAND_OUTPUT" "0.4.0"

test_start "live runtime smoke checks remain optional documentation"
assert_file "$REPO_ROOT/docs/live-runtime-smoke.md"
assert_not_contains "$(<"$REPO_ROOT/tests/run.sh")" "live-runtime-smoke" "automated suite must not invoke live runtime smoke checks"

test_start "CLI reports usage"
assert_exit 0 "$CYBERPUNK_BIN" --help
assert_contains "$COMMAND_OUTPUT" "USAGE"

echo "PASS: smoke tests"
