#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/test_helper.bash"

SANDBOX_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cyberpunk-integration-test.XXXXXX")"
trap 'rm -rf "$SANDBOX_ROOT"' EXIT
project="$SANDBOX_ROOT/project"
mkdir -p "$project"
git -C "$project" init -q

run_cli() {
    local target="$1"
    shift
    (cd "$target" && "$CYBERPUNK_BIN" "$@")
}

line_count() {
    local value="$1"
    local path="$2"
    grep -Fxc "$value" "$path" || true
}

test_start "fresh project initializes and validates"
assert_exit 0 run_cli "$project" init
assert_exit 0 run_cli "$project" validate
assert_file "$project/AGENTS.md"
assert_file "$project/CLAUDE.md"
assert_file "$project/.cursor/rules/rules.mdc"

test_start "every agent default skill resolves"
for agent_file in "$project"/agents/*.md; do
    [[ "$(basename "$agent_file")" == _* ]] && continue
    while IFS= read -r skill; do
        [[ -n "$skill" ]] || continue
        assert_file "$project/skills/core/$skill/SKILL.md"
    done < <(
        awk '
            /^## Default Skills/ { in_skills=1; next }
            /^## / { in_skills=0 }
            in_skills && /^- `/ {
                value=$0
                sub(/^- `/, "", value)
                sub(/`$/, "", value)
                print value
            }
        ' "$agent_file"
    )
done

test_start "local run and worktree paths are ignored"
git -C "$project" check-ignore -q .cyberpunk/runs/example
git -C "$project" check-ignore -q .worktrees/example

test_start "force refresh preserves user-owned project skills"
mkdir -p "$project/skills/project/release-policy"
printf '%s\n' "project-owned" > "$project/skills/project/release-policy/SKILL.md"
before_checksum="$(cksum "$project/skills/project/release-policy/SKILL.md")"
assert_exit 0 run_cli "$project" init --force
after_checksum="$(cksum "$project/skills/project/release-policy/SKILL.md")"
assert_eq "$before_checksum" "$after_checksum" "project skill changed during force refresh"

test_start "reinitialization is idempotent"
assert_exit 0 run_cli "$project" init
assert_eq 1 "$(line_count ".cyberpunk/runs/" "$project/.gitignore")" "run ignore count"
assert_eq 1 "$(line_count ".worktrees/" "$project/.gitignore")" "worktree ignore count"

test_start "status is read-only"
status_before="$(git -C "$project" status --porcelain)"
assert_exit 0 run_cli "$project" status
status_after="$(git -C "$project" status --porcelain)"
assert_eq "$status_before" "$status_after" "status changed the project"

test_start "generated policy defines safe job integration"
policy="$(<"$project/.cyberpunk/config.yml")$(<"$project/.cyberpunk/workflow.md")"
for value in \
    "default: integration-branch" \
    "require_worktrees: true" \
    "allow_internal_commits: true" \
    "allow_protected_branch_merge: false" \
    "worker branch" \
    "Gatekeeper" \
    "dependency order" \
    "assembled verification" \
    "cleanup"; do
    assert_contains "$policy" "$value" "integration policy"
done

test_start "validate rejects unsafe protected-branch policy"
sed 's/allow_protected_branch_merge: false/allow_protected_branch_merge: true/' \
    "$project/.cyberpunk/config.yml" > "$project/.cyberpunk/config.yml.tmp"
mv "$project/.cyberpunk/config.yml.tmp" "$project/.cyberpunk/config.yml"
capture run_cli "$project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "protected branch"

echo "PASS: integration tests"
