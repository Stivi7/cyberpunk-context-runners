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
for value in "adaptive" "integration branch" "dependency order" "worktree" "cleanup" "delivery" "spawn" "resume" "steer" "interrupt" "replace" "ready queue" "three active subagents" "fresh Gatekeeper" "assembled-change review"; do
    assert_contains "$nexus" "$value" "Nexus responsibility"
done

test_start "Nexus alone delegates and all other roles reject nested team delegation"
common="$(<"$AGENT_ROOT/_common-principles.md")"
for value in "## Native Delegation" "only dispatcher" "never spawn" "steer" "resume" "interrupt" "replace" "fresh-context" "not inherited" "sequential fallback"; do
    assert_contains "$common" "$value" "common native delegation rule"
done
for agent in "${agents[@]}"; do
    [[ "$agent" == nexus ]] && continue
    content="$(<"$AGENT_ROOT/$agent.md")"
    assert_contains "$content" "./_common-principles.md" "$agent must inherit the nested delegation prohibition"
done

test_start "Coder is a shared contract with backend and frontend specialists"
assert_contains "$(<"$AGENT_ROOT/coder.md")" "shared engineering contract"
assert_contains "$(<"$AGENT_ROOT/daemon.md")" "backend engineer"
assert_contains "$(<"$AGENT_ROOT/neon.md")" "frontend engineer"

test_start "parallel work and review have independent safeguards"
fragmenter="$(<"$AGENT_ROOT/fragmenter.md")"
for value in "non-overlapping" "integration contract" "dependencies" "allowed scope" "parallel_safe" "integration owner" "required skills" "model profile"; do
    assert_contains "$fragmenter" "$value" "Fragmenter packet safeguard"
done
gatekeeper="$(<"$AGENT_ROOT/gatekeeper.md")"
for value in "independently" "rerun" "result commit" "fresh" "review_agent_instance" "review_context: fresh" "verification_observed" "review_status: approved" "assembled"; do
    assert_contains "$gatekeeper" "$value" "Gatekeeper fresh review safeguard"
done

test_start "Fixer owns approved PRD creation and handoff gates"
fixer="$(<"$AGENT_ROOT/fixer.md")"
for value in \
    "requirements-discovery" \
    "specs/YYYY-MM-DD-<topic>-prd.md" \
    "current named branch" \
    "commit only the approved PRD" \
    "The Fixer must ask whether to hand the committed PRD to Nexus." \
    "does not implement"; do
    assert_contains "$fixer" "$value" "Fixer responsibility"
done
handoff_obligation_count="$(grep -Fxc -- "- The Fixer must ask whether to hand the committed PRD to Nexus." "$AGENT_ROOT/fixer.md")"
assert_eq "1" "$handoff_obligation_count" "Fixer handoff obligation must have one normative bullet"
assert_not_contains "$fixer" "- Asking whether to hand the committed PRD to Nexus." "Fixer handoff obligation must not be duplicated"

test_start "agent defaults are runtime neutral"
for agent in "${agents[@]}"; do
    content="$(<"$AGENT_ROOT/$agent.md")"
    for banned in "AWS" "TypeScript" "npm" "95%" "gpt-5.6" "opus" "sonnet" "haiku" "composer-2.5"; do
        assert_not_contains "$content" "$banned" "$agent must not prescribe $banned"
    done
done

echo "PASS: agent contract tests"
