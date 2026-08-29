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

write_legacy_config() {
    local destination="$1"
    cat > "$destination" <<'EOF'
version: 1

delivery:
  default: integration-branch
  allow_push: false
  allow_pull_requests: false
  allow_deploy: false

workflow:
  mode: adaptive
  levels: [quick, standard, complex]
  repair_cycles_before_rediagnosis: 2
  unresolved_cycles_before_escalation: 3
  project_workflow_note: preserve-this-workflow-line

git:
  integration_branch: auto
  branch_prefix: cyberpunk/
  worktree_root: .worktrees
  require_worktrees: true
  require_non_overlapping_ownership: true
  allow_internal_commits: true
  merge_worker_branches: true
  allow_protected_branch_merge: false
  cleanup_worktrees_after_integration: true
  cleanup_worker_branches: after-confirmation

memory:
  tracked: [.cyberpunk/project.md, .cyberpunk/memory]
  local: .cyberpunk/runs
  promote_only_validated_lessons: true
  project_memory_note: preserve-this-memory-line

skills:
  core_path: skills/core
  project_path: skills/project
  enabled_project: []

project_owned:
  team_note: preserve-this-project-owned-line
EOF
}

section_text() {
    local config="$1"
    local section="$2"
    awk -v section="$section" '
        $0 == section ":" { printing=1 }
        printing && /^[^[:space:]][^:]*:$/ && $0 != section ":" { exit }
        printing { print }
    ' "$config"
}

test_start "fresh project initializes and validates"
assert_exit 0 run_cli "$project" init
assert_exit 0 run_cli "$project" validate
assert_file "$project/AGENTS.md"
assert_file "$project/CLAUDE.md"
assert_file "$project/.cursor/rules/rules.mdc"
assert_file "$project/agents/fixer.md"
assert_file "$project/skills/core/requirements-discovery/SKILL.md"

test_start "sync migrates a legacy configuration without changing existing policy"
legacy_project="$SANDBOX_ROOT/legacy"
mkdir -p "$legacy_project/.cyberpunk"
write_legacy_config "$legacy_project/.cyberpunk/config.yml"
legacy_delivery_before="$(section_text "$legacy_project/.cyberpunk/config.yml" delivery)"
legacy_workflow_before="$(section_text "$legacy_project/.cyberpunk/config.yml" workflow)"
legacy_git_before="$(section_text "$legacy_project/.cyberpunk/config.yml" git)"
legacy_memory_before="$(section_text "$legacy_project/.cyberpunk/config.yml" memory)"
legacy_skills_before="$(section_text "$legacy_project/.cyberpunk/config.yml" skills)"
legacy_project_owned_before="$(section_text "$legacy_project/.cyberpunk/config.yml" project_owned)"
assert_exit 0 run_cli "$legacy_project" sync
legacy_config="$legacy_project/.cyberpunk/config.yml"
assert_contains "$(<"$legacy_config")" "version: 2"
for value in "runtimes:" "execution:" "models:"; do
    assert_contains "$(<"$legacy_config")" "$value" "legacy migration"
done
assert_eq "$legacy_delivery_before" "$(section_text "$legacy_config" delivery)" "delivery policy changed during migration"
assert_eq "$legacy_workflow_before" "$(section_text "$legacy_config" workflow)" "workflow policy changed during migration"
assert_eq "$legacy_git_before" "$(section_text "$legacy_config" git)" "git policy changed during migration"
assert_eq "$legacy_memory_before" "$(section_text "$legacy_config" memory)" "memory policy changed during migration"
assert_eq "$legacy_skills_before" "$(section_text "$legacy_config" skills)" "skills policy changed during migration"
assert_eq "$legacy_project_owned_before" "$(section_text "$legacy_config" project_owned)" "project-owned policy changed during migration"
legacy_checksum_before="$(cksum "$legacy_config")"
assert_exit 0 run_cli "$legacy_project" sync
legacy_checksum_after="$(cksum "$legacy_config")"
assert_eq "$legacy_checksum_before" "$legacy_checksum_after" "sync migration was not stable"

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

test_start "generated Fixer exposes the committed PRD handoff"
fixer_contract="$(<"$project/agents/fixer.md")$(<"$project/skills/core/requirements-discovery/SKILL.md")$(<"$project/.cyberpunk/workflow.md")"
for value in \
    "requirements-discovery" \
    "specs/YYYY-MM-DD-<topic>-prd.md" \
    "current named branch" \
    "discovery_complete: true" \
    "user_authorized_handoff: true"; do
    assert_contains "$fixer_contract" "$value" "generated Fixer handoff"
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
