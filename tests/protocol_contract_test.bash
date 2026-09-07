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
NEXUS="$TEMPLATE_ROOT/agents/nexus.md"
COMMON_PRINCIPLES="$TEMPLATE_ROOT/agents/_common-principles.md"
WORKTREE_SKILL="$TEMPLATE_ROOT/skills/core/worktree-isolation/SKILL.md"
DECOMPOSITION_SKILL="$TEMPLATE_ROOT/skills/core/task-decomposition/SKILL.md"
REVIEW_SKILL="$TEMPLATE_ROOT/skills/core/code-review/SKILL.md"

test_start "canonical protocol files exist"
assert_file "$CONFIG"
assert_file "$WORKFLOW"
assert_file "$PROJECT"
assert_file "$DECISIONS"
assert_file "$PATTERNS"
assert_file "$LESSONS"
assert_file "$TEMPLATE_ROOT/specs/.gitkeep"
assert_contains "$(<"$WORKFLOW")" "Protocol version: 2" "canonical protocol version marker"

test_start "configuration is adaptive and integration-branch based"
config_content="$(<"$CONFIG")"
for value in \
    "version: 2" \
    "runtimes:" \
    "enabled: [codex, claude, cursor]" \
    "execution:" \
    "parallelism: auto" \
    "max_concurrent_agents: 3" \
    "unavailable_runtime_fallback: sequential" \
    "models:" \
    "fallback: inherit" \
    "profiles:" \
    "cursor: \"composer-2.5[]\"" \
    "roles:" \
    "overrides: {}" \
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

test_start "configuration uses the exact approved model profiles and role mappings"
for block in \
    $'    deep:\n      codex: "gpt-5.6-sol"\n      claude: "opus"\n      cursor: "gpt-5.6-sol"' \
    $'    balanced:\n      codex: "gpt-5.6-terra"\n      claude: "sonnet"\n      cursor: "composer-2.5[]"' \
    $'    fast:\n      codex: "gpt-5.6-luna"\n      claude: "haiku"\n      cursor: "composer-2.5"' \
    $'  roles:\n    nexus: deep\n    fixer: deep\n    operator: fast\n    mind: deep\n    interrogator: deep\n    fragmenter: balanced\n    coder: balanced\n    daemon: balanced\n    neon: balanced\n    grid-master: balanced\n    gatekeeper: deep'; do
    assert_contains "$config_content" "$block" "exact model configuration"
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

test_start "canonical workflow records sole native dispatch and observed execution"
for value in \
    "Nexus is the only component allowed to spawn" \
    "dependency-ready" \
    "ready queue" \
    "parallel_safe" \
    "max_concurrent_agents" \
    "three active subagents" \
    "full queue" \
    "fresh Gatekeeper" \
    "assembled-change review" \
    "model_preferred" \
    "model_effective" \
    "model_fallback_reason" \
    "native agent evidence" \
    "roles performed in the parent context"; do
    assert_contains "$workflow_content" "$value" "native dispatch and observed execution"
done
for value in \
    "parallelism: sequential" \
    "effective_limit" \
    "minimum of the configured maximum, the observed runtime cap, and three" \
    "never dispatches above"; do
    assert_contains "$workflow_content" "$value" "effective dispatch limit"
done
for value in \
    "integration_owner: null" \
    "integration_contract: null" \
    "allowed_scope:" \
    "schema_version: 2" \
    "review_agent_instance:" \
    "review_context: fresh" \
    "verification_observed:" \
    "execution_status:" \
    "fallback:" \
    "observed_evidence:" \
    "affected_jobs:" \
    "delivery_impact:"; do
    assert_contains "$workflow_content" "$value" "run-state evidence schema"
done
assert_contains "$workflow_content" 'Legacy `run.yml`' "legacy run-state compatibility"
assert_contains "$workflow_content" 'pre-0.4 `state.yml`' "legacy state schema compatibility"

test_start "fallback vocabulary records the only supported observed model recovery"
for value in \
    "native_tools_unavailable" \
    "delegation_disabled_by_policy" \
    "delegation_disabled_by_user" \
    "no_parallel_safe_packets" \
    "runtime_spawn_failure" \
    'retries once with `inherit`' \
    "built-in default worker" \
    "no duplicate fallback agent files"; do
    assert_contains "$workflow_content" "$value" "fallback protocol"
done

test_start "work packets and skills enforce safe native isolation and fresh review"
for value in \
    "parallel_safe: true" \
    "dependencies: []" \
    "allowed_scope:" \
    "integration_owner: null" \
    "integration_contract: null" \
    "required_skills: []" \
    "model_profile: balanced" \
    "worktree isolation does not make overlapping ownership safe"; do
    assert_contains "$workflow_content" "$value" "work packet contract"
done

decomposition_skill="$(<"$DECOMPOSITION_SKILL")"
for value in "parallel_safe" "dependencies" "allowed_scope" "integration owner" "integration contract" "required skills" "model profile"; do
    assert_contains "$decomposition_skill" "$value" "decomposition packet contract"
done

worktree_skill="$(<"$WORKTREE_SKILL")"
for value in "native runtime" "worker branch" "base commit" "allowed scope" "integration contract"; do
    assert_contains "$worktree_skill" "$value" "native worktree evidence"
done

review_skill="$(<"$REVIEW_SKILL")"
for value in "review_agent_instance" "review_context: fresh" "result_commit" "verification_observed" "runtime-provided"; do
    assert_contains "$review_skill" "$value" "fresh review evidence"
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

test_start "requirements discovery routes safely and hands off a committed PRD"
for value in \
    "## Requirements Discovery" \
    "new product, feature, or architectural" \
    "routine bug fix or maintenance" \
    "specs/YYYY-MM-DD-<topic>-prd.md" \
    "current named branch" \
    "planning-artifact exception" \
    "source: fixer" \
    "discovery_complete: true" \
    "prd_commit:" \
    "user_authorized_handoff: true" \
    "continue sequentially" \
    "Interactive Fixer discovery remains in the parent conversation" \
    "Non-interactive Fixer analysis may use a native subagent" \
    "does not repeat discovery"; do
    assert_contains "$workflow_content" "$value" "Fixer workflow contract"
done

test_start "fresh Gatekeeper evidence is conditional on native delegation"
for value in \
    "When native delegation is available" \
    "review_agent_instance: null" \
    "review_context: parent" \
    "parent-session fallback"; do
    assert_contains "$workflow_content" "$value" "conditional Gatekeeper evidence"
done

nexus_content="$(<"$NEXUS")"
for value in \
    "The Fixer" \
    "approved PRD" \
    "discovery_complete: true" \
    "does not repeat completed discovery"; do
    assert_contains "$nexus_content" "$value" "Nexus discovery routing"
done

common_principles="$(<"$COMMON_PRINCIPLES")"
for value in "planning-artifact exception" "approved PRD" "current named branch"; do
    assert_contains "$common_principles" "$value" "PRD worktree exception"
done

worktree_skill="$(<"$WORKTREE_SKILL")"
for value in \
    "mutating implementation" \
    "only approved planning-artifact exception" \
    "approved PRD" \
    "current named branch" \
    "does not exempt implementation"; do
    assert_contains "$worktree_skill" "$value" "worktree skill PRD exception"
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
