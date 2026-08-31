#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/test_helper.bash"

SANDBOX_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cyberpunk-runtime-adapter-test.XXXXXX")"
trap 'rm -rf "$SANDBOX_ROOT"' EXIT

roles=(nexus fixer operator mind interrogator fragmenter coder daemon neon grid-master gatekeeper)
runtimes=(codex claude cursor)

run_cli() {
    local project="$1"
    shift
    (cd "$project" && "$CYBERPUNK_BIN" "$@")
}

run_cli_with_path() {
    local project="$1"
    local path_prefix="$2"
    shift 2
    (cd "$project" && PATH="$path_prefix:$PATH" "$CYBERPUNK_BIN" "$@")
}

make_post_commit_signal_wrapper() {
    local wrapper_dir="$1"

    mkdir -p "$wrapper_dir"
    cat > "$wrapper_dir/rm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
for argument in "$@"; do
    case "$argument" in
        */.*.rollback.*/original)
            kill -TERM "$PPID"
            break
            ;;
    esac
done
exec /bin/rm "$@"
EOF
    chmod +x "$wrapper_dir/rm"
}

make_staging_race_wrapper() {
    local wrapper_dir="$1"

    mkdir -p "$wrapper_dir"
    cat > "$wrapper_dir/sort" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
/usr/bin/sort "$@"
for argument in "$@"; do
    case "$argument" in
        */staged.tsv)
            mkdir -p "$(dirname "$CYBERPUNK_RACE_TARGET")"
            case "$CYBERPUNK_RACE_ACTION" in
                create) printf '%s\n' "$CYBERPUNK_RACE_VALUE" > "$CYBERPUNK_RACE_TARGET" ;;
                append) printf '%s\n' "$CYBERPUNK_RACE_VALUE" >> "$CYBERPUNK_RACE_TARGET" ;;
                *) exit 64 ;;
            esac
            ;;
    esac
done
EOF
    chmod +x "$wrapper_dir/sort"
}

make_restore_failure_wrapper() {
    local wrapper_dir="$1"

    mkdir -p "$wrapper_dir"
    cat > "$wrapper_dir/ln" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
source_path=""
for argument in "$@"; do
    case "$argument" in
        -*) continue ;;
        *) source_path="$argument"; break ;;
    esac
done
case "$source_path" in
    */.*.rollback.*/original) exit 73 ;;
esac
exec /bin/ln "$@"
EOF
    chmod +x "$wrapper_dir/ln"
}

make_post_check_absent_wrapper() {
    local wrapper_dir="$1"

    mkdir -p "$wrapper_dir"
    cat > "$wrapper_dir/mktemp" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
temporary="$(/usr/bin/mktemp "$@")"
printf '%s\n' "$temporary"
target_name="$(basename "$CYBERPUNK_POSTCHECK_TARGET")"
case "$(basename "$temporary")" in
    ".$target_name.tmp."*)
        temporary_dir="$(cd "$(dirname "$temporary")" && pwd -P)"
        target_dir="$(cd "$(dirname "$CYBERPUNK_POSTCHECK_TARGET")" && pwd -P)"
        if [[ "$temporary_dir" == "$target_dir" ]]; then
            printf '%s\n' 'post-check-user-collision' > "$CYBERPUNK_POSTCHECK_TARGET"
        fi
        ;;
esac
EOF
    chmod +x "$wrapper_dir/mktemp"
}

make_post_check_present_wrapper() {
    local wrapper_dir="$1"

    mkdir -p "$wrapper_dir"
    cat > "$wrapper_dir/cp" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
source_path=""
for argument in "$@"; do
    case "$argument" in
        -*) continue ;;
        *) source_path="$argument"; break ;;
    esac
done
/bin/cp "$@"
absolute_source="$(cd "$(dirname "$source_path")" && pwd -P)/$(basename "$source_path")"
absolute_target="$(cd "$(dirname "$CYBERPUNK_POSTCHECK_TARGET")" && pwd -P)/$(basename "$CYBERPUNK_POSTCHECK_TARGET")"
if [[ "$absolute_source" == "$absolute_target" ]]; then
    printf '%s\n' 'post-check-user-drift' >> "$CYBERPUNK_POSTCHECK_TARGET"
fi
EOF
    cat > "$wrapper_dir/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
source_path=""
for argument in "$@"; do
    case "$argument" in
        -*) continue ;;
        *) source_path="$argument"; break ;;
    esac
done
absolute_source="$(cd "$(dirname "$source_path")" && pwd -P)/$(basename "$source_path")"
absolute_target="$(cd "$(dirname "$CYBERPUNK_POSTCHECK_TARGET")" && pwd -P)/$(basename "$CYBERPUNK_POSTCHECK_TARGET")"
if [[ "$absolute_source" == "$absolute_target" ]]; then
    printf '%s\n' 'post-check-user-drift' >> "$CYBERPUNK_POSTCHECK_TARGET"
fi
exec /bin/mv "$@"
EOF
    chmod +x "$wrapper_dir/cp" "$wrapper_dir/mv"
}

make_installed_edit_then_failure_wrapper() {
    local wrapper_dir="$1"

    mkdir -p "$wrapper_dir"
    cat > "$wrapper_dir/ln" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
destination_path=""
for argument in "$@"; do
    case "$argument" in
        -*) continue ;;
        *) destination_path="$argument" ;;
    esac
done
absolute_destination="$(cd "$(dirname "$destination_path")" && pwd -P)/$(basename "$destination_path")"
absolute_failure_target="$(cd "$(dirname "$CYBERPUNK_ROLLBACK_FAILURE_TARGET")" && pwd -P)/$(basename "$CYBERPUNK_ROLLBACK_FAILURE_TARGET")"
if [[ "$absolute_destination" == "$absolute_failure_target" && ! -e "$CYBERPUNK_ROLLBACK_HOOK_MARKER" ]]; then
    printf '%s\n' 'rollback-user-edit' >> "$CYBERPUNK_ROLLBACK_EDIT_TARGET"
    /bin/cp "$CYBERPUNK_ROLLBACK_EDIT_TARGET" "$CYBERPUNK_ROLLBACK_EDIT_WITNESS"
    : > "$CYBERPUNK_ROLLBACK_HOOK_MARKER"
    exit 73
fi
exec /bin/ln "$@"
EOF
    chmod +x "$wrapper_dir/ln"
}

run_cli_with_target_hook() {
    local project="$1"
    local path_prefix="$2"
    local target="$3"
    shift 3
    (
        cd "$project"
        CYBERPUNK_POSTCHECK_TARGET="$target" \
        PATH="$path_prefix:$PATH" \
            "$CYBERPUNK_BIN" "$@"
    )
}

run_cli_with_installed_edit_then_failure() {
    local project="$1"
    local path_prefix="$2"
    local edit_target="$3"
    local failure_target="$4"
    local hook_marker="$5"
    local edit_witness="$6"
    shift 6
    (
        cd "$project"
        CYBERPUNK_ROLLBACK_EDIT_TARGET="$edit_target" \
        CYBERPUNK_ROLLBACK_FAILURE_TARGET="$failure_target" \
        CYBERPUNK_ROLLBACK_HOOK_MARKER="$hook_marker" \
        CYBERPUNK_ROLLBACK_EDIT_WITNESS="$edit_witness" \
        PATH="$path_prefix:$PATH" \
            "$CYBERPUNK_BIN" "$@"
    )
}

run_cli_with_race() {
    local project="$1"
    local path_prefix="$2"
    local target="$3"
    local action="$4"
    local value="$5"
    shift 5
    (
        cd "$project"
        CYBERPUNK_RACE_TARGET="$target" \
        CYBERPUNK_RACE_ACTION="$action" \
        CYBERPUNK_RACE_VALUE="$value" \
        PATH="$path_prefix:$PATH" \
            "$CYBERPUNK_BIN" "$@"
    )
}

assert_not_path() {
    local path="$1"
    [[ ! -e "$path" && ! -L "$path" ]] || fail "unexpected path: $path"
}

role_description_fixture() {
    case "$1" in
        nexus) printf '%s\n' "Parent engineering coordinator for complete Cyberpunk task delivery" ;;
        fixer) printf '%s\n' "Product requirements discovery for unresolved product or feature decisions" ;;
        operator) printf '%s\n' "Read-only repository discovery and verification-command mapping" ;;
        mind) printf '%s\n' "Architecture and implementation planning from approved requirements" ;;
        interrogator) printf '%s\n' "Adversarial review of complex implementation plans" ;;
        fragmenter) printf '%s\n' "Dependency-aware work decomposition and safe ownership boundaries" ;;
        coder) printf '%s\n' "General scoped implementation following an approved work packet" ;;
        daemon) printf '%s\n' "Backend, API, persistence, and domain-logic implementation" ;;
        neon) printf '%s\n' "Frontend, interaction, accessibility, and responsive implementation" ;;
        grid-master) printf '%s\n' "Platform, automation, observability, and operational implementation" ;;
        gatekeeper) printf '%s\n' "Fresh-context review of a result commit or assembled change" ;;
        *) fail "unknown role fixture: $1" ;;
    esac
}

role_model_fixture() {
    local role="$1"
    local runtime="$2"
    local profile

    case "$role" in
        nexus|fixer|mind|interrogator|gatekeeper) profile=deep ;;
        operator) profile=fast ;;
        fragmenter|coder|daemon|neon|grid-master) profile=balanced ;;
        *) fail "unknown model role fixture: $role" ;;
    esac

    case "$profile:$runtime" in
        deep:codex|deep:cursor) printf '%s\n' "gpt-5.6-sol" ;;
        deep:claude) printf '%s\n' "opus" ;;
        balanced:codex) printf '%s\n' "gpt-5.6-terra" ;;
        balanced:claude) printf '%s\n' "sonnet" ;;
        balanced:cursor) printf '%s\n' "composer-2.5[]" ;;
        fast:codex) printf '%s\n' "gpt-5.6-luna" ;;
        fast:claude) printf '%s\n' "haiku" ;;
        fast:cursor) printf '%s\n' "composer-2.5" ;;
        *) fail "unknown model fixture: $profile:$runtime" ;;
    esac
}

native_path() {
    local project="$1"
    local runtime="$2"
    local role="$3"

    case "$runtime" in
        codex) printf '%s\n' "$project/.codex/agents/$role.toml" ;;
        claude) printf '%s\n' "$project/.claude/agents/$role.md" ;;
        cursor) printf '%s\n' "$project/.cursor/agents/$role.md" ;;
        *) fail "unknown native runtime fixture: $runtime" ;;
    esac
}

native_skill_path() {
    local project="$1"
    local runtime="$2"
    local skill="$3"

    case "$runtime" in
        codex) printf '%s\n' "$project/.agents/skills/$skill/SKILL.md" ;;
        claude) printf '%s\n' "$project/.claude/skills/$skill/SKILL.md" ;;
        cursor) printf '%s\n' "$project/.cursor/skills/$skill/SKILL.md" ;;
        *) fail "unknown native skill runtime fixture: $runtime" ;;
    esac
}

canonical_skill_field() {
    local path="$1"
    local field="$2"

    awk -v field="$field" '
        $0 == "---" { delimiters += 1; next }
        delimiters == 1 && index($0, field ": ") == 1 {
            print substr($0, length(field) + 3)
            exit
        }
    ' "$path"
}

parse_markdown_skill_string() {
    local path="$1"
    local field="$2"

    ruby -rpsych -e '
        content = File.binread(ARGV.fetch(0))
        match = content.match(/\A<!-- Generated by Cyberpunk[^\n]* -->\n---\n(.*?)\n---\n\n/m)
        abort "invalid native skill envelope" unless match
        metadata = Psych.safe_load(match[1], [], [], false)
        value = metadata.fetch(ARGV.fetch(1))
        abort "native skill metadata was not a string" unless value.is_a?(String)
        print value
    ' "$path" "$field"
}

replace_enabled_project_skills() {
    local path="$1"
    local value="$2"
    local temporary="$path.tmp"

    awk -v value="$value" '
        $0 == "  enabled_project: []" {
            print "  enabled_project: " value
            replaced=1
            next
        }
        { print }
        END { if (!replaced) exit 1 }
    ' "$path" > "$temporary"
    mv "$temporary" "$path"
}

set_enabled_project_skills() {
    local path="$1"
    local replacement="$2"
    local temporary="$path.tmp"
    local replacement_file
    local awk_status

    replacement_file="$(mktemp "${TMPDIR:-/tmp}/cyberpunk-runtime-adapter-replacement.XXXXXX")"
    printf '%s' "$replacement" > "$replacement_file"

    if awk -v replacement_file="$replacement_file" '
        BEGIN {
            replacement_line_count=0
            while ((getline replacement_line < replacement_file) > 0) {
                if (replacement_line_count == 0) {
                    replacement_text=replacement_line
                } else {
                    replacement_text=replacement_text "\n" replacement_line
                }
                replacement_line_count++
            }
            close(replacement_file)
        }
        $0 ~ /^  enabled_project:/ {
            print "  enabled_project: " replacement_text
            replaced=1
            if ($0 == "  enabled_project:") skip_list=1
            next
        }
        skip_list && /^    -[[:space:]]*/ { next }
        skip_list { skip_list=0 }
        { print }
        END { if (!replaced) exit 1 }
    ' "$path" > "$temporary"; then
        awk_status=0
    else
        awk_status=$?
    fi
    rm -f "$replacement_file"
    [[ "$awk_status" -eq 0 ]] || return "$awk_status"
    mv "$temporary" "$path"
}

replace_exact_line() {
    local path="$1"
    local before="$2"
    local after="$3"
    local temporary="$path.tmp"

    awk -v before="$before" -v after="$after" '
        $0 == before { print after; replaced=1; next }
        { print }
        END { if (!replaced) exit 1 }
    ' "$path" > "$temporary"
    mv "$temporary" "$path"
}

remove_exact_line() {
    local path="$1"
    local removed="$2"
    local temporary="$path.tmp"

    awk -v removed="$removed" '
        $0 == removed { found=1; next }
        { print }
        END { if (!found) exit 1 }
    ' "$path" > "$temporary"
    mv "$temporary" "$path"
}

replace_override_block() {
    local path="$1"
    local fixture="$2"
    local temporary="$path.tmp"

    awk -v fixture="$fixture" '
        $0 == "  overrides: {}" {
            print "  overrides:"
            if (fixture == "precedence") {
                print "    fixer:"
                print "      profile: fast"
                print "      claude: \"runtime-claude\""
                print "    gatekeeper:"
                print "      cursor: \"inherit\""
            } else if (fixture == "invalid") {
                print "    fixer:"
                print "      profile: extreme"
            } else {
                exit 1
            }
            replaced=1
            next
        }
        { print }
        END { if (!replaced) exit 1 }
    ' "$path" > "$temporary"
    mv "$temporary" "$path"
}

replace_override_with_model() {
    local path="$1"
    local runtime="$2"
    local raw_model="$3"
    local temporary="$path.tmp"

    local line
    local replaced=false
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == '  overrides: {}' ]]; then
            printf '%s\n' '  overrides:' '    fixer:' "      $runtime: $raw_model" >> "$temporary"
            replaced=true
        else
            printf '%s\n' "$line" >> "$temporary"
        fi
    done < "$path"
    [[ "$replaced" == true ]] || return 1
    mv "$temporary" "$path"
}

parse_codex_model() {
    local path="$1"

    ruby -e '
        lines = File.readlines(ARGV.fetch(0), chomp: true)
        model_lines = lines.grep(/^model = /)
        abort "expected exactly one TOML model key" unless model_lines.length == 1
        raw = model_lines.first.sub(/^model = /, "")
        abort "invalid TOML basic string" unless raw.match?(/\A"(?:[^"\\\x00-\x1f]|\\["\\])*"\z/)
        value = raw[1...-1].gsub(/\\(["\\])/, "\\1")
        abort "TOML model did not parse as a string" unless value.is_a?(String)
        print value
    ' "$path"
}

parse_markdown_model() {
    local path="$1"

    ruby -rpsych -e '
        content = File.binread(ARGV.fetch(0))
        match = content.match(/\A<!-- Generated by Cyberpunk[^\n]* -->\n---\n(.*?)\n---\n\n/m)
        abort "invalid native Markdown envelope" unless match
        metadata = Psych.safe_load(match[1], [], [], false)
        abort "native metadata must be a mapping" unless metadata.is_a?(Hash)
        abort "unexpected native metadata keys" unless metadata.keys.sort == %w[description model name]
        abort "native metadata values must be strings" unless metadata.values.all? { |value| value.is_a?(String) }
        print metadata.fetch("model")
    ' "$path"
}

test_start "all enabled runtimes receive the complete native agent matrix"
project="$SANDBOX_ROOT/all"
mkdir -p "$project"
assert_exit 0 run_cli "$project" init
for role in "${roles[@]}"; do
    description="$(role_description_fixture "$role")"
    for runtime in "${runtimes[@]}"; do
        path="$(native_path "$project" "$runtime" "$role")"
        model="$(role_model_fixture "$role" "$runtime")"
        assert_file "$path"
        content="$(<"$path")"
        if [[ "$runtime" == codex ]]; then
            assert_contains "$content" "name = \"$role\"" "$runtime $role identifier"
            assert_contains "$content" "description = \"$description\"" "$runtime $role description"
            assert_contains "$content" "model = \"$model\"" "$runtime $role model"
            assert_contains "$content" 'developer_instructions = """' "$runtime $role instructions"
        else
            assert_contains "$content" "name: \"$role\"" "$runtime $role identifier"
            assert_contains "$content" "description: \"$description\"" "$runtime $role description"
            assert_contains "$content" "model: \"$model\"" "$runtime $role model"
        fi
        assert_contains "$content" '.cyberpunk/workflow.md' "$runtime $role workflow pointer"
        assert_contains "$content" 'agents/_common-principles.md' "$runtime $role common-principles pointer"
        assert_contains "$content" "agents/$role.md" "$runtime $role role pointer"
        assert_contains "$content" 'assigned work packet' "$runtime $role work-packet pointer"
        assert_contains "$content" 'every required skill' "$runtime $role required-skills pointer"
        if [[ "$role" == nexus ]]; then
            assert_contains "$content" 'parent and sole Cyberpunk dispatcher' "$runtime Nexus dispatcher boundary"
            assert_contains "$content" 'Never ask a' "$runtime Nexus nesting boundary"
            assert_contains "$content" 'subagent to create sibling or nested Cyberpunk agents.' "$runtime Nexus nesting boundary"
        else
            assert_contains "$content" 'Do not spawn, delegate, or coordinate sibling or nested Cyberpunk agents.' "$runtime $role nesting boundary"
            assert_not_contains "$content" 'parent and sole Cyberpunk dispatcher' "$runtime $role must not dispatch"
        fi
    done
done
assert_eq 33 "$(grep -Fc '    kind: "agent"' "$project/.cyberpunk/generated.yml")" "all-runtime agent manifest count"

test_start "all enabled runtimes receive thin wrappers for every canonical core skill"
core_skill_paths=()
while IFS= read -r core_skill_path; do
    core_skill_paths+=("$core_skill_path")
done < <(find "$project/skills/core" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | LC_ALL=C sort)
assert_eq 16 "${#core_skill_paths[@]}" "canonical core skill fixture count"
for runtime in "${runtimes[@]}"; do
    native_skill_root="$(dirname "$(dirname "$(native_skill_path "$project" "$runtime" placeholder)")")"
    native_skill_count=0
    if [[ -d "$native_skill_root" ]]; then
        native_skill_count="$(find "$native_skill_root" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | wc -l | tr -d ' ')"
    fi
    assert_eq "${#core_skill_paths[@]}" "$native_skill_count" "$runtime native core skill count"
done
for core_skill_path in "${core_skill_paths[@]}"; do
    core_skill="$(canonical_skill_field "$core_skill_path" name)"
    core_description="$(canonical_skill_field "$core_skill_path" description)"
    for runtime in "${runtimes[@]}"; do
        wrapper_path="$(native_skill_path "$project" "$runtime" "$core_skill")"
        wrapper="$(<"$wrapper_path")"
        assert_contains "$wrapper" "name: \"$core_skill\"" "$runtime $core_skill wrapper name"
        assert_contains "$wrapper" "description: \"$core_description\"" "$runtime $core_skill wrapper description"
        assert_contains "$wrapper" "../../../skills/core/$core_skill/SKILL.md" "$runtime $core_skill canonical pointer"
        assert_contains "$wrapper" "completely and follow it" "$runtime $core_skill pointer instruction"
        assert_contains "$wrapper" "relative to that canonical skill directory" "$runtime $core_skill resolution instruction"
        assert_not_contains "$wrapper" "## Procedure" "$runtime $core_skill wrapper must not copy canonical body"
    done
done
assert_eq 48 "$(grep -Fc '    kind: "skill"' "$project/.cyberpunk/generated.yml")" "all-runtime core skill manifest count"

test_start "sync registers only explicitly enabled project skills in every selected runtime"
project_skills_project="$SANDBOX_ROOT/project-skills"
mkdir -p "$project_skills_project"
assert_exit 0 run_cli "$project_skills_project" init
mkdir -p "$project_skills_project/skills/project/release-policy" "$project_skills_project/skills/project/unlisted"
printf '%s\n' \
    '---' \
    'name: release-policy' \
    'description: Use when a release needs explicit approval and rollback policy.' \
    '---' \
    '' \
    '## Procedure' \
    'Project-owned policy body.' > "$project_skills_project/skills/project/release-policy/SKILL.md"
printf '%s\n' \
    '---' \
    'name: unlisted' \
    'description: Use when an unlisted policy is requested.' \
    '---' \
    '' \
    '## Procedure' \
    'Unlisted project body.' > "$project_skills_project/skills/project/unlisted/SKILL.md"
replace_enabled_project_skills "$project_skills_project/.cyberpunk/config.yml" '[release-policy]'
project_skill_before="$(cksum "$project_skills_project/skills/project/release-policy/SKILL.md")"
assert_exit 0 run_cli "$project_skills_project" sync
for runtime in "${runtimes[@]}"; do
    project_wrapper_path="$(native_skill_path "$project_skills_project" "$runtime" release-policy)"
    assert_file "$project_wrapper_path"
    project_wrapper="$(<"$project_wrapper_path")"
    assert_contains "$project_wrapper" 'name: "release-policy"' "$runtime project skill wrapper name"
    assert_contains "$project_wrapper" 'description: "Use when a release needs explicit approval and rollback policy."' "$runtime project skill wrapper description"
    assert_contains "$project_wrapper" '../../../skills/project/release-policy/SKILL.md' "$runtime project skill canonical pointer"
    assert_not_path "$(native_skill_path "$project_skills_project" "$runtime" unlisted)"
done
assert_eq "$project_skill_before" "$(cksum "$project_skills_project/skills/project/release-policy/SKILL.md")" "project canonical skill changed during sync"
assert_exit 0 run_cli "$project_skills_project" sync --force
assert_eq "$project_skill_before" "$(cksum "$project_skills_project/skills/project/release-policy/SKILL.md")" "project canonical skill changed during forced sync"

test_start "disabled project skills retire owned wrappers and manifest records without touching unrelated assets"
release_wrapper_codex="$(native_skill_path "$project_skills_project" codex release-policy)"
release_wrapper_claude="$(native_skill_path "$project_skills_project" claude release-policy)"
release_wrapper_cursor="$(native_skill_path "$project_skills_project" cursor release-policy)"
printf '%s\n' 'local-disabled-skill-edit' >> "$release_wrapper_codex"
set_enabled_project_skills "$project_skills_project/.cyberpunk/config.yml" '[]'
release_manifest_before_retirement="$(cksum "$project_skills_project/.cyberpunk/generated.yml")"
capture run_cli "$project_skills_project" sync
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" 'drift' "disabled drifted project skill must not be deleted without force"
assert_contains "$(<"$release_wrapper_codex")" 'local-disabled-skill-edit' "disabled drifted wrapper changed without force"
assert_eq "$release_manifest_before_retirement" "$(cksum "$project_skills_project/.cyberpunk/generated.yml")" "disabled drift changed the manifest without force"
assert_exit 0 run_cli "$project_skills_project" sync --force
for release_wrapper in "$release_wrapper_codex" "$release_wrapper_claude" "$release_wrapper_cursor"; do
    assert_not_path "$release_wrapper"
done
assert_not_contains "$(<"$project_skills_project/.cyberpunk/generated.yml")" 'skills/project/release-policy/SKILL.md' "disabled project skill manifest record remained"
assert_file "$(native_skill_path "$project_skills_project" codex task-decomposition)"
assert_file "$project_skills_project/.codex/agents/nexus.toml"
mkdir -p "$(dirname "$release_wrapper_codex")"
printf '%s\n' 'unowned-disabled-skill-wrapper' > "$release_wrapper_codex"
assert_exit 0 run_cli "$project_skills_project" sync
assert_eq 'unowned-disabled-skill-wrapper' "$(<"$release_wrapper_codex")" "disabled unowned wrapper was changed"
assert_not_contains "$(<"$project_skills_project/.cyberpunk/generated.yml")" 'skills/project/release-policy/SKILL.md' "unowned disabled wrapper gained a manifest record"

test_start "project skill configuration normalizes inline and block lists lexically"
ordering_project="$SANDBOX_ROOT/project-skill-ordering"
mkdir -p "$ordering_project"
assert_exit 0 run_cli "$ordering_project" init --runtime codex
for ordered_skill in alpha-policy zeta-policy; do
    mkdir -p "$ordering_project/skills/project/$ordered_skill"
    printf '%s\n' '---' "name: $ordered_skill" "description: Use when $ordered_skill is enabled." '---' > "$ordering_project/skills/project/$ordered_skill/SKILL.md"
done
set_enabled_project_skills "$ordering_project/.cyberpunk/config.yml" '[zeta-policy, alpha-policy, zeta-policy]'
assert_exit 0 run_cli "$ordering_project" sync
assert_file "$(native_skill_path "$ordering_project" codex alpha-policy)"
assert_file "$(native_skill_path "$ordering_project" codex zeta-policy)"
ordered_sources="$(awk -F '"' '/source: "skills\/project\// { print $2 }' "$ordering_project/.cyberpunk/generated.yml")"
assert_eq $'skills/project/alpha-policy/SKILL.md\nskills/project/zeta-policy/SKILL.md' "$ordered_sources" "inline project skill list was not lexical and unique"
set_enabled_project_skills "$ordering_project/.cyberpunk/config.yml" $'\n    - zeta-policy\n    - alpha-policy'
assert_exit 0 run_cli "$ordering_project" sync --force
ordered_sources="$(awk -F '"' '/source: "skills\/project\// { print $2 }' "$ordering_project/.cyberpunk/generated.yml")"
assert_eq $'skills/project/alpha-policy/SKILL.md\nskills/project/zeta-policy/SKILL.md' "$ordered_sources" "block project skill list was not lexical"

test_start "project skill discovery rejects traversal and non-string frontmatter before writes"
traversal_project="$SANDBOX_ROOT/project-skill-traversal"
mkdir -p "$traversal_project"
assert_exit 0 run_cli "$traversal_project" init --runtime codex
mkdir -p "$traversal_project/skills/escape"
printf '%s\n' '---' 'name: escape' 'description: Use when traversal is attempted.' '---' > "$traversal_project/skills/escape/SKILL.md"
set_enabled_project_skills "$traversal_project/.cyberpunk/config.yml" '[../escape]'
capture run_cli "$traversal_project" sync
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" '../escape' "project traversal identifier error"
assert_not_path "$(native_skill_path "$traversal_project" codex escape)"

outside_skill_root="$SANDBOX_ROOT/outside-project-skill"
mkdir -p "$outside_skill_root/escaped-directory"
printf '%s\n' '---' 'name: symlink-directory' 'description: Use when directory symlinks escape.' '---' > "$outside_skill_root/escaped-directory/SKILL.md"
ln -s "$outside_skill_root/escaped-directory" "$traversal_project/skills/project/symlink-directory"
set_enabled_project_skills "$traversal_project/.cyberpunk/config.yml" '[symlink-directory]'
capture run_cli "$traversal_project" sync
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" 'outside skills/project' "project symlink-directory error"
assert_not_path "$(native_skill_path "$traversal_project" codex symlink-directory)"

mkdir -p "$traversal_project/skills/project/symlink-file"
printf '%s\n' '---' 'name: symlink-file' 'description: Use when file symlinks escape.' '---' > "$outside_skill_root/escaped-file.md"
ln -s "$outside_skill_root/escaped-file.md" "$traversal_project/skills/project/symlink-file/SKILL.md"
set_enabled_project_skills "$traversal_project/.cyberpunk/config.yml" '[symlink-file]'
capture run_cli "$traversal_project" sync
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" 'outside skills/project' "project symlink-file error"
assert_not_path "$(native_skill_path "$traversal_project" codex symlink-file)"

metadata_project="$SANDBOX_ROOT/project-skill-metadata"
mkdir -p "$metadata_project"
assert_exit 0 run_cli "$metadata_project" init --runtime codex
mkdir -p "$metadata_project/skills/project/release-policy"
set_enabled_project_skills "$metadata_project/.cyberpunk/config.yml" '[release-policy]'
malformed_metadata_names=(missing-whitespace block collection alias tag comment boolean infinity nan exponent timestamp)
malformed_metadata_values=(
    $'name:release-policy\ndescription: Use when metadata is malformed.'
    $'name: release-policy\ndescription: |'
    $'name: release-policy\ndescription: [not, a, string]'
    $'name: *shared\ndescription: Use when metadata is malformed.'
    $'name: !release-policy\ndescription: Use when metadata is malformed.'
    $'name: release-policy\ndescription: Use when comments # truncate metadata.'
    $'name: release-policy\ndescription: true'
    $'name: release-policy\ndescription: .inf'
    $'name: release-policy\ndescription: .NaN'
    $'name: release-policy\ndescription: 1e9'
    $'name: release-policy\ndescription: 2026-08-30'
)
for metadata_index in "${!malformed_metadata_names[@]}"; do
    printf '%s\n' '---' "${malformed_metadata_values[$metadata_index]}" '---' > "$metadata_project/skills/project/release-policy/SKILL.md"
    capture run_cli "$metadata_project" sync
    assert_eq 1 "$COMMAND_STATUS"
    assert_contains "$COMMAND_OUTPUT" 'Invalid canonical skill frontmatter' "${malformed_metadata_names[$metadata_index]} metadata error"
    assert_not_path "$(native_skill_path "$metadata_project" codex release-policy)"
done

# Deterministic file-byte validation, including NUL and the complete C0/C1
# boundary, is covered independently by runtime_skill_metadata_byte_test.bash.

printf '%s\n' '---' 'name: release-policy' 'description: "Release \"quoted\" from C:\\workspace"' '---' > "$metadata_project/skills/project/release-policy/SKILL.md"
assert_exit 0 run_cli "$metadata_project" sync
quoted_wrapper="$(native_skill_path "$metadata_project" codex release-policy)"
assert_contains "$(<"$quoted_wrapper")" 'name: "release-policy"' "quoted wrapper name serialization"
assert_contains "$(<"$quoted_wrapper")" 'description: "Release \"quoted\" from C:\\workspace"' "quoted wrapper description serialization"
assert_eq 'Release "quoted" from C:\workspace' "$(parse_markdown_skill_string "$quoted_wrapper" description)" "quoted wrapper description round-trip"

test_start "a core skill supersedes an obsolete project wrapper at the same native destination"
takeover_project="$SANDBOX_ROOT/project-core-takeover"
mkdir -p "$takeover_project"
assert_exit 0 run_cli "$takeover_project" init --runtime codex
mkdir -p "$takeover_project/skills/project/release-policy"
printf '%s\n' '---' 'name: release-policy' 'description: Use when a project policy owns this identifier.' '---' > "$takeover_project/skills/project/release-policy/SKILL.md"
set_enabled_project_skills "$takeover_project/.cyberpunk/config.yml" '[release-policy]'
assert_exit 0 run_cli "$takeover_project" sync
takeover_wrapper="$(native_skill_path "$takeover_project" codex release-policy)"
assert_contains "$(<"$takeover_wrapper")" '../../../skills/project/release-policy/SKILL.md' "project wrapper was not generated before takeover"
rm "$takeover_project/skills/project/release-policy/SKILL.md"
mkdir -p "$takeover_project/skills/core/release-policy"
printf '%s\n' '---' 'name: release-policy' 'description: Use when the core policy supersedes the project policy.' '---' > "$takeover_project/skills/core/release-policy/SKILL.md"
set_enabled_project_skills "$takeover_project/.cyberpunk/config.yml" '[]'
assert_exit 0 run_cli "$takeover_project" sync
assert_file "$takeover_wrapper"
assert_contains "$(<"$takeover_wrapper")" '../../../skills/core/release-policy/SKILL.md' "core wrapper was retired after takeover"
takeover_manifest="$(<"$takeover_project/.cyberpunk/generated.yml")"
assert_contains "$takeover_manifest" 'source: "skills/core/release-policy/SKILL.md"' "core manifest ownership missing after takeover"
assert_not_contains "$takeover_manifest" 'source: "skills/project/release-policy/SKILL.md"' "obsolete project manifest ownership remained after takeover"

test_start "skill discovery rejects missing and ambiguous canonical project skills before wrapper writes"
missing_project_skill_project="$SANDBOX_ROOT/missing-project-skill"
mkdir -p "$missing_project_skill_project"
assert_exit 0 run_cli "$missing_project_skill_project" init --runtime codex
replace_enabled_project_skills "$missing_project_skill_project/.cyberpunk/config.yml" '[missing-policy]'
rm -rf "$missing_project_skill_project/.agents"
capture run_cli "$missing_project_skill_project" sync
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" 'missing-policy' "missing project skill error"
assert_not_path "$missing_project_skill_project/.agents/skills"

mismatched_project_skill_project="$SANDBOX_ROOT/mismatched-project-skill"
mkdir -p "$mismatched_project_skill_project"
assert_exit 0 run_cli "$mismatched_project_skill_project" init --runtime codex
mkdir -p "$mismatched_project_skill_project/skills/project/release-policy"
printf '%s\n' '---' 'name: renamed-policy' 'description: Use when names do not match.' '---' > "$mismatched_project_skill_project/skills/project/release-policy/SKILL.md"
replace_enabled_project_skills "$mismatched_project_skill_project/.cyberpunk/config.yml" '[release-policy]'
rm -rf "$mismatched_project_skill_project/.agents"
capture run_cli "$mismatched_project_skill_project" sync
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" 'release-policy' "mismatched project skill error"
assert_not_path "$mismatched_project_skill_project/.agents/skills"

colliding_project_skill_project="$SANDBOX_ROOT/colliding-project-skill"
mkdir -p "$colliding_project_skill_project"
assert_exit 0 run_cli "$colliding_project_skill_project" init --runtime codex
mkdir -p "$colliding_project_skill_project/skills/project/task-decomposition"
printf '%s\n' '---' 'name: task-decomposition' 'description: Use when a project shadows a core skill.' '---' > "$colliding_project_skill_project/skills/project/task-decomposition/SKILL.md"
replace_enabled_project_skills "$colliding_project_skill_project/.cyberpunk/config.yml" '[task-decomposition]'
rm -rf "$colliding_project_skill_project/.agents"
capture run_cli "$colliding_project_skill_project" sync
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" 'task-decomposition' "core/project collision error"
assert_not_path "$colliding_project_skill_project/.agents/skills"

duplicate_core_skill_project="$SANDBOX_ROOT/duplicate-core-skill"
mkdir -p "$duplicate_core_skill_project"
assert_exit 0 run_cli "$duplicate_core_skill_project" init --runtime codex
sed 's/^name: repository-discovery$/name: task-decomposition/' \
    "$duplicate_core_skill_project/skills/core/repository-discovery/SKILL.md" > "$duplicate_core_skill_project/skills/core/repository-discovery/SKILL.md.tmp"
mv "$duplicate_core_skill_project/skills/core/repository-discovery/SKILL.md.tmp" "$duplicate_core_skill_project/skills/core/repository-discovery/SKILL.md"
rm -rf "$duplicate_core_skill_project/.agents"
capture run_cli "$duplicate_core_skill_project" sync
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" 'task-decomposition' "duplicate core skill error"
assert_not_path "$duplicate_core_skill_project/.agents/skills"

test_start "unowned and drifted native skill wrappers follow generated asset collision rules"
skill_collision_project="$SANDBOX_ROOT/skill-collision"
mkdir -p "$skill_collision_project/.agents/skills/task-decomposition"
printf '%s\n' 'user-owned-wrapper' > "$skill_collision_project/.agents/skills/task-decomposition/SKILL.md"
skill_collision_before="$(cksum "$skill_collision_project/.agents/skills/task-decomposition/SKILL.md")"
capture run_cli "$skill_collision_project" init --runtime codex
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" 'collision' "unowned skill wrapper collision"
assert_eq "$skill_collision_before" "$(cksum "$skill_collision_project/.agents/skills/task-decomposition/SKILL.md")" "unowned skill wrapper was replaced"

skill_drift_project="$SANDBOX_ROOT/skill-drift"
mkdir -p "$skill_drift_project"
assert_exit 0 run_cli "$skill_drift_project" init --runtime codex
skill_drift_path="$(native_skill_path "$skill_drift_project" codex task-decomposition)"
printf '%s\n' 'local-skill-wrapper-edit' >> "$skill_drift_path"
skill_drift_before="$(cksum "$skill_drift_path")"
capture run_cli "$skill_drift_project" sync
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" 'drift' "owned skill wrapper drift"
assert_eq "$skill_drift_before" "$(cksum "$skill_drift_path")" "non-force sync changed drifted skill wrapper"
assert_exit 0 run_cli "$skill_drift_project" sync --force
assert_not_contains "$(<"$skill_drift_path")" 'local-skill-wrapper-edit' "force did not regenerate owned skill wrapper"

test_start "representative role profiles map to exact vendor models"
for role in fixer operator daemon gatekeeper; do
    for runtime in "${runtimes[@]}"; do
        path="$(native_path "$project" "$runtime" "$role")"
        model="$(role_model_fixture "$role" "$runtime")"
        if [[ "$runtime" == codex ]]; then
            assert_contains "$(<"$path")" "model = \"$model\"" "$runtime $role representative model"
        else
            assert_contains "$(<"$path")" "model: \"$model\"" "$runtime $role representative model"
        fi
    done
done

test_start "a Claude-only project contains only Claude-native agents"
claude_project="$SANDBOX_ROOT/claude-only"
mkdir -p "$claude_project"
assert_exit 0 run_cli "$claude_project" init --runtime claude
for role in "${roles[@]}"; do
    assert_file "$claude_project/.claude/agents/$role.md"
done
assert_eq 11 "$(grep -Fc '    kind: "agent"' "$claude_project/.cyberpunk/generated.yml")" "single-runtime agent manifest count"
assert_not_path "$claude_project/.codex/agents"
assert_not_path "$claude_project/.cursor/agents"
assert_not_path "$claude_project/AGENTS.md"
assert_not_path "$claude_project/.cursor/rules/cyberpunk.mdc"

test_start "model resolution honors runtime override, override profile, role profile, and terminal inherit"
override_project="$SANDBOX_ROOT/overrides"
mkdir -p "$override_project"
assert_exit 0 run_cli "$override_project" init
override_config="$override_project/.cyberpunk/config.yml"
replace_override_block "$override_config" precedence
assert_exit 0 run_cli "$override_project" sync --force
assert_contains "$(<"$override_project/.claude/agents/fixer.md")" 'model: "runtime-claude"' "runtime override did not win"
assert_contains "$(<"$override_project/.codex/agents/fixer.toml")" 'model = "gpt-5.6-luna"' "override profile did not win"
assert_contains "$(<"$override_project/.cursor/agents/daemon.md")" 'model: "composer-2.5[]"' "role profile did not resolve"
assert_contains "$(<"$override_project/.cursor/agents/gatekeeper.md")" 'model: "inherit"' "inherit override did not terminate resolution"

test_start "native model metadata round-trips syntax-like strings in every vendor format"
serialization_names=(backslash quote comment colon empty-collection tag alias)
serialization_raw_models=('vendor\q' 'vendor"quote' '"#beta"' '"vendor: beta"' '"[]"' '"!tagged"' '"*alias"')
serialization_expected_models=('vendor\q' 'vendor"quote' '#beta' 'vendor: beta' '[]' '!tagged' '*alias')
for runtime in "${runtimes[@]}"; do
    serialization_project="$SANDBOX_ROOT/serialization-$runtime"
    mkdir -p "$serialization_project"
    assert_exit 0 run_cli "$serialization_project" init --runtime "$runtime"
    cp "$serialization_project/.cyberpunk/config.yml" "$serialization_project/base-config.yml"
    for serialization_index in "${!serialization_names[@]}"; do
        cp "$serialization_project/base-config.yml" "$serialization_project/.cyberpunk/config.yml"
        replace_override_with_model \
            "$serialization_project/.cyberpunk/config.yml" \
            "$runtime" \
            "${serialization_raw_models[$serialization_index]}"
        assert_exit 0 run_cli "$serialization_project" sync --force
        serialization_path="$(native_path "$serialization_project" "$runtime" fixer)"
        if [[ "$runtime" == codex ]]; then
            serialization_actual="$(parse_codex_model "$serialization_path")"
        else
            serialization_actual="$(parse_markdown_model "$serialization_path")"
        fi
        assert_eq \
            "${serialization_expected_models[$serialization_index]}" \
            "$serialization_actual" \
            "$runtime ${serialization_names[$serialization_index]} model round-trip"
    done
done

test_start "validation rejects an unsupported override profile"
invalid_override_project="$SANDBOX_ROOT/invalid-override"
mkdir -p "$invalid_override_project"
assert_exit 0 run_cli "$invalid_override_project" init
replace_override_block "$invalid_override_project/.cyberpunk/config.yml" invalid
capture run_cli "$invalid_override_project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Invalid model override profile for fixer: extreme"

test_start "validation rejects a canonical role without a profile"
missing_role_project="$SANDBOX_ROOT/missing-role"
mkdir -p "$missing_role_project"
assert_exit 0 run_cli "$missing_role_project" init
remove_exact_line "$missing_role_project/.cyberpunk/config.yml" '    neon: balanced'
capture run_cli "$missing_role_project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Missing model profile for role: neon"

test_start "validation rejects a profile missing an enabled-runtime mapping"
missing_mapping_project="$SANDBOX_ROOT/missing-mapping"
mkdir -p "$missing_mapping_project"
assert_exit 0 run_cli "$missing_mapping_project" init
remove_exact_line "$missing_mapping_project/.cyberpunk/config.yml" '      cursor: "composer-2.5[]"'
capture run_cli "$missing_mapping_project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Missing cursor model mapping for profile: balanced"

test_start "validation rejects a model fallback other than inherit"
fallback_project="$SANDBOX_ROOT/fallback"
mkdir -p "$fallback_project"
assert_exit 0 run_cli "$fallback_project" init
replace_exact_line "$fallback_project/.cyberpunk/config.yml" '  fallback: inherit' '  fallback: vendor-default'
capture run_cli "$fallback_project" validate
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Model fallback must be inherit"

test_start "an unowned native agent collision is preserved even with force"
collision_project="$SANDBOX_ROOT/collision"
mkdir -p "$collision_project/.claude/agents"
printf '%s\n' 'user-owned-native-agent' > "$collision_project/.claude/agents/nexus.md"
collision_before="$(cksum "$collision_project/.claude/agents/nexus.md")"
capture run_cli "$collision_project" init --runtime claude
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "collision"
assert_eq "$collision_before" "$(cksum "$collision_project/.claude/agents/nexus.md")" "native collision was overwritten"
capture run_cli "$collision_project" init --runtime claude --force
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "collision"
assert_eq "$collision_before" "$(cksum "$collision_project/.claude/agents/nexus.md")" "force overwrote native collision"

test_start "a later-runtime collision leaves no earlier generated assets unowned"
later_collision_project="$SANDBOX_ROOT/later-collision"
mkdir -p "$later_collision_project/.claude/agents"
printf '%s\n' 'later-user-owned-native-agent' > "$later_collision_project/.claude/agents/nexus.md"
later_collision_before="$(cksum "$later_collision_project/.claude/agents/nexus.md")"
capture run_cli "$later_collision_project" init
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "collision"
assert_eq "$later_collision_before" "$(cksum "$later_collision_project/.claude/agents/nexus.md")" "later collision was overwritten"
assert_eq "" "$(find "$later_collision_project/.codex/agents" -type f -print 2>/dev/null || true)" "later collision left unowned Codex agents"
assert_eq "" "$(find "$later_collision_project/.cursor" -type f -print 2>/dev/null || true)" "later collision left unowned Cursor assets"
[[ ! -e "$later_collision_project/.cyberpunk/generated.yml" ]] || fail "later collision committed a generated manifest"

test_start "a later write failure rolls back changed and newly installed assets"
rollback_project="$SANDBOX_ROOT/rollback"
mkdir -p "$rollback_project"
assert_exit 0 run_cli "$rollback_project" init
rollback_manifest_before="$(cksum "$rollback_project/.cyberpunk/generated.yml")"
rollback_codex_before="$(cksum "$rollback_project/.codex/agents/fixer.toml")"
rollback_claude_before="$(cksum "$rollback_project/.claude/agents/fixer.md")"
rm "$rollback_project/.claude/agents/coder.md"
replace_exact_line "$rollback_project/.cyberpunk/config.yml" '      codex: "gpt-5.6-sol"' '      codex: "rollback-model"'
replace_exact_line "$rollback_project/.cyberpunk/config.yml" '      claude: "opus"' '      claude: "rollback-model"'
replace_exact_line "$rollback_project/.cyberpunk/config.yml" '      cursor: "gpt-5.6-sol"' '      cursor: "rollback-model"'
chmod 500 "$rollback_project/.cursor/agents"
capture run_cli "$rollback_project" sync --force
chmod 700 "$rollback_project/.cursor/agents"
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "Cannot create generated asset temporary file in: .cursor/agents" "later write failure was not exercised"
assert_eq "$rollback_manifest_before" "$(cksum "$rollback_project/.cyberpunk/generated.yml")" "failed transaction changed the manifest"
assert_eq "$rollback_codex_before" "$(cksum "$rollback_project/.codex/agents/fixer.toml")" "failed transaction did not restore a Codex agent"
assert_eq "$rollback_claude_before" "$(cksum "$rollback_project/.claude/agents/fixer.md")" "failed transaction did not restore a Claude agent"
[[ ! -e "$rollback_project/.claude/agents/coder.md" ]] || fail "failed transaction left a newly installed Claude agent"

test_start "a handled signal after manifest commit keeps committed assets and manifest together"
signal_project="$SANDBOX_ROOT/post-commit-signal"
mkdir -p "$signal_project"
assert_exit 0 run_cli "$signal_project" init --runtime codex
signal_manifest_before="$(cksum "$signal_project/.cyberpunk/generated.yml")"
signal_fixer_before="$(cksum "$signal_project/.codex/agents/fixer.toml")"
replace_exact_line "$signal_project/.cyberpunk/config.yml" '      codex: "gpt-5.6-sol"' '      codex: "signal-model"'
signal_wrapper="$SANDBOX_ROOT/post-commit-signal-bin"
make_post_commit_signal_wrapper "$signal_wrapper"
capture run_cli_with_path "$signal_project" "$signal_wrapper" sync --force
assert_eq 143 "$COMMAND_STATUS" "post-commit signal did not interrupt synchronization"
assert_contains "$(<"$signal_project/.codex/agents/fixer.toml")" 'model = "signal-model"' "post-commit signal rolled back committed assets"
[[ "$signal_manifest_before" != "$(cksum "$signal_project/.cyberpunk/generated.yml")" ]] || fail "post-commit signal kept the old manifest"
[[ "$signal_fixer_before" != "$(cksum "$signal_project/.codex/agents/fixer.toml")" ]] || fail "post-commit signal kept the old native agent"
assert_exit 0 bash -c 'source "$1"; validate_generated_manifest "$2"' _ "$REPO_ROOT/lib/generated-assets.bash" "$signal_project/.cyberpunk/generated.yml"

test_start "an absent destination created after staging is preserved as a collision"
absent_race_project="$SANDBOX_ROOT/absent-race"
mkdir -p "$absent_race_project"
absent_race_wrapper="$SANDBOX_ROOT/absent-race-bin"
make_staging_race_wrapper "$absent_race_wrapper"
absent_race_target="$absent_race_project/.codex/agents/coder.toml"
capture run_cli_with_race \
    "$absent_race_project" \
    "$absent_race_wrapper" \
    "$absent_race_target" \
    create \
    'concurrent-user-collision' \
    init --runtime codex
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "collision after staging" "absent-path race was not detected"
assert_eq 'concurrent-user-collision' "$(<"$absent_race_target")" "absent-path race overwrote the user collision"
[[ ! -e "$absent_race_project/.cyberpunk/generated.yml" ]] || fail "absent-path race committed a manifest"

test_start "a forced sync preserves owned drift introduced after staging"
drift_race_project="$SANDBOX_ROOT/drift-race"
mkdir -p "$drift_race_project"
assert_exit 0 run_cli "$drift_race_project" init --runtime codex
drift_race_manifest_before="$(cksum "$drift_race_project/.cyberpunk/generated.yml")"
drift_race_fixer_before="$(cksum "$drift_race_project/.codex/agents/fixer.toml")"
replace_exact_line "$drift_race_project/.cyberpunk/config.yml" '      codex: "gpt-5.6-sol"' '      codex: "race-model"'
drift_race_wrapper="$SANDBOX_ROOT/drift-race-bin"
make_staging_race_wrapper "$drift_race_wrapper"
drift_race_target="$drift_race_project/.codex/agents/mind.toml"
capture run_cli_with_race \
    "$drift_race_project" \
    "$drift_race_wrapper" \
    "$drift_race_target" \
    append \
    'concurrent-user-drift' \
    sync --force
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "drift after staging" "owned-path race was not detected"
assert_contains "$(<"$drift_race_target")" 'concurrent-user-drift' "forced sync overwrote concurrent drift"
assert_eq "$drift_race_manifest_before" "$(cksum "$drift_race_project/.cyberpunk/generated.yml")" "owned-path race changed the manifest"
assert_eq "$drift_race_fixer_before" "$(cksum "$drift_race_project/.codex/agents/fixer.toml")" "owned-path race did not roll back an earlier install"

test_start "a present destination changed after revalidation is atomically preserved"
postcheck_present_project="$SANDBOX_ROOT/postcheck-present"
mkdir -p "$postcheck_present_project"
assert_exit 0 run_cli "$postcheck_present_project" init --runtime codex
postcheck_present_manifest_before="$(cksum "$postcheck_present_project/.cyberpunk/generated.yml")"
postcheck_present_fixer_before="$(cksum "$postcheck_present_project/.codex/agents/fixer.toml")"
replace_exact_line "$postcheck_present_project/.cyberpunk/config.yml" '      codex: "gpt-5.6-sol"' '      codex: "postcheck-model"'
postcheck_present_wrapper="$SANDBOX_ROOT/postcheck-present-bin"
make_post_check_present_wrapper "$postcheck_present_wrapper"
postcheck_present_target="$postcheck_present_project/.codex/agents/mind.toml"
capture run_cli_with_target_hook \
    "$postcheck_present_project" \
    "$postcheck_present_wrapper" \
    "$postcheck_present_target" \
    sync --force
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "changed during atomic claim" "post-check present drift was not detected"
assert_contains "$(<"$postcheck_present_target")" 'post-check-user-drift' "post-check present drift was overwritten"
assert_eq "$postcheck_present_manifest_before" "$(cksum "$postcheck_present_project/.cyberpunk/generated.yml")" "post-check present drift changed the manifest"
assert_eq "$postcheck_present_fixer_before" "$(cksum "$postcheck_present_project/.codex/agents/fixer.toml")" "post-check present drift did not roll back an earlier install"

test_start "an in-place edit of an installed asset is preserved when a later install fails"
rollback_edit_project="$SANDBOX_ROOT/rollback-installed-edit"
mkdir -p "$rollback_edit_project"
assert_exit 0 run_cli "$rollback_edit_project" init --runtime codex
rollback_edit_manifest_before="$(cksum "$rollback_edit_project/.cyberpunk/generated.yml")"
rollback_edit_fixer_before="$(cksum "$rollback_edit_project/.codex/agents/fixer.toml" | awk '{ print $1 " " $2 }')"
replace_exact_line "$rollback_edit_project/.cyberpunk/config.yml" '      codex: "gpt-5.6-sol"' '      codex: "rollback-race-model"'
rollback_edit_wrapper="$SANDBOX_ROOT/rollback-installed-edit-bin"
make_installed_edit_then_failure_wrapper "$rollback_edit_wrapper"
rollback_edit_target="$rollback_edit_project/.codex/agents/fixer.toml"
rollback_failure_target="$rollback_edit_project/.codex/agents/mind.toml"
rollback_hook_marker="$SANDBOX_ROOT/rollback-installed-edit-fired"
rollback_edit_witness="$SANDBOX_ROOT/rollback-installed-edit-witness"
capture run_cli_with_installed_edit_then_failure \
    "$rollback_edit_project" \
    "$rollback_edit_wrapper" \
    "$rollback_edit_target" \
    "$rollback_failure_target" \
    "$rollback_hook_marker" \
    "$rollback_edit_witness" \
    sync --force
assert_eq 1 "$COMMAND_STATUS"
assert_file "$rollback_hook_marker"
assert_contains "$COMMAND_OUTPUT" "no-clobber install" "later install failure was not exercised"
assert_contains "$(<"$rollback_edit_target")" 'rollback-user-edit' "rollback discarded the concurrent in-place edit"
assert_contains "$(<"$rollback_edit_target")" 'model = "rollback-race-model"' "rollback did not preserve the edited installed bytes"
assert_eq \
    "$(cksum "$rollback_edit_witness" | awk '{ print $1 " " $2 }')" \
    "$(cksum "$rollback_edit_target" | awk '{ print $1 " " $2 }')" \
    "rollback did not preserve every concurrently edited byte"
assert_eq "$rollback_edit_manifest_before" "$(cksum "$rollback_edit_project/.cyberpunk/generated.yml")" "in-place rollback race changed the manifest"
rollback_edit_workspace="$(printf '%s\n' "$COMMAND_OUTPUT" | sed -n 's/^Generated asset recovery workspace preserved: //p' | tail -n 1)"
[[ -n "$rollback_edit_workspace" ]] || fail "in-place rollback race did not report a recovery workspace"
assert_dir "$rollback_edit_workspace"
rollback_edit_backup="$(awk -F '\t' '$1 == ".codex/agents/fixer.toml" { print $3; exit }' "$rollback_edit_workspace/rollback.tsv")"
assert_file "$rollback_edit_backup"
assert_eq "$rollback_edit_fixer_before" "$(cksum "$rollback_edit_backup" | awk '{ print $1 " " $2 }')" "in-place rollback recovery lost the prior Fixer bytes"
case "$rollback_edit_workspace" in
    "${TMPDIR:-/tmp}"/cyberpunk-generated.*) rm -rf "$rollback_edit_workspace" ;;
    *) fail "refusing to clean unexpected recovery workspace: $rollback_edit_workspace" ;;
esac

test_start "an absent destination appearing after revalidation is not clobbered"
postcheck_absent_project="$SANDBOX_ROOT/postcheck-absent"
mkdir -p "$postcheck_absent_project"
postcheck_absent_wrapper="$SANDBOX_ROOT/postcheck-absent-bin"
make_post_check_absent_wrapper "$postcheck_absent_wrapper"
postcheck_absent_target="$postcheck_absent_project/.codex/agents/coder.toml"
capture run_cli_with_target_hook \
    "$postcheck_absent_project" \
    "$postcheck_absent_wrapper" \
    "$postcheck_absent_target" \
    init --runtime codex
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "no-clobber install" "post-check absent collision was not detected"
assert_eq 'post-check-user-collision' "$(<"$postcheck_absent_target")" "post-check absent collision was overwritten"
[[ ! -e "$postcheck_absent_project/.cyberpunk/generated.yml" ]] || fail "post-check absent collision committed a manifest"

test_start "an incomplete rollback preserves exact backup bytes for manual recovery"
recovery_project="$SANDBOX_ROOT/recovery"
mkdir -p "$recovery_project"
assert_exit 0 run_cli "$recovery_project" init
recovery_manifest_before="$(cksum "$recovery_project/.cyberpunk/generated.yml")"
recovery_fixer_before="$(cksum "$recovery_project/.codex/agents/fixer.toml" | awk '{ print $1 " " $2 }')"
replace_exact_line "$recovery_project/.cyberpunk/config.yml" '      codex: "gpt-5.6-sol"' '      codex: "recovery-model"'
replace_exact_line "$recovery_project/.cyberpunk/config.yml" '      claude: "opus"' '      claude: "recovery-model"'
replace_exact_line "$recovery_project/.cyberpunk/config.yml" '      cursor: "gpt-5.6-sol"' '      cursor: "recovery-model"'
recovery_wrapper="$SANDBOX_ROOT/recovery-bin"
make_restore_failure_wrapper "$recovery_wrapper"
chmod 500 "$recovery_project/.cursor/agents"
capture run_cli_with_path "$recovery_project" "$recovery_wrapper" sync --force
chmod 700 "$recovery_project/.cursor/agents"
assert_eq 1 "$COMMAND_STATUS"
assert_eq "$recovery_manifest_before" "$(cksum "$recovery_project/.cyberpunk/generated.yml")" "incomplete rollback changed the manifest"
recovery_workspace="$(printf '%s\n' "$COMMAND_OUTPUT" | sed -n 's/^Generated asset recovery workspace preserved: //p' | tail -n 1)"
[[ -n "$recovery_workspace" ]] || fail "incomplete rollback did not report a recovery workspace"
assert_dir "$recovery_workspace"
recovery_backup="$(awk -F '\t' '$1 == ".codex/agents/fixer.toml" { print $3; exit }' "$recovery_workspace/rollback.tsv")"
assert_file "$recovery_backup"
assert_eq "$recovery_fixer_before" "$(cksum "$recovery_backup" | awk '{ print $1 " " $2 }')" "preserved rollback backup does not contain the prior Fixer bytes"
case "$recovery_workspace" in
    "${TMPDIR:-/tmp}"/cyberpunk-generated.*) rm -rf "$recovery_workspace" ;;
    *) fail "refusing to clean unexpected recovery workspace: $recovery_workspace" ;;
esac

test_start "owned native agent drift is preserved without force and regenerated with force"
drift_project="$SANDBOX_ROOT/drift"
mkdir -p "$drift_project"
assert_exit 0 run_cli "$drift_project" init --runtime codex
operator_path="$drift_project/.codex/agents/operator.toml"
printf '%s\n' 'local-native-edit' >> "$operator_path"
operator_drift="$(cksum "$operator_path")"
manifest_drift="$(cksum "$drift_project/.cyberpunk/generated.yml")"
capture run_cli "$drift_project" sync
assert_eq 1 "$COMMAND_STATUS"
assert_contains "$COMMAND_OUTPUT" "drift"
assert_eq "$operator_drift" "$(cksum "$operator_path")" "non-force sync changed drifted native agent"
assert_eq "$manifest_drift" "$(cksum "$drift_project/.cyberpunk/generated.yml")" "failed native sync changed ownership manifest"
assert_exit 0 run_cli "$drift_project" sync --force
assert_not_contains "$(<"$operator_path")" 'local-native-edit' "force did not regenerate owned native agent"

echo "PASS: runtime adapter tests"
