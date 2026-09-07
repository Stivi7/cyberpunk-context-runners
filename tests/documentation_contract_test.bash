#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/test_helper.bash"

adapters=(
    "$REPO_ROOT/templates/AGENTS.md"
    "$REPO_ROOT/templates/CLAUDE.md"
    "$REPO_ROOT/templates/.cursor/rules/rules.mdc"
)

test_start "runtime adapters are thin pointers to the canonical team"
for adapter in "${adapters[@]}"; do
    assert_file "$adapter"
    content="$(<"$adapter")"
    assert_contains "$content" ".cyberpunk/workflow.md" "adapter workflow pointer"
    assert_contains "$content" "agents/nexus.md" "adapter Nexus pointer"
    line_count="$(wc -l < "$adapter" | tr -d ' ')"
    if [[ "$line_count" -gt 35 ]]; then
        fail "adapter duplicates too much policy: $adapter ($line_count lines)"
    fi
done

test_start "README documents discovery and autonomous integration-branch flow"
readme="$(<"$REPO_ROOT/README.md")"
for value in \
    "The Nexus" \
    "quick" \
    "standard" \
    "complex" \
    "The Daemon" \
    "The Neon" \
    "11 specialized roles" \
    "The Fixer" \
    "requirements-discovery" \
    "specs/YYYY-MM-DD-<topic>-prd.md" \
    "asks whether to hand" \
    "integration branch" \
    "worktree" \
    "skills/project" \
    ".cyberpunk/memory" \
    "cyberpunk validate" \
    "cyberpunk status"; do
    assert_contains "$readme" "$value" "README contract"
done

test_start "documentation remains runtime neutral"
documentation="$readme$(<"$REPO_ROOT/templates/README.md")"
for adapter in "${adapters[@]}"; do
    documentation="$documentation$(<"$adapter")"
done
for banned in "AWS" "TypeScript" "npm" "95% coverage"; do
    assert_not_contains "$documentation" "$banned" "documentation must not prescribe $banned"
done

test_start "shipped example follows the runtime-neutral specification model"
example="$REPO_ROOT/templates/examples/specs/todo-list-example.md"
assert_file "$example"
[[ ! -e "$REPO_ROOT/templates/examples/PRPs/todo-list-example.md" ]] || fail "legacy stack-specific PRP example is still shipped"
example_content="$(<"$example")"
for heading in "## Objective" "## Scope" "## Acceptance Criteria" "## Verification Categories" "## Delivery"; do
    assert_contains "$example_content" "$heading" "example specification"
done
for banned in "AWS" "TypeScript" "npm" "95% coverage"; do
    assert_not_contains "$example_content" "$banned" "example must not prescribe $banned"
done

echo "PASS: documentation contract tests"
