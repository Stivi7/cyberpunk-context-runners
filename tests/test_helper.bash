#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
CYBERPUNK_BIN="$REPO_ROOT/cyberpunk"

COMMAND_OUTPUT=""
COMMAND_STATUS=0

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

test_start() {
    echo "TEST: $1"
}

capture() {
    set +e
    COMMAND_OUTPUT="$("$@" 2>&1)"
    COMMAND_STATUS=$?
    set -e
}

assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="${3:-expected values to match}"

    if [[ "$expected" != "$actual" ]]; then
        fail "$message (expected '$expected', got '$actual')"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-expected output to contain value}"

    if [[ "$haystack" != *"$needle"* ]]; then
        fail "$message (missing '$needle')"
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-expected output not to contain value}"

    if [[ "$haystack" == *"$needle"* ]]; then
        fail "$message (unexpected '$needle')"
    fi
}

assert_file() {
    local path="$1"
    [[ -f "$path" ]] || fail "expected file: $path"
}

assert_dir() {
    local path="$1"
    [[ -d "$path" ]] || fail "expected directory: $path"
}

assert_exit() {
    local expected="$1"
    shift
    capture "$@"
    assert_eq "$expected" "$COMMAND_STATUS" "unexpected exit status for: $*"
}
