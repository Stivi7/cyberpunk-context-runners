#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/test_helper.bash"

TEMPLATE_ROOT="$REPO_ROOT/templates"
CONFIG="$TEMPLATE_ROOT/.cyberpunk/config.yml"
WORKFLOW="$TEMPLATE_ROOT/.cyberpunk/workflow.md"
PROJECT="$TEMPLATE_ROOT/.cyberpunk/project.md"
DECISIONS="$TEMPLATE_ROOT/.cyberpunk/memory/decisions.md"
PATTERNS="$TEMPLATE_ROOT/.cyberpunk/memory/patterns.md"
LESSONS="$TEMPLATE_ROOT/.cyberpunk/memory/lessons.md"

test_start "canonical protocol files exist"
assert_file "$CONFIG"
assert_file "$WORKFLOW"
assert_file "$PROJECT"
assert_file "$DECISIONS"
assert_file "$PATTERNS"
assert_file "$LESSONS"
assert_file "$TEMPLATE_ROOT/specs/.gitkeep"

test_start "configuration is adaptive and integration-branch based"
config_content="$(<"$CONFIG")"
for value in \
    "version: 1" \
    "default: integration-branch" \
    "mode: adaptive" \
    "integration_branch: auto" \
    "branch_prefix: cyberpunk/" \
    "worktree_root: .worktrees" \
    "require_worktrees: true" \
    "allow_internal_commits: true" \
    "allow_protected_branch_merge: false" \
    "allow_push: false" \
    "allow_pull_requests: false" \
    "allow_deploy: false" \
    "core_path: skills/core" \
    "project_path: skills/project" \
    "enabled_project: []"; do
    assert_contains "$config_content" "$value" "configuration contract"
done

test_start "workflow defines the complete job lifecycle"
workflow_content="$(<"$WORKFLOW")"
for heading in \
    "## Intake" \
    "## Classification" \
    "## Planning" \
    "## Worktree Assignment" \
    "## Implementation" \
    "## Review and Repair" \
    "## Integration" \
    "## Delivery" \
    "## Retrospective" \
    "## Work Packet Contract" \
    "## Result Contract" \
    "## Run State"; do
    assert_contains "$workflow_content" "$heading" "workflow stage"
done
for value in \
    "cyberpunk/<task-id>-<slug>" \
    "cyberpunk/<task-id>/<role>-<work-unit>" \
    "integration_branch" \
    "worker_branch" \
    "base_commit" \
    "result_commit" \
    "merge_ready" \
    "merged" \
    "protected branch"; do
    assert_contains "$workflow_content" "$value" "worktree lifecycle"
done

test_start "project context uses conceptual command categories"
project_content="$(<"$PROJECT")"
for category in setup format_check lint static_analysis unit_test integration_test build security; do
    assert_contains "$project_content" "$category" "project command category"
done

test_start "curated memories have evidence-bearing schemas"
assert_contains "$(<"$DECISIONS")" "Rationale:"
assert_contains "$(<"$DECISIONS")" "Revisit when:"
assert_contains "$(<"$PATTERNS")" "Applicability:"
assert_contains "$(<"$PATTERNS")" "Example:"
lessons_content="$(<"$LESSONS")"
for field in "Symptom:" "Root cause:" "Prevention:" "Scope:" "Evidence:" "Status:"; do
    assert_contains "$lessons_content" "$field" "lesson field"
done

echo "PASS: protocol contract tests"
