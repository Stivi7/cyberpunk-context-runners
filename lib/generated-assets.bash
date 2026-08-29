#!/usr/bin/env bash

GENERATED_MANIFEST_PATH=""
GENERATED_MANIFEST_INDEX=""
GENERATED_MANIFEST_RECORDS=""
GENERATED_MANIFEST_WORKDIR=""
GENERATED_STAGED_ASSETS=""
GENERATED_STAGED_SORTED=""
GENERATED_ROLLBACK_LOG=""
GENERATED_TRANSACTION_COMMITTED=false
GENERATED_MANIFEST_FAILED=false
GENERATED_ACTIVE_TEMP=""
GENERATED_PREVIOUS_HUP_TRAP=""
GENERATED_PREVIOUS_INT_TRAP=""
GENERATED_PREVIOUS_TERM_TRAP=""
GENERATED_SIGNAL_TRAPS_ACTIVE=false

sha256_file() {
    local path="$1"

    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$path" | awk '{ value=$1; sub(/^\\/, "", value); print value }'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$path" | awk '{ value=$1; sub(/^\\/, "", value); print value }'
    else
        printf 'No SHA-256 tool found; install shasum or sha256sum\n' >&2
        return 1
    fi
}

create_parent_directory() {
    local path="$1"
    local directory

    directory="$(dirname "$path")"
    if ! mkdir -p "$directory"; then
        printf 'Cannot create parent directory: %s\n' "$directory" >&2
        return 1
    fi
}

create_sibling_temp() {
    local path="$1"
    local directory
    local basename_value

    directory="$(dirname "$path")"
    basename_value="$(basename "$path")"
    mktemp "$directory/.$basename_value.tmp.XXXXXX"
}

discard_temp_file() {
    local path="$1"
    local status=0

    [[ -n "$path" ]] || return 0
    if [[ -e "$path" || -L "$path" ]]; then
        rm -f "$path" || status=$?
    fi
    if [[ "$status" -eq 0 && "$GENERATED_ACTIVE_TEMP" == "$path" ]]; then
        GENERATED_ACTIVE_TEMP=""
    fi
    return "$status"
}

commit_temp_file() {
    local temporary="$1"
    local destination="$2"

    if generated_path_exists "$destination" && [[ ! -f "$destination" || -L "$destination" ]]; then
        printf 'Refusing to replace non-regular destination: %s\n' "$destination" >&2
        discard_temp_file "$temporary" || true
        return 1
    elif [[ -f "$destination" ]] && cmp -s "$temporary" "$destination"; then
        if ! discard_temp_file "$temporary"; then
            return 1
        fi
    elif ! mv "$temporary" "$destination"; then
        discard_temp_file "$temporary" || true
        return 1
    elif [[ "$GENERATED_ACTIVE_TEMP" == "$temporary" ]]; then
        GENERATED_ACTIVE_TEMP=""
    fi
}

install_generated_signal_traps() {
    GENERATED_PREVIOUS_HUP_TRAP="$(trap -p HUP || true)"
    GENERATED_PREVIOUS_INT_TRAP="$(trap -p INT || true)"
    GENERATED_PREVIOUS_TERM_TRAP="$(trap -p TERM || true)"
    GENERATED_SIGNAL_TRAPS_ACTIVE=true
    trap 'abort_generated_manifest_transaction; exit 129' HUP
    trap 'abort_generated_manifest_transaction; exit 130' INT
    trap 'abort_generated_manifest_transaction; exit 143' TERM
}

restore_generated_signal_traps() {
    local previous_hup="$GENERATED_PREVIOUS_HUP_TRAP"
    local previous_int="$GENERATED_PREVIOUS_INT_TRAP"
    local previous_term="$GENERATED_PREVIOUS_TERM_TRAP"

    [[ "$GENERATED_SIGNAL_TRAPS_ACTIVE" == true ]] || return 0
    trap - HUP INT TERM
    GENERATED_PREVIOUS_HUP_TRAP=""
    GENERATED_PREVIOUS_INT_TRAP=""
    GENERATED_PREVIOUS_TERM_TRAP=""
    GENERATED_SIGNAL_TRAPS_ACTIVE=false
    [[ -z "$previous_hup" ]] || eval "$previous_hup"
    [[ -z "$previous_int" ]] || eval "$previous_int"
    [[ -z "$previous_term" ]] || eval "$previous_term"
}

mask_generated_commit_signals() {
    trap '' HUP INT TERM
}

resume_generated_transaction_signals() {
    trap 'abort_generated_manifest_transaction; exit 129' HUP
    trap 'abort_generated_manifest_transaction; exit 130' INT
    trap 'abort_generated_manifest_transaction; exit 143' TERM
}

load_generated_manifest_records() {
    local manifest_path="$1"
    local records_path="$2"

    awk '
        BEGIN {
            OFS="\t"
            state="version"
        }
        function decode_quoted(raw,    decoded, character, escaped, index_value) {
            if (length(raw) < 2 || substr(raw, 1, 1) != "\"" || substr(raw, length(raw), 1) != "\"") {
                invalid=1
                return ""
            }
            raw=substr(raw, 2, length(raw) - 2)
            decoded=""
            for (index_value=1; index_value <= length(raw); index_value++) {
                character=substr(raw, index_value, 1)
                if (character == "\\") {
                    index_value++
                    if (index_value > length(raw)) {
                        invalid=1
                        return ""
                    }
                    escaped=substr(raw, index_value, 1)
                    if (escaped != "\\" && escaped != "\"") {
                        invalid=1
                        return ""
                    }
                    decoded=decoded escaped
                } else if (character == "\"" || character == "\t" || character == "\r") {
                    invalid=1
                    return ""
                } else {
                    decoded=decoded character
                }
            }
            return decoded
        }
        function field_value(line, prefix) {
            if (index(line, prefix) != 1) {
                invalid=1
                return ""
            }
            return decode_quoted(substr(line, length(prefix) + 1))
        }

        NR == 1 {
            if ($0 == "version: 1") {
                state="assets"
            } else if ($0 ~ /^version:[[:space:]]*/) {
                unsupported=1
            } else {
                invalid=1
            }
            next
        }
        state == "assets" {
            if ($0 == "assets: []") {
                state="done"
            } else if ($0 == "assets:") {
                state="path"
            } else {
                invalid=1
            }
            next
        }
        state == "path" {
            path=field_value($0, "  - path: ")
            source=runtime=kind=identifier=sha256=""
            record_count++
            state="source"
            next
        }
        state == "source" {
            source=field_value($0, "    source: ")
            state="runtime"
            next
        }
        state == "runtime" {
            runtime=field_value($0, "    runtime: ")
            state="kind"
            next
        }
        state == "kind" {
            kind=field_value($0, "    kind: ")
            state="identifier"
            next
        }
        state == "identifier" {
            identifier=field_value($0, "    identifier: ")
            state="sha256"
            next
        }
        state == "sha256" {
            sha256=field_value($0, "    sha256: ")
            if (path == "" || source == "" || runtime == "" || kind == "" || identifier == "" ||
                length(sha256) != 64 || sha256 ~ /[^0-9a-f]/) {
                invalid=1
            } else {
                print path, source, runtime, kind, identifier, sha256
            }
            state="path"
            next
        }
        { invalid=1 }

        END {
            if (NR < 2 || state == "version" || state == "assets" || state == "source" ||
                state == "runtime" || state == "kind" || state == "identifier" || state == "sha256" ||
                (state == "path" && record_count == 0)) {
                invalid=1
            }
            if (unsupported) exit 2
            if (invalid) exit 1
        }
    ' "$manifest_path" > "$records_path"
}

cleanup_generated_manifest() {
    local cleanup_status=0
    local staged_destination
    local staged_content
    local staged_expected_state
    local staged_expected_hash
    local rollback_destination
    local rollback_existed
    local rollback_backup
    local rollback_install_temp
    local rollback_backup_dir
    local rollback_claimed_marker
    local rollback_installed_marker
    local rollback_desired_hash

    if [[ -n "$GENERATED_ACTIVE_TEMP" ]]; then
        discard_temp_file "$GENERATED_ACTIVE_TEMP" || cleanup_status=1
    fi
    if [[ -n "$GENERATED_STAGED_ASSETS" && -f "$GENERATED_STAGED_ASSETS" ]]; then
        while IFS=$'\t' read -r staged_destination staged_content staged_expected_state staged_expected_hash; do
            [[ -n "$staged_content" ]] || continue
            discard_temp_file "$staged_content" || cleanup_status=1
        done < "$GENERATED_STAGED_ASSETS"
    fi
    if [[ -n "$GENERATED_ROLLBACK_LOG" && -f "$GENERATED_ROLLBACK_LOG" ]]; then
        while IFS=$'\t' read -r rollback_destination rollback_existed rollback_backup rollback_install_temp rollback_backup_dir rollback_claimed_marker rollback_installed_marker rollback_desired_hash; do
            [[ -z "$rollback_install_temp" || "$rollback_install_temp" == - ]] || discard_temp_file "$rollback_install_temp" || cleanup_status=1
            [[ -z "$rollback_backup" || "$rollback_backup" == - ]] || discard_temp_file "$rollback_backup" || cleanup_status=1
            [[ -z "$rollback_claimed_marker" || "$rollback_claimed_marker" == - ]] || discard_temp_file "$rollback_claimed_marker" || cleanup_status=1
            [[ -z "$rollback_installed_marker" || "$rollback_installed_marker" == - ]] || discard_temp_file "$rollback_installed_marker" || cleanup_status=1
            if [[ -n "$rollback_backup_dir" && "$rollback_backup_dir" != - ]]; then
                discard_temp_file "$rollback_backup_dir/installed" || cleanup_status=1
            fi
            if [[ -n "$rollback_backup_dir" && "$rollback_backup_dir" != - && -d "$rollback_backup_dir" ]]; then
                rmdir "$rollback_backup_dir" 2>/dev/null || cleanup_status=1
            fi
        done < "$GENERATED_ROLLBACK_LOG"
    fi
    if [[ -n "$GENERATED_MANIFEST_WORKDIR" && -d "$GENERATED_MANIFEST_WORKDIR" ]]; then
        rm -f \
            "$GENERATED_MANIFEST_WORKDIR/index.tsv" \
            "$GENERATED_MANIFEST_WORKDIR/records.tsv" \
            "$GENERATED_MANIFEST_WORKDIR/records.updated.tsv" \
            "$GENERATED_MANIFEST_WORKDIR/records.sorted.tsv" \
            "$GENERATED_MANIFEST_WORKDIR/staged.tsv" \
            "$GENERATED_MANIFEST_WORKDIR/staged.sorted.tsv" \
            "$GENERATED_MANIFEST_WORKDIR/rollback.tsv" \
            "$GENERATED_MANIFEST_WORKDIR/cursor.mdc" || cleanup_status=1
        rmdir "$GENERATED_MANIFEST_WORKDIR" 2>/dev/null || cleanup_status=1
    fi
    GENERATED_MANIFEST_PATH=""
    GENERATED_MANIFEST_INDEX=""
    GENERATED_MANIFEST_RECORDS=""
    GENERATED_MANIFEST_WORKDIR=""
    GENERATED_STAGED_ASSETS=""
    GENERATED_STAGED_SORTED=""
    GENERATED_ROLLBACK_LOG=""
    GENERATED_TRANSACTION_COMMITTED=false
    GENERATED_MANIFEST_FAILED=false
    GENERATED_ACTIVE_TEMP=""
    restore_generated_signal_traps
    return "$cleanup_status"
}

begin_generated_manifest() {
    local manifest_path="$1"
    local record_path
    local record_source
    local record_runtime
    local record_kind
    local record_identifier
    local record_hash

    cleanup_generated_manifest
    GENERATED_MANIFEST_PATH="$manifest_path"
    if [[ -L "$manifest_path" || (-e "$manifest_path" && ! -f "$manifest_path") ]]; then
        printf 'Generated asset manifest is not a regular file: %s\n' "$manifest_path" >&2
        GENERATED_MANIFEST_PATH=""
        return 1
    fi
    if ! GENERATED_MANIFEST_WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/cyberpunk-generated.XXXXXX")"; then
        printf 'Cannot create generated asset work directory\n' >&2
        GENERATED_MANIFEST_PATH=""
        return 1
    fi
    install_generated_signal_traps
    GENERATED_MANIFEST_INDEX="$GENERATED_MANIFEST_WORKDIR/index.tsv"
    GENERATED_MANIFEST_RECORDS="$GENERATED_MANIFEST_WORKDIR/records.tsv"
    GENERATED_STAGED_ASSETS="$GENERATED_MANIFEST_WORKDIR/staged.tsv"
    GENERATED_STAGED_SORTED="$GENERATED_MANIFEST_WORKDIR/staged.sorted.tsv"
    GENERATED_ROLLBACK_LOG="$GENERATED_MANIFEST_WORKDIR/rollback.tsv"
    GENERATED_TRANSACTION_COMMITTED=false
    if ! : > "$GENERATED_MANIFEST_INDEX"; then
        cleanup_generated_manifest
        return 1
    fi
    if ! : > "$GENERATED_MANIFEST_RECORDS"; then
        cleanup_generated_manifest
        return 1
    fi
    if ! : > "$GENERATED_STAGED_ASSETS"; then
        cleanup_generated_manifest
        return 1
    fi
    if ! : > "$GENERATED_ROLLBACK_LOG"; then
        cleanup_generated_manifest
        return 1
    fi

    if [[ -f "$manifest_path" ]]; then
        if load_generated_manifest_records "$manifest_path" "$GENERATED_MANIFEST_INDEX"; then
            :
        else
            local load_status=$?
            if [[ "$load_status" -eq 2 ]]; then
                printf 'Unsupported generated asset manifest version: %s\n' "$manifest_path" >&2
            else
                printf 'Malformed generated asset manifest: %s\n' "$manifest_path" >&2
            fi
            cleanup_generated_manifest
            return 1
        fi
        if ! awk -F '\t' '!/^[[:space:]]*$/ && seen[$1]++ { exit 1 }' "$GENERATED_MANIFEST_INDEX"; then
            printf 'Duplicate generated asset path in manifest: %s\n' "$manifest_path" >&2
            cleanup_generated_manifest
            return 1
        fi
    fi

    while IFS=$'\t' read -r record_path record_source record_runtime record_kind record_identifier record_hash; do
        [[ -n "$record_path" ]] || continue
        if generated_path_exists "$record_path" && [[ ! -f "$record_path" || -L "$record_path" ]]; then
            printf 'Generated asset collision: %s is not a regular Cyberpunk-owned file\n' "$record_path" >&2
            cleanup_generated_manifest
            return 1
        elif [[ -f "$record_path" ]]; then
            if ! printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$record_path" "$record_source" "$record_runtime" "$record_kind" "$record_identifier" "$record_hash" \
                >> "$GENERATED_MANIFEST_RECORDS"; then
                cleanup_generated_manifest
                return 1
            fi
        fi
    done < "$GENERATED_MANIFEST_INDEX"
}

record_generated_asset() {
    local path="$1"
    local source="$2"
    local runtime="$3"
    local kind="$4"
    local identifier="$5"
    local hash="$6"
    local updated
    local record_path
    local record_source
    local record_runtime
    local record_kind
    local record_identifier
    local record_hash

    if ! updated="$(mktemp "$GENERATED_MANIFEST_WORKDIR/records.updated.XXXXXX")"; then
        return 1
    fi
    GENERATED_ACTIVE_TEMP="$updated"
    while IFS=$'\t' read -r record_path record_source record_runtime record_kind record_identifier record_hash; do
        [[ "$record_path" == "$path" ]] && continue
        if ! printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$record_path" "$record_source" "$record_runtime" "$record_kind" "$record_identifier" "$record_hash" \
            >> "$updated"; then
            discard_temp_file "$updated" || true
            return 1
        fi
    done < "$GENERATED_MANIFEST_RECORDS"
    if ! printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$path" "$source" "$runtime" "$kind" "$identifier" "$hash" >> "$updated"; then
        discard_temp_file "$updated" || true
        return 1
    fi
    if ! mv "$updated" "$GENERATED_MANIFEST_RECORDS"; then
        discard_temp_file "$updated" || true
        return 1
    fi
    GENERATED_ACTIVE_TEMP=""
}

replace_generated_file() {
    local destination="$1"
    local content_file="$2"
    local destination_dir
    local temporary

    if [[ "${DRY_RUN:-false}" == true ]]; then
        return 0
    fi

    destination_dir="$(dirname "$destination")"
    if ! create_parent_directory "$destination"; then
        return 1
    fi
    if ! temporary="$(create_sibling_temp "$destination")"; then
        printf 'Cannot create generated asset temporary file in: %s\n' "$destination_dir" >&2
        return 1
    fi
    GENERATED_ACTIVE_TEMP="$temporary"
    if ! cp "$content_file" "$temporary"; then
        discard_temp_file "$temporary" || true
        return 1
    fi
    if ! mv "$temporary" "$destination"; then
        discard_temp_file "$temporary" || true
        return 1
    fi
    GENERATED_ACTIVE_TEMP=""
}

stage_generated_file() {
    local destination="$1"
    local content_file="$2"
    local expected_state="$3"
    local expected_hash="$4"
    local staged_content

    if ! staged_content="$(mktemp "$GENERATED_MANIFEST_WORKDIR/asset.XXXXXX")"; then
        printf 'Cannot create generated asset staging file\n' >&2
        return 1
    fi
    GENERATED_ACTIVE_TEMP="$staged_content"
    if ! cp "$content_file" "$staged_content"; then
        discard_temp_file "$staged_content" || true
        return 1
    fi
    if ! printf '%s\t%s\t%s\t%s\n' \
        "$destination" "$staged_content" "$expected_state" "$expected_hash" \
        >> "$GENERATED_STAGED_ASSETS"; then
        discard_temp_file "$staged_content" || true
        return 1
    fi
    GENERATED_ACTIVE_TEMP=""
}

generated_path_exists() {
    [[ -e "$1" || -L "$1" ]]
}

find_generated_record() {
    local wanted_path="$1"
    local index_path="$2"
    local record_path
    local record_source
    local record_runtime
    local record_kind
    local record_identifier
    local record_hash

    while IFS=$'\t' read -r record_path record_source record_runtime record_kind record_identifier record_hash; do
        if [[ "$record_path" == "$wanted_path" ]]; then
            printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$record_path" "$record_source" "$record_runtime" "$record_kind" "$record_identifier" "$record_hash"
            return 0
        fi
    done < "$index_path"
    return 1
}

validate_generated_manifest_field() {
    local field_name="$1"
    local value="$2"

    case "$value" in
        *$'\t'*|*$'\r'*|*$'\n'*)
            printf 'Invalid generated manifest field %s: raw tab, CR, and LF bytes are not allowed\n' "$field_name" >&2
            return 1
            ;;
    esac
}

write_generated_asset() {
    local destination="$1"
    local source="$2"
    local runtime="$3"
    local kind="$4"
    local identifier="$5"
    local content_file="$6"
    local relative_path="${destination#./}"
    local desired_hash
    local actual_hash
    local prior_record
    local prior_path=""
    local prior_source=""
    local prior_runtime=""
    local prior_kind=""
    local prior_identifier=""
    local prior_hash=""
    local expected_state=absent
    local expected_hash=""

    if [[ -z "$GENERATED_MANIFEST_PATH" ]]; then
        printf 'Generated asset manifest has not been started\n' >&2
        return 1
    fi
    if ! validate_generated_manifest_field path "$relative_path" ||
        ! validate_generated_manifest_field source "$source" ||
        ! validate_generated_manifest_field runtime "$runtime" ||
        ! validate_generated_manifest_field kind "$kind" ||
        ! validate_generated_manifest_field identifier "$identifier"; then
        GENERATED_MANIFEST_FAILED=true
        return 1
    fi
    if [[ ! -f "$content_file" ]]; then
        printf 'Generated asset content file not found: %s\n' "$content_file" >&2
        GENERATED_MANIFEST_FAILED=true
        return 1
    fi

    desired_hash="$(sha256_file "$content_file")" || {
        GENERATED_MANIFEST_FAILED=true
        return 1
    }
    if prior_record="$(find_generated_record "$relative_path" "$GENERATED_MANIFEST_INDEX")"; then
        :
    else
        prior_record=""
    fi
    if [[ -n "$prior_record" ]]; then
        IFS=$'\t' read -r prior_path prior_source prior_runtime prior_kind prior_identifier prior_hash <<EOF
$prior_record
EOF
    fi

    if generated_path_exists "$destination" && [[ -z "$prior_path" || ! -f "$destination" || -L "$destination" ]]; then
        printf 'Generated asset collision: %s is not owned by Cyberpunk\n' "$relative_path" >&2
        GENERATED_MANIFEST_FAILED=true
        return 1
    elif [[ -f "$destination" ]]; then
        actual_hash="$(sha256_file "$destination")" || {
            GENERATED_MANIFEST_FAILED=true
            return 1
        }
        if [[ "$actual_hash" != "$prior_hash" && "${FORCE:-false}" != true ]]; then
            printf 'Generated asset drift: %s was modified locally; rerun with --force to replace it\n' "$relative_path" >&2
            GENERATED_MANIFEST_FAILED=true
            return 1
        fi
        expected_state=present
        expected_hash="$actual_hash"
    fi

    if ! stage_generated_file "$relative_path" "$content_file" "$expected_state" "$expected_hash"; then
        GENERATED_MANIFEST_FAILED=true
        return 1
    fi

    if ! record_generated_asset "$relative_path" "$source" "$runtime" "$kind" "$identifier" "$desired_hash"; then
        GENERATED_MANIFEST_FAILED=true
        return 1
    fi
}

restore_generated_file() {
    local destination="$1"
    local backup="$2"

    if [[ -f "$destination" && ! -L "$destination" ]] && cmp -s "$destination" "$backup"; then
        return 0
    fi
    if generated_path_exists "$destination"; then
        printf 'Refusing to overwrite concurrent content during rollback: %s\n' "$destination" >&2
        return 1
    fi
    if ! create_parent_directory "$destination"; then
        return 1
    fi
    if ! ln "$backup" "$destination"; then
        printf 'Cannot restore generated asset without overwriting concurrent content: %s\n' "$destination" >&2
        return 1
    fi
}

remove_installed_generated_file() {
    local destination="$1"
    local install_temp="$2"
    local desired_hash="$3"
    local held_destination="$4"
    local actual_hash

    if ! generated_path_exists "$destination"; then
        return 0
    fi
    if ! mv "$destination" "$held_destination"; then
        printf 'Cannot atomically claim installed generated asset during rollback: %s\n' "$destination" >&2
        return 1
    fi
    if [[ -f "$held_destination" && ! -L "$held_destination" &&
        -f "$install_temp" && ! -L "$install_temp" && "$held_destination" -ef "$install_temp" ]]; then
        if actual_hash="$(sha256_file "$held_destination")" && [[ "$actual_hash" == "$desired_hash" ]]; then
            return 0
        fi
    fi
    if ! ln "$held_destination" "$destination"; then
        printf 'Concurrent content was claimed during rollback and remains recoverable at: %s\n' "$held_destination" >&2
        return 1
    fi
    printf 'Refusing to remove concurrent content during generated asset rollback: %s\n' "$destination" >&2
    return 1
}

rollback_generated_assets() {
    local destination
    local existed
    local backup
    local install_temp
    local backup_dir
    local claimed_marker
    local installed_marker
    local desired_hash
    local rollback_status=0

    [[ -n "$GENERATED_ROLLBACK_LOG" && -f "$GENERATED_ROLLBACK_LOG" ]] || return 0
    while IFS=$'\t' read -r destination existed backup install_temp backup_dir claimed_marker installed_marker desired_hash; do
        [[ -n "$destination" ]] || continue
        if [[ -n "$installed_marker" && "$installed_marker" != - && -f "$installed_marker" ]]; then
            if ! remove_installed_generated_file "$destination" "$install_temp" "$desired_hash" "$backup_dir/installed"; then
                rollback_status=1
                continue
            fi
        fi
        if [[ "$existed" == true ]]; then
            if [[ -f "$backup" && ! -L "$backup" ]]; then
                if ! restore_generated_file "$destination" "$backup"; then
                    printf 'Cannot restore generated asset during rollback: %s\n' "$destination" >&2
                    rollback_status=1
                fi
            elif [[ -n "$claimed_marker" && -f "$claimed_marker" ]]; then
                printf 'Generated rollback backup is unavailable for: %s\n' "$destination" >&2
                rollback_status=1
            fi
        fi
    done < "$GENERATED_ROLLBACK_LOG"
    return "$rollback_status"
}

discard_generated_rollback_backups() {
    local destination
    local existed
    local backup
    local install_temp
    local backup_dir
    local claimed_marker
    local installed_marker
    local desired_hash
    local discard_status=0

    while IFS=$'\t' read -r destination existed backup install_temp backup_dir claimed_marker installed_marker desired_hash; do
        [[ -z "$backup" || "$backup" == - ]] || discard_temp_file "$backup" || discard_status=1
        [[ -z "$install_temp" || "$install_temp" == - ]] || discard_temp_file "$install_temp" || discard_status=1
        [[ -z "$claimed_marker" || "$claimed_marker" == - ]] || discard_temp_file "$claimed_marker" || discard_status=1
        [[ -z "$installed_marker" || "$installed_marker" == - ]] || discard_temp_file "$installed_marker" || discard_status=1
        if [[ -n "$backup_dir" && "$backup_dir" != - ]]; then
            discard_temp_file "$backup_dir/installed" || discard_status=1
        fi
        if [[ -n "$backup_dir" && "$backup_dir" != - && -d "$backup_dir" ]]; then
            rmdir "$backup_dir" 2>/dev/null || discard_status=1
        fi
    done < "$GENERATED_ROLLBACK_LOG"
    return "$discard_status"
}

install_generated_file_no_clobber() {
    local temporary="$1"
    local destination="$2"

    if ! ln "$temporary" "$destination"; then
        printf 'Generated asset no-clobber install failed because the destination appeared concurrently: %s\n' "$destination" >&2
        return 1
    fi
}

install_staged_generated_assets() {
    local destination
    local staged_content
    local expected_state
    local expected_hash
    local actual_hash
    local existed
    local backup
    local backup_dir
    local claimed_marker
    local installed_marker
    local install_temp
    local destination_dir
    local destination_display_dir
    local destination_name
    local desired_hash

    if ! LC_ALL=C sort -t $'\t' -k1,1 "$GENERATED_STAGED_ASSETS" > "$GENERATED_STAGED_SORTED"; then
        return 1
    fi
    if ! : > "$GENERATED_ROLLBACK_LOG"; then
        return 1
    fi

    while IFS=$'\t' read -r destination staged_content expected_state expected_hash; do
        [[ -n "$destination" && -n "$staged_content" ]] || continue
        case "$expected_state" in
            absent)
                if generated_path_exists "$destination"; then
                    printf 'Generated asset collision after staging: %s changed from absent to present\n' "$destination" >&2
                    return 1
                fi
                ;;
            present)
                if [[ ! -f "$destination" || -L "$destination" ]]; then
                    printf 'Generated asset drift after staging: %s changed type or disappeared\n' "$destination" >&2
                    return 1
                fi
                if ! actual_hash="$(sha256_file "$destination")"; then
                    return 1
                fi
                if [[ "$actual_hash" != "$expected_hash" ]]; then
                    printf 'Generated asset drift after staging: %s changed concurrently\n' "$destination" >&2
                    return 1
                fi
                ;;
            *)
                printf 'Invalid generated asset staging state for: %s\n' "$destination" >&2
                return 1
                ;;
        esac
        if [[ -f "$destination" && ! -L "$destination" ]] && cmp -s "$destination" "$staged_content"; then
            continue
        fi
        if ! create_parent_directory "$destination"; then
            return 1
        fi
        if ! desired_hash="$(sha256_file "$staged_content")"; then
            return 1
        fi

        destination_display_dir="$(dirname "$destination")"
        destination_dir="$(cd "$destination_display_dir" && pwd -P)"
        destination_name="$(basename "$destination")"
        if ! install_temp="$(create_sibling_temp "$destination_dir/$destination_name")"; then
            printf 'Cannot create generated asset temporary file in: %s\n' "$destination_display_dir" >&2
            return 1
        fi
        GENERATED_ACTIVE_TEMP="$install_temp"
        if ! cp "$staged_content" "$install_temp"; then
            discard_temp_file "$install_temp" || true
            return 1
        fi

        existed=false
        backup="-"
        if ! backup_dir="$(mktemp -d "$destination_dir/.$destination_name.rollback.XXXXXX")"; then
            printf 'Cannot create generated rollback directory for: %s\n' "$destination" >&2
            discard_temp_file "$install_temp" || true
            return 1
        fi
        claimed_marker="-"
        installed_marker="$backup_dir/installed-claimed"
        if [[ "$expected_state" == present ]]; then
            backup="$backup_dir/original"
            claimed_marker="$backup_dir/claimed"
            existed=true
        fi

        mask_generated_commit_signals
        if ! printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$destination" "$existed" "$backup" "$install_temp" "$backup_dir" "$claimed_marker" "$installed_marker" "$desired_hash" \
            >> "$GENERATED_ROLLBACK_LOG"; then
            resume_generated_transaction_signals
            discard_temp_file "$install_temp" || true
            rmdir "$backup_dir" 2>/dev/null || true
            return 1
        fi
        GENERATED_ACTIVE_TEMP=""

        if [[ "$expected_state" == present ]]; then
            if ! mv "$destination" "$backup"; then
                resume_generated_transaction_signals
                return 1
            fi
            if ! : > "$claimed_marker"; then
                resume_generated_transaction_signals
                return 1
            fi
        fi
        resume_generated_transaction_signals

        if [[ "$expected_state" == present ]]; then
            if [[ ! -f "$backup" || -L "$backup" ]]; then
                printf 'Generated asset changed type during atomic claim: %s\n' "$destination" >&2
                return 1
            fi
            if ! actual_hash="$(sha256_file "$backup")"; then
                return 1
            fi
            if [[ "$actual_hash" != "$expected_hash" ]]; then
                printf 'Generated asset changed during atomic claim: %s\n' "$destination" >&2
                return 1
            fi
        fi

        mask_generated_commit_signals
        if ! : > "$installed_marker"; then
            resume_generated_transaction_signals
            return 1
        fi
        if ! install_generated_file_no_clobber "$install_temp" "$destination"; then
            discard_temp_file "$installed_marker" || true
            resume_generated_transaction_signals
            return 1
        fi
        resume_generated_transaction_signals
    done < "$GENERATED_STAGED_SORTED"
}

abort_generated_manifest_transaction() {
    local abort_status=0

    if [[ "$GENERATED_TRANSACTION_COMMITTED" == true ]]; then
        cleanup_generated_manifest
        return $?
    fi
    if [[ -n "$GENERATED_ACTIVE_TEMP" ]] && ! discard_temp_file "$GENERATED_ACTIVE_TEMP"; then
        abort_status=1
    fi
    if ! rollback_generated_assets; then
        preserve_generated_recovery_workspace
        printf 'Generated asset transaction rollback was incomplete\n' >&2
        return 1
    fi
    if ! cleanup_generated_manifest; then
        abort_status=1
    fi
    return "$abort_status"
}

preserve_generated_recovery_workspace() {
    local recovery_workspace="$GENERATED_MANIFEST_WORKDIR"

    restore_generated_signal_traps
    GENERATED_MANIFEST_PATH=""
    GENERATED_MANIFEST_INDEX=""
    GENERATED_MANIFEST_RECORDS=""
    GENERATED_MANIFEST_WORKDIR=""
    GENERATED_STAGED_ASSETS=""
    GENERATED_STAGED_SORTED=""
    GENERATED_ROLLBACK_LOG=""
    GENERATED_TRANSACTION_COMMITTED=false
    GENERATED_MANIFEST_FAILED=false
    GENERATED_ACTIVE_TEMP=""
    printf 'Generated asset recovery workspace preserved: %s\n' "$recovery_workspace" >&2
}

rollback_failed_generated_transaction() {
    if ! rollback_generated_assets; then
        preserve_generated_recovery_workspace
        printf 'Generated asset transaction rollback was incomplete\n' >&2
        return 1
    fi
    cleanup_generated_manifest
}

yaml_double_quote() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

render_generated_manifest() {
    local sorted_records="$1"
    local temporary="$2"
    local path
    local source
    local runtime
    local kind
    local identifier
    local hash

    if ! printf 'version: 1\n' > "$temporary"; then
        return 1
    fi
    if [[ ! -s "$sorted_records" ]]; then
        if ! printf 'assets: []\n' >> "$temporary"; then
            return 1
        fi
        return 0
    fi
    if ! printf 'assets:\n' >> "$temporary"; then
        return 1
    fi
    while IFS=$'\t' read -r path source runtime kind identifier hash; do
        if ! printf '  - path: "%s"\n' "$(yaml_double_quote "$path")" >> "$temporary" ||
            ! printf '    source: "%s"\n' "$(yaml_double_quote "$source")" >> "$temporary" ||
            ! printf '    runtime: "%s"\n' "$(yaml_double_quote "$runtime")" >> "$temporary" ||
            ! printf '    kind: "%s"\n' "$(yaml_double_quote "$kind")" >> "$temporary" ||
            ! printf '    identifier: "%s"\n' "$(yaml_double_quote "$identifier")" >> "$temporary" ||
            ! printf '    sha256: "%s"\n' "$hash" >> "$temporary"; then
            return 1
        fi
    done < "$sorted_records"
}

finish_generated_manifest() {
    local sorted_records
    local manifest_dir
    local temporary

    if [[ "$GENERATED_MANIFEST_FAILED" == true ]]; then
        cleanup_generated_manifest
        return 1
    fi
    if [[ "${DRY_RUN:-false}" == true ]]; then
        cleanup_generated_manifest
        return 0
    fi

    sorted_records="$GENERATED_MANIFEST_WORKDIR/records.sorted.tsv"
    if ! LC_ALL=C sort -t $'\t' -k1,1 "$GENERATED_MANIFEST_RECORDS" > "$sorted_records"; then
        cleanup_generated_manifest
        return 1
    fi
    if ! install_staged_generated_assets; then
        if ! rollback_failed_generated_transaction; then
            : # Detailed rollback errors were already emitted.
        fi
        return 1
    fi
    manifest_dir="$(dirname "$GENERATED_MANIFEST_PATH")"
    if ! create_parent_directory "$GENERATED_MANIFEST_PATH"; then
        if ! rollback_failed_generated_transaction; then
            : # Detailed rollback errors were already emitted.
        fi
        return 1
    fi
    if ! temporary="$(create_sibling_temp "$GENERATED_MANIFEST_PATH")"; then
        printf 'Cannot create generated manifest temporary file in: %s\n' "$manifest_dir" >&2
        if ! rollback_failed_generated_transaction; then
            : # Detailed rollback errors were already emitted.
        fi
        return 1
    fi
    GENERATED_ACTIVE_TEMP="$temporary"
    if ! render_generated_manifest "$sorted_records" "$temporary"; then
        discard_temp_file "$temporary" || true
        if ! rollback_failed_generated_transaction; then
            : # Detailed rollback errors were already emitted.
        fi
        return 1
    fi
    mask_generated_commit_signals
    if ! commit_temp_file "$temporary" "$GENERATED_MANIFEST_PATH"; then
        resume_generated_transaction_signals
        if ! rollback_failed_generated_transaction; then
            : # Detailed rollback errors were already emitted.
        fi
        return 1
    fi
    GENERATED_TRANSACTION_COMMITTED=true
    resume_generated_transaction_signals
    if ! discard_generated_rollback_backups; then
        cleanup_generated_manifest
        return 1
    fi
    cleanup_generated_manifest
}

update_managed_block() {
    local path="$1"
    local body_file="$2"
    local start_marker='<!-- cyberpunk:start -->'
    local end_marker='<!-- cyberpunk:end -->'
    local start_count=0
    local end_count=0
    local start_line
    local end_line
    local path_dir
    local temporary
    local last_byte

    if [[ ! -f "$body_file" || -L "$body_file" ]]; then
        printf 'Managed block body is not a regular file: %s\n' "$body_file" >&2
        return 1
    fi

    if [[ -f "$path" ]]; then
        start_count="$(grep -Fxc "$start_marker" "$path" || true)"
        end_count="$(grep -Fxc "$end_marker" "$path" || true)"
    fi

    if [[ "$start_count" -eq 0 && "$end_count" -eq 0 ]]; then
        if [[ "${DRY_RUN:-false}" == true ]]; then
            return 0
        fi
        path_dir="$(dirname "$path")"
        if ! create_parent_directory "$path"; then
            return 1
        fi
        if ! temporary="$(create_sibling_temp "$path")"; then
            printf 'Cannot create managed block temporary file in: %s\n' "$path_dir" >&2
            return 1
        fi
        GENERATED_ACTIVE_TEMP="$temporary"
        if [[ -f "$path" ]]; then
            if ! cp "$path" "$temporary"; then
                discard_temp_file "$temporary" || true
                return 1
            fi
            if [[ -s "$path" ]]; then
                if ! last_byte="$(tail -c 1 "$path")"; then
                    discard_temp_file "$temporary" || true
                    return 1
                fi
                if [[ -n "$last_byte" ]]; then
                    if ! printf '\n\n' >> "$temporary"; then
                        discard_temp_file "$temporary" || true
                        return 1
                    fi
                else
                    if ! printf '\n' >> "$temporary"; then
                        discard_temp_file "$temporary" || true
                        return 1
                    fi
                fi
            fi
            if ! cat "$body_file" >> "$temporary"; then
                discard_temp_file "$temporary" || true
                return 1
            fi
        else
            if ! cp "$body_file" "$temporary"; then
                discard_temp_file "$temporary" || true
                return 1
            fi
        fi
    elif [[ "$start_count" -eq 1 && "$end_count" -eq 1 ]]; then
        start_line="$(grep -Fn "$start_marker" "$path" | cut -d: -f1)"
        end_line="$(grep -Fn "$end_marker" "$path" | cut -d: -f1)"
        if [[ "$start_line" -ge "$end_line" ]]; then
            printf 'Malformed managed markers in %s\n' "$path" >&2
            return 1
        fi
        if [[ "${DRY_RUN:-false}" == true ]]; then
            return 0
        fi
        path_dir="$(dirname "$path")"
        if ! create_parent_directory "$path"; then
            return 1
        fi
        if ! temporary="$(create_sibling_temp "$path")"; then
            printf 'Cannot create managed block temporary file in: %s\n' "$path_dir" >&2
            return 1
        fi
        GENERATED_ACTIVE_TEMP="$temporary"
        if [[ "$start_line" -gt 1 ]]; then
            if ! head -n "$((start_line - 1))" "$path" >> "$temporary"; then
                discard_temp_file "$temporary" || true
                return 1
            fi
        fi
        if ! cat "$body_file" >> "$temporary"; then
            discard_temp_file "$temporary" || true
            return 1
        fi
        if ! tail -n "+$((end_line + 1))" "$path" >> "$temporary"; then
            discard_temp_file "$temporary" || true
            return 1
        fi
    else
        printf 'Malformed managed markers in %s\n' "$path" >&2
        return 1
    fi

    if ! commit_temp_file "$temporary" "$path"; then
        return 1
    fi
}

ensure_codex_agent_settings() {
    local path="$1"
    local path_dir
    local temporary
    local agents_count
    local agents_line
    local key_line
    local next_table_line
    local last_byte

    if [[ ! -f "$path" ]]; then
        if [[ "${DRY_RUN:-false}" == true ]]; then
            return 0
        fi
        path_dir="$(dirname "$path")"
        if ! create_parent_directory "$path"; then
            return 1
        fi
        if ! temporary="$(create_sibling_temp "$path")"; then
            printf 'Cannot create Codex settings temporary file in: %s\n' "$path_dir" >&2
            return 1
        fi
        GENERATED_ACTIVE_TEMP="$temporary"
        if ! printf '%s\n' '[agents]' 'max_concurrent_threads_per_session = 3' > "$temporary"; then
            discard_temp_file "$temporary" || true
            return 1
        fi
        if ! commit_temp_file "$temporary" "$path"; then
            return 1
        fi
        return 0
    fi

    agents_count="$(grep -Ec '^[[:space:]]*\[agents\][[:space:]]*(#.*)?$' "$path" || true)"
    if [[ "$agents_count" -gt 1 ]]; then
        printf 'Malformed Codex settings: duplicate [agents] tables in %s\n' "$path" >&2
        return 1
    fi
    if [[ "$agents_count" -eq 0 ]]; then
        if [[ "${DRY_RUN:-false}" == true ]]; then
            return 0
        fi
        path_dir="$(dirname "$path")"
        if ! temporary="$(create_sibling_temp "$path")"; then
            printf 'Cannot create Codex settings temporary file in: %s\n' "$path_dir" >&2
            return 1
        fi
        GENERATED_ACTIVE_TEMP="$temporary"
        if ! cp "$path" "$temporary"; then
            discard_temp_file "$temporary" || true
            return 1
        fi
        if [[ -s "$path" ]]; then
            if ! last_byte="$(tail -c 1 "$path")"; then
                discard_temp_file "$temporary" || true
                return 1
            fi
            if [[ -n "$last_byte" ]]; then
                if ! printf '\n\n' >> "$temporary"; then
                    discard_temp_file "$temporary" || true
                    return 1
                fi
            else
                if ! printf '\n' >> "$temporary"; then
                    discard_temp_file "$temporary" || true
                    return 1
                fi
            fi
        fi
        if ! printf '%s\n' '[agents]' 'max_concurrent_threads_per_session = 3' >> "$temporary"; then
            discard_temp_file "$temporary" || true
            return 1
        fi
        if ! commit_temp_file "$temporary" "$path"; then
            return 1
        fi
        return 0
    fi

    agents_line="$(grep -En '^[[:space:]]*\[agents\][[:space:]]*(#.*)?$' "$path" | head -n 1 | cut -d: -f1)"
    key_line="$(awk -v start="$agents_line" '
        NR <= start { next }
        /^[[:space:]]*(\[[^]]+\]|\[\[[^]]+\]\])[[:space:]]*(#.*)?$/ { exit }
        /^[[:space:]]*max_concurrent_threads_per_session[[:space:]]*=/ { print NR; exit }
    ' "$path")"
    if [[ -n "$key_line" ]]; then
        return 0
    fi
    if [[ "${DRY_RUN:-false}" == true ]]; then
        return 0
    fi

    next_table_line="$(awk -v start="$agents_line" 'NR > start && /^[[:space:]]*(\[[^]]+\]|\[\[[^]]+\]\])[[:space:]]*(#.*)?$/ { print NR; exit }' "$path")"
    path_dir="$(dirname "$path")"
    if ! temporary="$(create_sibling_temp "$path")"; then
        printf 'Cannot create Codex settings temporary file in: %s\n' "$path_dir" >&2
        return 1
    fi
    GENERATED_ACTIVE_TEMP="$temporary"
    if [[ -n "$next_table_line" ]]; then
        if ! head -n "$((next_table_line - 1))" "$path" > "$temporary" ||
            ! printf '%s\n' 'max_concurrent_threads_per_session = 3' >> "$temporary" ||
            ! tail -n "+$next_table_line" "$path" >> "$temporary"; then
            discard_temp_file "$temporary" || true
            return 1
        fi
    else
        if ! cp "$path" "$temporary"; then
            discard_temp_file "$temporary" || true
            return 1
        fi
        if [[ -s "$path" ]]; then
            if ! last_byte="$(tail -c 1 "$path")"; then
                discard_temp_file "$temporary" || true
                return 1
            fi
            if [[ -n "$last_byte" ]] && ! printf '\n' >> "$temporary"; then
                discard_temp_file "$temporary" || true
                return 1
            fi
        fi
        if ! printf '%s\n' 'max_concurrent_threads_per_session = 3' >> "$temporary"; then
            discard_temp_file "$temporary" || true
            return 1
        fi
    fi
    if ! commit_temp_file "$temporary" "$path"; then
        return 1
    fi
}

validate_generated_manifest() {
    local manifest_path="$1"
    local validation_dir
    local records
    local project_root
    local path
    local source
    local runtime
    local kind
    local identifier
    local expected_hash
    local actual_hash
    local failures=0
    local load_status
    local cleanup_status=0

    [[ -f "$manifest_path" && ! -L "$manifest_path" ]] || {
        printf 'Generated asset manifest not found: %s\n' "$manifest_path" >&2
        return 1
    }
    if ! validation_dir="$(mktemp -d "${TMPDIR:-/tmp}/cyberpunk-validate-generated.XXXXXX")"; then
        printf 'Cannot create generated manifest validation directory\n' >&2
        return 1
    fi
    records="$validation_dir/records.tsv"
    if load_generated_manifest_records "$manifest_path" "$records"; then
        :
    else
        load_status=$?
        if [[ "$load_status" -eq 2 ]]; then
            printf 'Unsupported generated asset manifest version: %s\n' "$manifest_path" >&2
        else
            printf 'Malformed generated asset manifest: %s\n' "$manifest_path" >&2
        fi
        rm -f "$records" || true
        rmdir "$validation_dir" 2>/dev/null || true
        return 1
    fi
    if ! awk -F '\t' '!/^[[:space:]]*$/ && seen[$1]++ { exit 1 }' "$records"; then
        printf 'Duplicate generated asset path in manifest: %s\n' "$manifest_path" >&2
        rm -f "$records" || true
        rmdir "$validation_dir" 2>/dev/null || true
        return 1
    fi
    if ! project_root="$(cd "$(dirname "$manifest_path")/.." && pwd)"; then
        rm -f "$records" || true
        rmdir "$validation_dir" 2>/dev/null || true
        return 1
    fi

    while IFS=$'\t' read -r path source runtime kind identifier expected_hash; do
        [[ -n "$path" ]] || continue
        if [[ ! "$expected_hash" =~ ^[0-9a-f]{64}$ ]]; then
            printf 'Invalid generated asset SHA-256: %s\n' "$path" >&2
            failures=$((failures + 1))
        elif [[ ! -f "$project_root/$path" || -L "$project_root/$path" ]]; then
            printf 'Missing generated asset: %s\n' "$path" >&2
            failures=$((failures + 1))
        else
            actual_hash="$(sha256_file "$project_root/$path")" || failures=$((failures + 1))
            if [[ "$actual_hash" != "$expected_hash" ]]; then
                printf 'Stale generated asset hash: %s\n' "$path" >&2
                failures=$((failures + 1))
            fi
        fi
    done < "$records"
    rm -f "$records" || cleanup_status=1
    rmdir "$validation_dir" 2>/dev/null || cleanup_status=1
    if [[ "$cleanup_status" -ne 0 ]]; then
        printf 'Cannot clean generated manifest validation directory: %s\n' "$validation_dir" >&2
        return 1
    fi
    [[ "$failures" -eq 0 ]]
}
