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
assert_file "$project/agents/nexus.md"
assert_file "$project/agents/daemon.md"
assert_file "$project/agents/neon.md"
assert_file "$project/.cyberpunk/workflow.md"
assert_file "$project/skills/core/worktree-isolation/SKILL.md"
assert_dir "$project/.cyberpunk/runs"
assert_file "$project/.gitignore"
assert_eq 1 "$(line_count ".cyberpunk/runs/" "$project/.gitignore")" "run ignore count"
assert_eq 1 "$(line_count ".worktrees/" "$project/.gitignore")" "worktree ignore count"

test_start "ordinary init preserves user modifications"
echo "user-marker" >> "$project/agents/nexus.md"
assert_exit 0 run_cli "$project" init
assert_contains "$(<"$project/agents/nexus.md")" "user-marker"
assert_eq 1 "$(line_count ".cyberpunk/runs/" "$project/.gitignore")" "idempotent run ignore"
assert_eq 1 "$(line_count ".worktrees/" "$project/.gitignore")" "idempotent worktree ignore"

test_start "force refreshes framework files but preserves custom skills"
mkdir -p "$project/skills/project/custom-review"
printf '%s\n' "custom-skill-content" > "$project/skills/project/custom-review/SKILL.md"
custom_before="$(cksum "$project/skills/project/custom-review/SKILL.md")"
assert_exit 0 run_cli "$project" init --force
assert_not_contains "$(<"$project/agents/nexus.md")" "user-marker"
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

test_start "status reports initialized project counts"
assert_exit 0 run_cli "$project" status
assert_contains "$COMMAND_OUTPUT" "Status: initialized"
assert_contains "$COMMAND_OUTPUT" "Agents: 10"
assert_contains "$COMMAND_OUTPUT" "Core skills: 15"

test_start "version is updated"
assert_exit 0 "$CYBERPUNK_BIN" --version
assert_contains "$COMMAND_OUTPUT" "0.2.0"

echo "PASS: CLI tests"
