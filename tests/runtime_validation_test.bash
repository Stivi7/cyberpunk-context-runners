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
assert_exit 0 run_cli "$project" init
assert_exit 0 run_cli "$project" validate
before="$(cksum "$project/.cyberpunk/generated.yml")"
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
