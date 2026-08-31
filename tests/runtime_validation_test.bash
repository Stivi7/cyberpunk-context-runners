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

write_run_state() {
    local name="$1"
    mkdir -p "$project/.cyberpunk/runs/$name"
    {
        printf '%s\n' 'schema_version: 2'
        cat
    } > "$project/.cyberpunk/runs/$name/state.yml"
}

write_legacy_run_yml() {
    local name="$1"
    mkdir -p "$project/.cyberpunk/runs/$name"
    cat > "$project/.cyberpunk/runs/$name/run.yml"
}

write_legacy_state() {
    local name="$1"
    mkdir -p "$project/.cyberpunk/runs/$name"
    cat > "$project/.cyberpunk/runs/$name/state.yml"
}

test_start "status reports synchronized native registrations without claiming live capability"
project="$SANDBOX_ROOT/healthy"
mkdir -p "$project"
git -C "$project" init -q
assert_exit 0 run_cli "$project" init
assert_exit 0 run_cli "$project" validate

write_legacy_run_yml legacy-run-record <<'EOF'
runtime: codex
execution_mode: sequential
max_concurrent_agents: 1
jobs:
  frontend:
    native_agent: neon
    agent_instance: codex-agent-worker
    parallel_safe: false
    allowed_scope: [src/frontend/**]
    review_agent_instance: codex-agent-reviewer
    review_context: fresh
    verification_observed: [bash tests/frontend.bash]
    review_status: approved
    result_commit: def456
fallback:
  used: false
EOF
assert_exit 0 run_cli "$project" validate
rm -rf "$project/.cyberpunk/runs/legacy-run-record"

write_legacy_state pre-0-4-state <<'EOF'
integration_branch: cyberpunk/TASK-014-session-renewal
base_commit: abc123
jobs:
  backend:
    agent: daemon
    branch: cyberpunk/TASK-014/daemon-session-api
    worktree: .worktrees/TASK-014/daemon-session-api
    status: verified
    result_commit: def456
    review_status: approved
    merged: false
EOF
assert_exit 0 run_cli "$project" validate
rm -rf "$project/.cyberpunk/runs/pre-0-4-state"

write_legacy_state unversioned-current-state <<'EOF'
runtime: codex
execution_mode: sequential
max_concurrent_agents: 1
jobs:
  frontend:
    native_agent: neon
    parallel_safe: false
    allowed_scope: [src/frontend/**]
fallback:
  used: false
EOF
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Current state.yml requires schema_version: 2"
rm -rf "$project/.cyberpunk/runs/unversioned-current-state"

write_run_state reused-assembled-reviewer <<'EOF'
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
    verification_observed: [bash tests/frontend.bash]
    review_status: approved
    result_commit: def456
assembled_review:
  integrated_commit: fed789
  review_agent_instance: codex-agent-reviewer
  review_context: fresh
  verification_observed: [bash tests/assembled.bash]
  review_status: approved
fallback:
  used: false
EOF
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Approved assembled review reuses a per-result reviewer identity"
rm -rf "$project/.cyberpunk/runs/reused-assembled-reviewer"

write_run_state mixed-native-fallback <<'EOF'
runtime: codex
execution_mode: sequential
max_concurrent_agents: 3
jobs:
  native:
    native_agent: neon
    agent_instance: native-worker
    parallel_safe: false
    allowed_scope: [src/native/**]
    review_agent_instance: null
    review_context: stale
    verification_observed: [bash tests/native.bash]
    review_status: approved
    result_commit: native456
  fallback:
    native_agent: null
    agent_instance: null
    parallel_safe: false
    allowed_scope: [src/fallback/**]
    review_agent_instance: null
    review_context: stale
    verification_skipped_reason: runtime spawn failed | original diagnostics retained
    review_status: approved
    result_commit: fallback456
assembled_review:
  integrated_commit: fed789
  review_agent_instance: assembled-reviewer
  review_context: fresh
  verification_observed: [bash tests/assembled.bash]
  review_status: approved
fallback:
  used: true
  category: runtime_spawn_failure
  affected_jobs: [fallback]
EOF
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Approved native review lacks fresh reviewer identity/context"
rm -rf "$project/.cyberpunk/runs/mixed-native-fallback"
git -C "$project" add -A
git -C "$project" -c user.name="Fixture" -c user.email="fixture@example.test" commit -qm "baseline"
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

test_start "validation compares native agents and Cursor adapter with current renderer output"
cp "$project/.cyberpunk/config.yml" "$project/config.rendered.yml"
sed 's/      codex: "gpt-5.6-sol"/      codex: "render-drift-model"/' \
    "$project/config.rendered.yml" > "$project/.cyberpunk/config.yml"
generated_before_model_drift="$(cksum "$project/.codex/agents/fixer.toml")"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Native agent differs from current configuration: .codex/agents/fixer.toml"
assert_exit 0 run_cli "$project" status
assert_contains "$COMMAND_OUTPUT" "Generated assets: drift detected"
assert_eq "$generated_before_model_drift" "$(cksum "$project/.codex/agents/fixer.toml")" "validation rewrote a stale native agent"
cp "$project/config.rendered.yml" "$project/.cyberpunk/config.yml"

cursor_adapter="$project/.cursor/rules/cyberpunk.mdc"
printf '%s\n' 'renderer-owned-drift' >> "$cursor_adapter"
if command -v shasum >/dev/null 2>&1; then
    cursor_hash="$(shasum -a 256 "$cursor_adapter" | awk '{ print $1 }')"
else
    cursor_hash="$(sha256sum "$cursor_adapter" | awk '{ print $1 }')"
fi
awk -v expected_path='  - path: ".cursor/rules/cyberpunk.mdc"' -v hash="$cursor_hash" '
    $0 == expected_path { in_record=1 }
    in_record && /^    sha256: / { print "    sha256: \"" hash "\""; in_record=0; next }
    { print }
' "$project/.cyberpunk/generated.yml" > "$project/manifest.rendered.yml"
mv "$project/manifest.rendered.yml" "$project/.cyberpunk/generated.yml"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Cursor adapter differs from current renderer: .cursor/rules/cyberpunk.mdc"
assert_exit 0 run_cli "$project" sync --force

test_start "validation rejects exact managed-block and skill-wrapper corruption without writing"
sed "s/and use the active runtime's native Cyberpunk agents and skills\. Dispatch/and use drifted native Cyberpunk agents and skills. Dispatch/" \
    "$project/AGENTS.md" > "$project/managed.tmp"
mv "$project/managed.tmp" "$project/AGENTS.md"
managed_before="$(cksum "$project/AGENTS.md")"
managed_git_before_validate="$(git -C "$project" status --porcelain)"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Managed instruction block differs from canonical content: AGENTS.md"
assert_eq "$managed_before" "$(cksum "$project/AGENTS.md")" "validate rewrote managed content"
assert_eq "$managed_git_before_validate" "$(git -C "$project" status --porcelain)" "validate changed the project"
managed_git_before_status="$(git -C "$project" status --porcelain)"
assert_exit 0 run_cli "$project" status
assert_eq "$managed_before" "$(cksum "$project/AGENTS.md")" "status rewrote managed content"
assert_eq "$managed_git_before_status" "$(git -C "$project" status --porcelain)" "status changed the project"
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

sed 's/enabled: \[codex, claude, cursor\]/enabled: [codex, warp]/' "$project/config.fixed.yml" > "$project/.cyberpunk/config.yml"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Unknown configured runtime: warp"
cp "$project/config.fixed.yml" "$project/.cyberpunk/config.yml"

awk '{ print; if ($0 == "  fallback: inherit") print "  fallback: inherit" }' "$project/config.fixed.yml" > "$project/.cyberpunk/config.yml"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Configuration key must appear exactly once: models.fallback"
cp "$project/config.fixed.yml" "$project/.cyberpunk/config.yml"

awk '{ print; if ($0 == "    deep:") print "    deep:" }' "$project/config.fixed.yml" > "$project/.cyberpunk/config.yml"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Model profile must appear exactly once: deep"
cp "$project/config.fixed.yml" "$project/.cyberpunk/config.yml"

awk '{ print; if ($0 == "    neon: balanced") print "    neon: balanced" }' "$project/config.fixed.yml" > "$project/.cyberpunk/config.yml"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Model role must appear exactly once: neon"
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
assert_contains "$COMMAND_OUTPUT" "Missing generated asset: .codex/agents/nexus.toml"

test_start "status reports generated drift for a missing expected native agent"
assert_exit 0 run_cli "$project" status
assert_contains "$COMMAND_OUTPUT" "Generated assets: drift detected"

test_start "recorded native run evidence binds parallel safety, review, and delivery claims"
assert_exit 0 run_cli "$project" init --force

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
    verification_observed: [bash tests/frontend.bash]
    review_status: approved
    result_commit: def456
assembled_review:
  integrated_commit: fed789
  review_agent_instance: codex-agent-assembled-reviewer
  review_context: fresh
  verification_observed: [bash tests/assembled.bash]
  review_status: approved
fallback:
  used: false
EOF
assert_exit 0 run_cli "$project" validate

write_run_state missing-approved-evidence <<'EOF'
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
    verification_observed: []
    review_status: approved
    result_commit: def456
assembled_review:
  integrated_commit: fed789
  review_agent_instance: codex-agent-assembled-reviewer
  review_context: fresh
  verification_observed: [bash tests/assembled.bash]
  review_status: approved
fallback:
  used: false
EOF
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Approved review requires verification_observed or verification_skipped_reason"
rm -rf "$project/.cyberpunk/runs/missing-approved-evidence"

write_run_state missing-assembled-review <<'EOF'
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
    verification_observed: [bash tests/frontend.bash]
    review_status: approved
    result_commit: def456
fallback:
  used: false
EOF
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Recorded run state requires exactly one assembled_review section"
rm -rf "$project/.cyberpunk/runs/missing-assembled-review"

write_run_state invalid-assembled-review <<'EOF'
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
    verification_observed: [bash tests/frontend.bash]
    review_status: approved
    result_commit: def456
assembled_review:
  integrated_commit: null
  review_agent_instance: null
  review_context: stale
  verification_observed: []
  review_status: approved
fallback:
  used: false
EOF
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Approved assembled review lacks fresh reviewer identity/context"
assert_contains "$COMMAND_OUTPUT" "Approved assembled review requires integrated_commit"
assert_contains "$COMMAND_OUTPUT" "Approved review requires verification_observed or verification_skipped_reason"
rm -rf "$project/.cyberpunk/runs/invalid-assembled-review"

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

write_run_state sibling-scopes <<'EOF'
runtime: codex
execution_mode: parallel
max_concurrent_agents: 3
jobs:
  alpha:
    native_agent: neon
    agent_instance: agent-alpha
    parallel_safe: true
    allowed_scope: [src/a/**]
    review_agent_instance: review-alpha
    review_context: fresh
    verification_observed: [bash tests/alpha.bash]
    review_status: approved
    result_commit: alpha456
  beta:
    native_agent: daemon
    agent_instance: agent-beta
    parallel_safe: true
    allowed_scope: [src/b/**]
    review_agent_instance: review-beta
    review_context: fresh
    verification_observed: [bash tests/beta.bash]
    review_status: approved
    result_commit: beta456
assembled_review:
  integrated_commit: combined789
  review_agent_instance: assembled-reviewer
  review_context: fresh
  verification_observed: [bash tests/assembled.bash]
  review_status: approved
fallback:
  used: false
EOF
assert_exit 0 run_cli "$project" validate
rm -rf "$project/.cyberpunk/runs/sibling-scopes"

write_run_state normalized-alias-overlap <<'EOF'
runtime: codex
execution_mode: parallel
max_concurrent_agents: 3
jobs:
  broad:
    native_agent: neon
    parallel_safe: true
    allowed_scope: [./src//shared/**]
  narrow:
    native_agent: daemon
    parallel_safe: true
    allowed_scope: [src/shared/file.md]
assembled_review:
  review_status: pending
fallback:
  used: false
EOF
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Recorded parallel-safe jobs overlap mutable scope: src/shared/** and src/shared/file.md"
rm -rf "$project/.cyberpunk/runs/normalized-alias-overlap"

for invalid_scope in '/absolute/path' 'src/../escape' 'src/*.js' 'src/file?.js' 'src/[ab].js'; do
    write_run_state invalid-scope <<EOF
runtime: codex
execution_mode: sequential
max_concurrent_agents: 1
jobs:
  invalid:
    native_agent: neon
    parallel_safe: false
    allowed_scope: [$invalid_scope]
assembled_review:
  review_status: pending
fallback:
  used: false
EOF
    capture run_cli "$project" validate
    assert_eq 1 "$COMMAND_STATUS"
    assert_contains "$COMMAND_OUTPUT" "Recorded allowed_scope is not a supported project-relative path"
    rm -rf "$project/.cyberpunk/runs/invalid-scope"
done

write_run_state normalized-siblings <<'EOF'
runtime: codex
execution_mode: sequential
max_concurrent_agents: 1
jobs:
  alpha:
    native_agent: neon
    parallel_safe: true
    allowed_scope: [./src//a/**]
  beta:
    native_agent: daemon
    parallel_safe: true
    allowed_scope: [src/b/**]
assembled_review:
  review_status: pending
fallback:
  used: false
EOF
assert_exit 0 run_cli "$project" validate
rm -rf "$project/.cyberpunk/runs/normalized-siblings"

write_run_state parent-fallback-review <<'EOF'
runtime: codex
execution_mode: sequential
max_concurrent_agents: 1
jobs:
  fallback:
    native_agent: null
    agent_instance: null
    parallel_safe: false
    allowed_scope: [src/fallback/**]
    review_agent_instance: null
    review_context: parent
    verification_observed: [bash tests/fallback.bash]
    review_status: approved
    result_commit: fallback456
assembled_review:
  integrated_commit: fallback456
  review_agent_instance: null
  review_context: parent
  verification_observed: [bash tests/assembled.bash]
  review_status: approved
fallback:
  used: true
  category: native_tools_unavailable
  affected_jobs: [all]
EOF
assert_exit 0 run_cli "$project" validate
sed 's/review_context: parent/review_context: stale/' \
    "$project/.cyberpunk/runs/parent-fallback-review/state.yml" > "$project/parent-fallback.tmp"
mv "$project/parent-fallback.tmp" "$project/.cyberpunk/runs/parent-fallback-review/state.yml"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Approved parent-session fallback review requires null identity and parent context"
rm -rf "$project/.cyberpunk/runs/parent-fallback-review"

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
