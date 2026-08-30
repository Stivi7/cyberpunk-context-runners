#!/usr/bin/env bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/test_helper.bash"

SANDBOX_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/cyberpunk-runtime-skill-metadata-byte-test.XXXXXX")"
trap 'rm -rf "$SANDBOX_ROOT"' EXIT

run_cli_with_locale() {
    local locale_name="$1"
    local project="$2"
    shift 2

    (
        cd "$project"
        LC_ALL="$locale_name" LANG="$locale_name" "$CYBERPUNK_BIN" "$@"
    )
}

assert_not_path() {
    local path="$1"

    [[ ! -e "$path" && ! -L "$path" ]] || fail "unexpected path: $path"
}

native_skill_path() {
    local project="$1"
    local skill="$2"

    printf '%s\n' "$project/.agents/skills/$skill/SKILL.md"
}

set_enabled_project_skill() {
    local path="$1"
    local temporary="$path.tmp"

    awk '
        $0 == "  enabled_project: []" {
            print "  enabled_project: [release-policy]"
            replaced=1
            next
        }
        { print }
        END { if (!replaced) exit 1 }
    ' "$path" > "$temporary"
    mv "$temporary" "$path"
}

write_hex_bytes() {
    local hex_byte

    for hex_byte in "$@"; do
        [[ "$hex_byte" =~ ^[0-9A-Fa-f][0-9A-Fa-f]$ ]] || fail "invalid fixture byte: $hex_byte"
        printf '%b' "\\x$hex_byte"
    done
}

write_skill_with_frontmatter_bytes() {
    local path="$1"
    shift

    {
        printf '%s\n' \
            '---' \
            'name: release-policy' \
            'description: Use when raw skill bytes are examined.'
        printf '%s' 'byte probe: "'
        write_hex_bytes "$@"
        printf '%s\n' '"' '---'
    } > "$path"
}

write_skill_with_description_bytes() {
    local path="$1"
    shift

    {
        printf '%s\n' '---' 'name: release-policy'
        printf '%s' 'description: "Use when YAML permits '
        write_hex_bytes "$@"
        printf '%s\n' ' metadata."' '---'
    } > "$path"
}

write_crlf_skill() {
    local path="$1"

    printf '%s\r\n' \
        '---' \
        'name: release-policy' \
        'description: Use when CRLF YAML input is valid.' \
        '---' > "$path"
}

create_yaml_byte_fixtures() {
    local root="$1"
    local hex_byte
    local ascii_byte
    local c1_byte
    local c0_count=0
    local c1_count=0
    local invalid_case
    local invalid_name
    local invalid_payload
    local -a invalid_bytes=()
    local allowed_case
    local allowed_name
    local allowed_payload
    local -a allowed_bytes=()
    local -a invalid_utf8_cases=()
    local -a yaml_allowed_byte_cases=()

    mkdir -p "$root/prohibited-ascii" "$root/prohibited-c1" "$root/invalid-utf8" "$root/permitted"
    for ascii_byte in {0..31}; do
        case "$ascii_byte" in
            9|10|13) continue ;;
        esac
        printf -v hex_byte '%02X' "$ascii_byte"
        write_skill_with_frontmatter_bytes "$root/prohibited-ascii/c0-$hex_byte.md" "$hex_byte"
        c0_count=$((c0_count + 1))
    done
    write_skill_with_frontmatter_bytes "$root/prohibited-ascii/del-7F.md" 7F
    c0_count=$((c0_count + 1))
    assert_eq 30 "$c0_count" "exhaustive YAML-prohibited ASCII fixture count"

    for c1_byte in {128..159}; do
        [[ "$c1_byte" -eq 133 ]] && continue
        printf -v hex_byte '%02X' "$c1_byte"
        write_skill_with_frontmatter_bytes "$root/prohibited-c1/u00$hex_byte.md" C2 "$hex_byte"
        c1_count=$((c1_count + 1))
    done
    assert_eq 31 "$c1_count" "exhaustive YAML-prohibited C1 fixture count excluding U+0085"

    invalid_utf8_cases=(
        'lone-continuation|80'
        'truncated-two-byte|C2'
        'overlong-two-byte|C0 AF'
        'overlong-three-byte|E0 80 80'
        'surrogate|ED A0 80'
        'truncated-four-byte|F0 9F 98'
        'above-unicode-range|F4 90 80 80'
        'invalid-leading-byte|F5 80 80 80'
        'yaml-noncharacter-fffe|EF BF BE'
        'yaml-noncharacter-ffff|EF BF BF'
    )
    assert_eq 10 "${#invalid_utf8_cases[@]}" "invalid UTF-8 fixture table count"
    for invalid_case in "${invalid_utf8_cases[@]}"; do
        IFS='|' read -r invalid_name invalid_payload <<< "$invalid_case"
        read -r -a invalid_bytes <<< "$invalid_payload"
        write_skill_with_frontmatter_bytes "$root/invalid-utf8/$invalid_name.md" "${invalid_bytes[@]}"
    done

    yaml_allowed_byte_cases=(
        'horizontal-tab|09'
        'next-line|C2 85'
        'nonbreaking-space|C2 A0'
        'supplementary-plane|F0 9F 98 80'
    )
    assert_eq 4 "${#yaml_allowed_byte_cases[@]}" "YAML-permitted byte fixture table count"
    for allowed_case in "${yaml_allowed_byte_cases[@]}"; do
        IFS='|' read -r allowed_name allowed_payload <<< "$allowed_case"
        read -r -a allowed_bytes <<< "$allowed_payload"
        write_skill_with_frontmatter_bytes "$root/permitted/$allowed_name.md" "${allowed_bytes[@]}"
    done
    write_crlf_skill "$root/permitted/crlf.md"
}

validate_yaml_byte_fixture_table() {
    local fixture_locale="$1"
    local root="$2"

    LC_ALL="$fixture_locale" LANG="$fixture_locale" bash -c '
        source "$1"
        root="$2"
        shopt -s nullglob
        prohibited_ascii=("$root"/prohibited-ascii/*.md)
        prohibited_c1=("$root"/prohibited-c1/*.md)
        invalid_utf8=("$root"/invalid-utf8/*.md)
        permitted=("$root"/permitted/*.md)
        [[ ${#prohibited_ascii[@]} -eq 30 ]] || exit 64
        [[ ${#prohibited_c1[@]} -eq 31 ]] || exit 65
        [[ ${#invalid_utf8[@]} -eq 10 ]] || exit 66
        [[ ${#permitted[@]} -eq 5 ]] || exit 67
        for path in "${prohibited_ascii[@]}" "${prohibited_c1[@]}" "${invalid_utf8[@]}"; do
            if validate_yaml_printable_utf8_file "$path"; then
                printf "accepted prohibited byte fixture: %s\\n" "$path" >&2
                exit 1
            fi
        done
        for path in "${permitted[@]}"; do
            if ! validate_yaml_printable_utf8_file "$path"; then
                printf "rejected YAML-permitted byte fixture: %s\\n" "$path" >&2
                exit 1
            fi
        done
    ' _ "$CYBERPUNK_BIN" "$root"
}

test_start "sync rejects raw NUL, DEL, and prohibited C1 bytes before creating a wrapper"
integration_project="$SANDBOX_ROOT/integration-rejections"
integration_skill_path="$integration_project/skills/project/release-policy/SKILL.md"
integration_wrapper_path="$(native_skill_path "$integration_project" release-policy)"
mkdir -p "$integration_project"
assert_exit 0 run_cli_with_locale C "$integration_project" init --runtime codex
mkdir -p "$(dirname "$integration_skill_path")"
set_enabled_project_skill "$integration_project/.cyberpunk/config.yml"
for integration_case in 'nul|00' 'del|7F' 'prohibited-c1|C2 80'; do
    IFS='|' read -r integration_name integration_payload <<< "$integration_case"
    read -r -a integration_bytes <<< "$integration_payload"
    write_skill_with_frontmatter_bytes "$integration_skill_path" "${integration_bytes[@]}"
    capture run_cli_with_locale C "$integration_project" sync
    assert_eq 1 "$COMMAND_STATUS" "$integration_name byte must reject sync"
    assert_contains "$COMMAND_OUTPUT" 'Invalid canonical skill frontmatter' "$integration_name byte error"
    assert_not_path "$integration_wrapper_path"
done

test_start "canonical skill byte validation is locale-independent and follows YAML c-printable"
for fixture_locale in C C.UTF-8; do
    fixture_root="$SANDBOX_ROOT/fixture-$fixture_locale"
    create_yaml_byte_fixtures "$fixture_root"
    assert_exit 0 validate_yaml_byte_fixture_table "$fixture_locale" "$fixture_root"
done

test_start "YAML-permitted UTF-8 metadata and CRLF frontmatter remain discoverable"
permitted_project="$SANDBOX_ROOT/permitted-metadata"
permitted_skill_path="$permitted_project/skills/project/release-policy/SKILL.md"
permitted_wrapper_path="$(native_skill_path "$permitted_project" release-policy)"
mkdir -p "$permitted_project"
assert_exit 0 run_cli_with_locale C.UTF-8 "$permitted_project" init --runtime codex
mkdir -p "$(dirname "$permitted_skill_path")"
set_enabled_project_skill "$permitted_project/.cyberpunk/config.yml"
for yaml_allowed_metadata_case in \
    'horizontal-tab|09' \
    'next-line|C2 85' \
    'nonbreaking-space|C2 A0' \
    'supplementary-plane|F0 9F 98 80'; do
    IFS='|' read -r allowed_name allowed_payload <<< "$yaml_allowed_metadata_case"
    read -r -a allowed_bytes <<< "$allowed_payload"
    write_skill_with_description_bytes "$permitted_skill_path" "${allowed_bytes[@]}"
    assert_exit 0 run_cli_with_locale C.UTF-8 "$permitted_project" sync --force
    assert_file "$permitted_wrapper_path"
    assert_contains "$(<"$permitted_wrapper_path")" '../../../skills/project/release-policy/SKILL.md' "YAML-permitted $allowed_name metadata wrapper pointer"
done
write_crlf_skill "$permitted_skill_path"
assert_exit 0 run_cli_with_locale C.UTF-8 "$permitted_project" sync --force
assert_file "$permitted_wrapper_path"

echo "PASS: runtime skill metadata byte tests"
