#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/test_helper.bash"

SKILL_ROOT="$REPO_ROOT/templates/skills"
expected_skills=(
    task-classification
    repository-discovery
    implementation-planning
    plan-review
    task-decomposition
    worktree-isolation
    scoped-implementation
    systematic-debugging
    test-first-development
    backend-safety
    frontend-quality
    infrastructure-safety
    code-review
    verification-before-delivery
    memory-curation
)

test_start "skill extension points exist"
assert_file "$SKILL_ROOT/README.md"
assert_file "$SKILL_ROOT/project/.gitkeep"
readme="$(<"$SKILL_ROOT/README.md")"
assert_contains "$readme" "user-owned"
assert_contains "$readme" "never overwritten"
assert_contains "$readme" "explicitly enabled"

test_start "every core skill has portable metadata and instructions"
seen_names=""
for skill in "${expected_skills[@]}"; do
    path="$SKILL_ROOT/core/$skill/SKILL.md"
    assert_file "$path"
    content="$(<"$path")"
    assert_contains "$content" "name: $skill" "$skill frontmatter name"
    assert_contains "$content" "description: Use when" "$skill frontmatter description"
    for heading in "## Metadata" "## When to Use" "## Inputs" "## Procedure" "## Verification" "## Output"; do
        assert_contains "$content" "$heading" "$skill required heading"
    done
    for field in "- Version:" "- Triggers:" "- Allowed agents:" "- Side effects:"; do
        assert_contains "$content" "$field" "$skill metadata field"
    done
    if [[ " $seen_names " == *" $skill "* ]]; then
        fail "duplicate skill name: $skill"
    fi
    seen_names="$seen_names $skill"
done

test_start "core skills remain language neutral"
for skill in "${expected_skills[@]}"; do
    content="$(<"$SKILL_ROOT/core/$skill/SKILL.md")"
    for banned in "npm " "pytest" "cargo " "go test" "mvn " "dotnet "; do
        assert_not_contains "$content" "$banned" "$skill must not prescribe $banned"
    done
done

test_start "worktree and memory skills preserve critical invariants"
worktree="$(<"$SKILL_ROOT/core/worktree-isolation/SKILL.md")"
for value in "integration branch" "worker branch" "base commit" "Gatekeeper" "dependency order" "assembled verification" "protected branch" "cleanup"; do
    assert_contains "$worktree" "$value" "worktree lifecycle"
done
memory="$(<"$SKILL_ROOT/core/memory-curation/SKILL.md")"
for value in "evidence" "generalizable" "actionable" "secret" "superseded"; do
    assert_contains "$memory" "$value" "memory safeguard"
done

echo "PASS: skill contract tests"
