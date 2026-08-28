#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test_count=0

for test_file in "$TESTS_DIR"/*_test.bash; do
    [[ -f "$test_file" ]] || continue
    bash "$test_file"
    test_count=$((test_count + 1))
done

echo "All $test_count test files passed."
