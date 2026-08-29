#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/test_helper.bash"

SANDBOX_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cyberpunk-cli-test.XXXXXX")"
trap 'rm -rf "$SANDBOX_ROOT"' EXIT

run_cli() {
    local project="$1"
    shift
    (cd "$project" && "$CYBERPUNK_BIN" "$@")
}

line_count() {
    local value="$1"
    local path="$2"
    grep -Fxc "$value" "$path" || true
}

test_start "dry run reports changes without writing"
dry_project="$SANDBOX_ROOT/dry"
mkdir -p "$dry_project"
capture run_cli "$dry_project" init --dry-run
assert_eq 0 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "DRY RUN"
[[ ! -e "$dry_project/agents" ]] || fail "dry run created agents"
[[ ! -e "$dry_project/.gitignore" ]] || fail "dry run created .gitignore"

test_start "init copies the complete team and local-state structure"
project="$SANDBOX_ROOT/project"
mkdir -p "$project"
assert_exit 0 run_cli "$project" init
assert_contains "$(<"$project/.cyberpunk/config.yml")" "enabled: [codex, claude, cursor]"
assert_file "$project/agents/nexus.md"
assert_file "$project/agents/fixer.md"
assert_file "$project/agents/daemon.md"
assert_file "$project/agents/neon.md"
assert_file "$project/.cyberpunk/workflow.md"
assert_file "$project/skills/core/worktree-isolation/SKILL.md"
assert_file "$project/skills/core/requirements-discovery/SKILL.md"
assert_dir "$project/.cyberpunk/runs"
assert_file "$project/.gitignore"
assert_eq 1 "$(line_count ".cyberpunk/runs/" "$project/.gitignore")" "run ignore count"
assert_eq 1 "$(line_count ".worktrees/" "$project/.gitignore")" "worktree ignore count"

test_start "init selects one requested runtime"
codex_project="$SANDBOX_ROOT/codex"
mkdir -p "$codex_project"
assert_exit 0 run_cli "$codex_project" init --runtime codex
assert_contains "$(<"$codex_project/.cyberpunk/config.yml")" "enabled: [codex]"

test_start "plain init restores all runtimes after limited initialization"
assert_exit 0 run_cli "$codex_project" init
assert_contains "$(<"$codex_project/.cyberpunk/config.yml")" "enabled: [codex, claude, cursor]"

test_start "init normalizes repeated runtime selections"
multi_project="$SANDBOX_ROOT/multi"
mkdir -p "$multi_project"
assert_exit 0 run_cli "$multi_project" init --runtime cursor --runtime codex --runtime cursor
assert_contains "$(<"$multi_project/.cyberpunk/config.yml")" "enabled: [codex, cursor]"

test_start "init rejects unknown runtimes before writing project files"
invalid_project="$SANDBOX_ROOT/invalid"
mkdir -p "$invalid_project"
capture run_cli "$invalid_project" init --runtime warp
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Unknown runtime: warp"
[[ ! -e "$invalid_project/.cyberpunk" ]] || fail "invalid runtime wrote project files"

test_start "ordinary init preserves user modifications"
echo "user-marker" >> "$project/agents/nexus.md"
echo "fixer-user-marker" >> "$project/agents/fixer.md"
echo "discovery-user-marker" >> "$project/skills/core/requirements-discovery/SKILL.md"
assert_exit 0 run_cli "$project" init
assert_contains "$(<"$project/agents/nexus.md")" "user-marker"
assert_contains "$(<"$project/agents/fixer.md")" "fixer-user-marker"
assert_contains "$(<"$project/skills/core/requirements-discovery/SKILL.md")" "discovery-user-marker"
assert_eq 1 "$(line_count ".cyberpunk/runs/" "$project/.gitignore")" "idempotent run ignore"
assert_eq 1 "$(line_count ".worktrees/" "$project/.gitignore")" "idempotent worktree ignore"

test_start "force refreshes framework files but preserves custom skills"
mkdir -p "$project/skills/project/custom-review"
printf '%s\n' "custom-skill-content" > "$project/skills/project/custom-review/SKILL.md"
custom_before="$(cksum "$project/skills/project/custom-review/SKILL.md")"
assert_exit 0 run_cli "$project" init --force
assert_not_contains "$(<"$project/agents/nexus.md")" "user-marker"
assert_not_contains "$(<"$project/agents/fixer.md")" "fixer-user-marker"
assert_not_contains "$(<"$project/skills/core/requirements-discovery/SKILL.md")" "discovery-user-marker"
custom_after="$(cksum "$project/skills/project/custom-review/SKILL.md")"
assert_eq "$custom_before" "$custom_after" "custom skill checksum"

test_start "validate accepts a complete scaffold"
assert_exit 0 run_cli "$project" validate
assert_contains "$COMMAND_OUTPUT" "Validation passed"

test_start "validate identifies a missing canonical file"
rm "$project/.cyberpunk/workflow.md"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" ".cyberpunk/workflow.md"
assert_exit 0 run_cli "$project" init --force

test_start "validate identifies a missing Fixer persona"
rm "$project/agents/fixer.md"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "agents/fixer.md"
assert_exit 0 run_cli "$project" init --force

test_start "validate identifies a missing requirements-discovery skill"
rm "$project/skills/core/requirements-discovery/SKILL.md"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "skills/core/requirements-discovery/SKILL.md"
assert_exit 0 run_cli "$project" init --force

test_start "status reports initialized project counts"
assert_exit 0 run_cli "$project" status
assert_contains "$COMMAND_OUTPUT" "Status: initialized"
assert_contains "$COMMAND_OUTPUT" "Agents: 11"
assert_contains "$COMMAND_OUTPUT" "Core skills: 16"

test_start "version is updated"
assert_exit 0 "$CYBERPUNK_BIN" --version
assert_contains "$COMMAND_OUTPUT" "0.3.0"

echo "PASS: CLI tests"
