#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/test_helper.bash"

SANDBOX_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cyberpunk-runtime-validation-test.XXXXXX")"
trap 'rm -rf "$SANDBOX_ROOT"' EXIT

run_cli() {
    local project="$1"
    shift
    (cd "$project" && "$CYBERPUNK_BIN" "$@")
}

test_start "status reports synchronized native registrations without claiming live capability"
project="$SANDBOX_ROOT/healthy"
mkdir -p "$project"
git -C "$project" init -q
assert_exit 0 run_cli "$project" init
assert_exit 0 run_cli "$project" validate
before="$(cksum "$project/.cyberpunk/generated.yml")"
git_before="$(git -C "$project" status --porcelain)"
assert_exit 0 run_cli "$project" status
assert_contains "$COMMAND_OUTPUT" "Configured runtimes: codex, claude, cursor"
assert_contains "$COMMAND_OUTPUT" "Parallelism: auto"
assert_contains "$COMMAND_OUTPUT" "Maximum concurrent subagents: 3"
assert_contains "$COMMAND_OUTPUT" "Model fallback: inherit"
assert_contains "$COMMAND_OUTPUT" "Native agents: codex=11 claude=11 cursor=11"
assert_contains "$COMMAND_OUTPUT" "Native skills: codex=16 claude=16 cursor=16"
assert_contains "$COMMAND_OUTPUT" "Generated assets: synchronized"
assert_not_contains "$COMMAND_OUTPUT" "parallel agents available"
assert_eq "$before" "$(cksum "$project/.cyberpunk/generated.yml")" "status changed generated state"
assert_eq "$git_before" "$(git -C "$project" status --porcelain)" "status changed the project"

test_start "validation rejects exact managed-block and skill-wrapper corruption without writing"
sed "s/and use the active runtime's native Cyberpunk agents and skills\. Dispatch/and use drifted native Cyberpunk agents and skills. Dispatch/" \
    "$project/AGENTS.md" > "$project/managed.tmp"
mv "$project/managed.tmp" "$project/AGENTS.md"
managed_before="$(cksum "$project/AGENTS.md")"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Managed instruction block differs from canonical content: AGENTS.md"
assert_eq "$managed_before" "$(cksum "$project/AGENTS.md")" "validate rewrote managed content"
assert_eq "$git_before" "$(git -C "$project" status --porcelain)" "validate changed the project"
assert_exit 0 run_cli "$project" sync --force

sed 's|../../../skills/core/task-decomposition/SKILL.md|../../../skills/core/missing/SKILL.md|' \
    "$project/.agents/skills/task-decomposition/SKILL.md" > "$project/wrapper.tmp"
mv "$project/wrapper.tmp" "$project/.agents/skills/task-decomposition/SKILL.md"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Native skill wrapper differs from canonical registration"
assert_exit 0 run_cli "$project" sync --force

cp "$project/.cyberpunk/generated.yml" "$project/manifest.healthy.yml"
awk '
    $0 == "  - path: \".codex/agents/nexus.toml\"" { skip=6 }
    skip > 0 { skip--; next }
    { print }
' "$project/.cyberpunk/generated.yml" > "$project/manifest.tmp"
mv "$project/manifest.tmp" "$project/.cyberpunk/generated.yml"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Native identifier collision at expected path without manifest record: .codex/agents/nexus.toml"
cp "$project/manifest.healthy.yml" "$project/.cyberpunk/generated.yml"

test_start "validation rejects duplicate fixed-schema configuration fields"
cp "$project/.cyberpunk/config.yml" "$project/config.fixed.yml"
printf '%s\n' 'execution:' '  max_concurrent_agents: 3' >> "$project/.cyberpunk/config.yml"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Configuration section must appear exactly once: execution"
cp "$project/config.fixed.yml" "$project/.cyberpunk/config.yml"

test_start "validation rejects invalid concurrency and missing expected native agent"
cp "$project/.cyberpunk/config.yml" "$project/config.healthy.yml"
sed 's/max_concurrent_agents: 3/max_concurrent_agents: 4/' \
    "$project/.cyberpunk/config.yml" > "$project/.cyberpunk/config.yml.tmp"
mv "$project/.cyberpunk/config.yml.tmp" "$project/.cyberpunk/config.yml"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "max_concurrent_agents must be an integer from 1 to 3"
assert_exit 0 run_cli "$project" status
assert_contains "$COMMAND_OUTPUT" "Maximum concurrent subagents: unknown"
assert_contains "$COMMAND_OUTPUT" "Generated assets: drift detected"

cp "$project/config.healthy.yml" "$project/.cyberpunk/config.yml"
rm "$project/.codex/agents/nexus.toml"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Missing expected generated asset: .codex/agents/nexus.toml"

test_start "status reports generated drift for a missing expected native agent"
assert_exit 0 run_cli "$project" status
assert_contains "$COMMAND_OUTPUT" "Generated assets: drift detected"

test_start "recorded native run evidence binds parallel safety, review, and delivery claims"
assert_exit 0 run_cli "$project" init --force

write_run_state() {
    local name="$1"
    mkdir -p "$project/.cyberpunk/runs/$name"
    cat > "$project/.cyberpunk/runs/$name/state.yml"
}

write_run_state valid <<'EOF'
runtime: codex
execution_mode: parallel
max_concurrent_agents: 3
jobs:
  frontend:
    native_agent: neon
    agent_instance: codex-agent-worker
    parallel_safe: true
    allowed_scope: [src/frontend/**]
    review_agent_instance: codex-agent-reviewer
    review_context: fresh
    review_status: approved
fallback:
  used: false
EOF
assert_exit 0 run_cli "$project" validate

write_run_state invalid-maximum <<'EOF'
max_concurrent_agents: 4
EOF
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Recorded run max_concurrent_agents must be an integer from 1 to 3"
rm -rf "$project/.cyberpunk/runs/invalid-maximum"

write_run_state overlap <<'EOF'
runtime: codex
execution_mode: parallel
max_concurrent_agents: 3
jobs:
  frontend:
    native_agent: neon
    agent_instance: codex-agent-frontend
    parallel_safe: true
    allowed_scope: [src/shared/**]
    review_agent_instance: codex-agent-reviewer-frontend
    review_context: fresh
    review_status: approved
  api:
    native_agent: daemon
    agent_instance: codex-agent-api
    parallel_safe: true
    allowed_scope: [src/shared/**]
    review_agent_instance: codex-agent-reviewer-api
    review_context: fresh
    review_status: approved
fallback:
  used: false
EOF
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Recorded parallel-safe jobs overlap mutable scope: src/shared/**"
rm -rf "$project/.cyberpunk/runs/overlap"

write_run_state missing-reviewer <<'EOF'
runtime: codex
execution_mode: parallel
max_concurrent_agents: 3
jobs:
  frontend:
    native_agent: neon
    agent_instance: codex-agent-worker
    parallel_safe: true
    allowed_scope: [src/frontend/**]
    review_agent_instance: null
    review_context: stale
    review_status: approved
fallback:
  used: false
EOF
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Approved native review lacks fresh reviewer identity/context"
rm -rf "$project/.cyberpunk/runs/missing-reviewer"

write_run_state same-reviewer <<'EOF'
runtime: codex
execution_mode: parallel
max_concurrent_agents: 3
jobs:
  frontend:
    native_agent: neon
    agent_instance: codex-agent-worker
    parallel_safe: true
    allowed_scope: [src/frontend/**]
    review_agent_instance: codex-agent-worker
    review_context: fresh
    review_status: approved
fallback:
  used: false
EOF
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Approved native review lacks fresh reviewer identity/context"
rm -rf "$project/.cyberpunk/runs/same-reviewer"

write_run_state glob-overlap <<'EOF'
runtime: codex
execution_mode: parallel
max_concurrent_agents: 3
jobs:
  broad:
    native_agent: neon
    agent_instance: agent-one
    parallel_safe: true
    allowed_scope: [src/**]
    review_agent_instance: review-one
    review_context: fresh
    review_status: approved
  narrow:
    native_agent: daemon
    agent_instance: agent-two
    parallel_safe: true
    allowed_scope: [src/frontend/**]
    review_agent_instance: review-two
    review_context: fresh
    review_status: approved
fallback:
  used: false
EOF
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Recorded parallel-safe jobs overlap mutable scope: src/** and src/frontend/**"
rm -rf "$project/.cyberpunk/runs/glob-overlap"

mkdir -p "$project/.cyberpunk/runs/empty"
: > "$project/.cyberpunk/runs/empty/state.yml"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Recorded run state is empty"
rm -rf "$project/.cyberpunk/runs/empty"

write_run_state unsupported-parallel-claim <<'EOF'
runtime: codex
execution_mode: parallel
max_concurrent_agents: 3
jobs:
  frontend:
    parallel_safe: true
    allowed_scope: [src/frontend/**]
fallback:
  used: false
EOF
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Recorded parallel execution/delivery claim lacks native agent evidence"

echo "PASS: runtime validation tests"
