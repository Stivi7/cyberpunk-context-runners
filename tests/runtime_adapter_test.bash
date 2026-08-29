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
