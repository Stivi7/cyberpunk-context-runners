#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test_count=0

[[ -f "$TESTS_DIR/runtime_adapter_test.bash" ]] || {
    echo "Missing runtime adapter test harness" >&2
    exit 1
}

for test_file in "$TESTS_DIR"/*_test.bash; do
    [[ -f "$test_file" ]] || continue
    bash "$test_file"
    test_count=$((test_count + 1))
done

echo "All $test_count test files passed."
