#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/test_helper.bash"

AGENT_ROOT="$REPO_ROOT/templates/agents"
agents=(nexus fixer operator mind interrogator fragmenter coder daemon neon grid-master gatekeeper)
required_headings=(
    "## Mission"
    "## Owns"
    "## Does Not Own"
    "## Default Skills"
    "## Inputs"
    "## Workflow"
    "## Output Contract"
    "## Escalation"
    "## References"
)

test_start "all public agents implement the shared contract"
for agent in "${agents[@]}"; do
    path="$AGENT_ROOT/$agent.md"
    assert_file "$path"
    content="$(<"$path")"
    for heading in "${required_headings[@]}"; do
        assert_contains "$content" "$heading" "$agent agent contract"
    done
done

test_start "Nexus owns adaptive integration-branch delivery"
nexus="$(<"$AGENT_ROOT/nexus.md")"
for value in "adaptive" "integration branch" "dependency order" "worktree" "cleanup" "delivery"; do
    assert_contains "$nexus" "$value" "Nexus responsibility"
done

test_start "Coder is a shared contract with backend and frontend specialists"
assert_contains "$(<"$AGENT_ROOT/coder.md")" "shared engineering contract"
assert_contains "$(<"$AGENT_ROOT/daemon.md")" "backend engineer"
assert_contains "$(<"$AGENT_ROOT/neon.md")" "frontend engineer"

test_start "parallel work and review have independent safeguards"
fragmenter="$(<"$AGENT_ROOT/fragmenter.md")"
assert_contains "$fragmenter" "non-overlapping"
assert_contains "$fragmenter" "integration contract"
gatekeeper="$(<"$AGENT_ROOT/gatekeeper.md")"
assert_contains "$gatekeeper" "independently"
assert_contains "$gatekeeper" "rerun"
assert_contains "$gatekeeper" "result commit"

test_start "Fixer owns approved PRD creation and handoff gates"
fixer="$(<"$AGENT_ROOT/fixer.md")"
for value in \
    "requirements-discovery" \
    "specs/YYYY-MM-DD-<topic>-prd.md" \
    "current named branch" \
    "commit only the approved PRD" \
    "ask whether to hand" \
    "does not implement"; do
    assert_contains "$fixer" "$value" "Fixer responsibility"
done

test_start "agent defaults are runtime neutral"
for agent in "${agents[@]}"; do
    content="$(<"$AGENT_ROOT/$agent.md")"
    for banned in "AWS" "TypeScript" "npm" "95%"; do
        assert_not_contains "$content" "$banned" "$agent must not prescribe $banned"
    done
done

echo "PASS: agent contract tests"
