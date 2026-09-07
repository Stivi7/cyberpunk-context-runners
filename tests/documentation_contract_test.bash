#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/test_helper.bash"

SANDBOX_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cyberpunk-documentation-test.XXXXXX")"
trap 'rm -rf "$SANDBOX_ROOT"' EXIT
project="$SANDBOX_ROOT/project"
mkdir -p "$project"
(cd "$project" && "$CYBERPUNK_BIN" init >/dev/null)

adapters=(
    "$project/AGENTS.md"
    "$project/CLAUDE.md"
    "$project/.cursor/rules/cyberpunk.mdc"
)

test_start "runtime adapters are thin pointers to the canonical team"
for adapter in "${adapters[@]}"; do
    assert_file "$adapter"
    content="$(<"$adapter")"
    assert_contains "$content" ".cyberpunk/workflow.md" "adapter workflow pointer"
    assert_contains "$content" "Nexus" "adapter Nexus pointer"
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

test_start "README and generated-template guide document runtime-native setup and inspection"
template_readme="$(<"$REPO_ROOT/templates/README.md")"
documentation="$readme$template_readme"
for value in \
    "cyberpunk init --runtime codex" \
    "cyberpunk init --runtime claude" \
    "cyberpunk init --runtime cursor" \
    "cyberpunk init --runtime codex --runtime claude" \
    "cyberpunk sync" \
    ".codex/agents/" \
    ".agents/skills/" \
    ".claude/agents/" \
    ".claude/skills/" \
    ".cursor/agents/" \
    ".cursor/skills/" \
    "max_concurrent_agents: 3" \
    "worktree isolation does not start agents" \
    "inherit" \
    "generated.yml" \
    "dependency-bound roles remain sequential" \
    "full queue waits" \
    "modified generated files require" \
    "migration is idempotent" \
    "reviewed canonical-protocol upgrade" \
    "interactive Fixer discovery" \
    "parent conversation" \
    "non-interactive Fixer analysis" \
    "parallelism: sequential" \
    "configured maximum, the observed runtime cap, and three" \
    "review_context: parent" \
    "does not prove live capability"; do
    assert_contains "$documentation" "$value" "runtime-native documentation contract"
done

test_start "optional usage-consuming live runtime smoke matrix is documented, not automated"
live_smoke="$REPO_ROOT/docs/live-runtime-smoke.md"
assert_file "$live_smoke"
live_smoke_content="$(<"$live_smoke")"
for value in \
    "Optional" \
    "usage-consuming" \
    "account-dependent" \
    "Codex" \
    "Claude Code" \
    "Cursor" \
    "four independent packets" \
    "three native subagents" \
    "queued packet" \
    "worktree/branch isolation" \
    "fresh Gatekeeper identity" \
    "sequential fallback" \
    'one `inherit` retry'; do
    assert_contains "$live_smoke_content" "$value" "live smoke matrix contract"
done

test_start "documentation remains runtime neutral"
documentation="$readme$template_readme"
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
