#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/test_helper.bash"

SKILL_ROOT="$REPO_ROOT/templates/skills"
expected_skills=(
    task-classification
    requirements-discovery
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
    assert_eq 2 "$(grep -Fxc -- '---' "$path")" "$skill frontmatter delimiter count"
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

test_start "requirements discovery preserves approval and handoff gates"
discovery="$(<"$SKILL_ROOT/core/requirements-discovery/SKILL.md")"
for value in \
    "Brief" \
    "Standard" \
    "Architectural" \
    "one focused question" \
    "two or three" \
    "design approval" \
    "artifact approval" \
    "specs/YYYY-MM-DD-<topic>-prd.md" \
    "must not overwrite" \
    "current named branch" \
    "commit only the approved PRD" \
    "discovery_complete: true" \
    "user_authorized_handoff: true"; do
    assert_contains "$discovery" "$value" "requirements-discovery safeguard"
done

test_start "requirements discovery defines the complete PRD schema"
prd_headings=(
    "Summary and Problem Statement"
    "Target Users and Use Cases"
    "Goals and Success Criteria"
    "Non-goals and Scope Boundaries"
    "Functional Requirements"
    "User Journeys and Expected Behavior"
    "Constraints and Non-functional Requirements"
    "Considered Approaches and Accepted Decisions"
    "Edge Cases and Failure Behavior"
    "Acceptance Criteria"
    "Dependencies and Risks"
    "Deferred Decisions"
)
for heading in "${prd_headings[@]}"; do
    assert_contains "$discovery" "$heading" "requirements-discovery PRD heading"
done
for field in "owner" "reason" "resolution stage"; do
    assert_contains "$discovery" "$field" "requirements-discovery deferred-decision field"
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
assert_contains "$worktree" "Mutating implementation jobs" "worktree trigger scope"
assert_contains "$worktree" "only approved planning-artifact exception" "worktree PRD exception"
assert_not_contains "$worktree" "Any mutating agent job" "worktree trigger must not cover planning artifacts"
assert_not_contains "$worktree" "every job that may write" "worktree usage must be implementation-scoped"
for value in "native runtime" "worker branch" "base commit" "allowed scope" "integration contract" "Nexus creates"; do
    assert_contains "$worktree" "$value" "native worktree compatibility"
done
decomposition="$(<"$SKILL_ROOT/core/task-decomposition/SKILL.md")"
for value in "parallel_safe" "dependencies" "allowed_scope" "integration owner" "integration contract" "required skills" "model profile" "Worktree isolation"; do
    assert_contains "$decomposition" "$value" "native decomposition safety"
done
review="$(<"$SKILL_ROOT/core/code-review/SKILL.md")"
for value in "fresh context" "review_agent_instance" "review_context: fresh" "result_commit" "verification_observed" "runtime-provided" "assembled"; do
    assert_contains "$review" "$value" "fresh Gatekeeper review evidence"
done
memory="$(<"$SKILL_ROOT/core/memory-curation/SKILL.md")"
for value in "evidence" "generalizable" "actionable" "secret" "superseded"; do
    assert_contains "$memory" "$value" "memory safeguard"
done

echo "PASS: skill contract tests"
