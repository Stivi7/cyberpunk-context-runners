#!/usr/bin/env bash

GENERATED_MANIFEST_PATH=""
GENERATED_MANIFEST_INDEX=""
GENERATED_MANIFEST_RECORDS=""
GENERATED_MANIFEST_WORKDIR=""
GENERATED_MANIFEST_FAILED=false

sha256_file() {
    local path="$1"

    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$path" | awk '{ print $1 }'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$path" | awk '{ print $1 }'
    else
        printf 'No SHA-256 tool found; install shasum or sha256sum\n' >&2
        return 1
    fi
}

load_generated_manifest_records() {
    local manifest_path="$1"
    local records_path="$2"

    awk '
        BEGIN { OFS="\t" }
        function scalar(line) {
            sub(/^[^:]*:[[:space:]]*/, "", line)
            if (line ~ /^".*"$/) {
                sub(/^"/, "", line)
                sub(/"$/, "", line)
            }
            return line
        }
        function flush_record() {
            if (!record_started) return
            if (path == "" || source == "" || runtime == "" || kind == "" || identifier == "" || sha256 == "") {
                invalid=1
                return
            }
            print path, source, runtime, kind, identifier, sha256
        }
        /^  - path:[[:space:]]*/ {
            flush_record()
            path=scalar($0)
            source=runtime=kind=identifier=sha256=""
            record_started=1
            next
        }
        record_started && /^    source:[[:space:]]*/ { source=scalar($0); next }
        record_started && /^    runtime:[[:space:]]*/ { runtime=scalar($0); next }
        record_started && /^    kind:[[:space:]]*/ { kind=scalar($0); next }
        record_started && /^    identifier:[[:space:]]*/ { identifier=scalar($0); next }
        record_started && /^    sha256:[[:space:]]*/ { sha256=scalar($0); next }
        END {
            flush_record()
            if (invalid) exit 1
        }
    ' "$manifest_path" > "$records_path"
}

cleanup_generated_manifest() {
    if [[ -n "$GENERATED_MANIFEST_WORKDIR" && -d "$GENERATED_MANIFEST_WORKDIR" ]]; then
        rm -f \
            "$GENERATED_MANIFEST_WORKDIR/index.tsv" \
            "$GENERATED_MANIFEST_WORKDIR/records.tsv" \
            "$GENERATED_MANIFEST_WORKDIR/records.updated.tsv" \
            "$GENERATED_MANIFEST_WORKDIR/records.sorted.tsv"
        rmdir "$GENERATED_MANIFEST_WORKDIR" 2>/dev/null || true
    fi
    GENERATED_MANIFEST_PATH=""
    GENERATED_MANIFEST_INDEX=""
    GENERATED_MANIFEST_RECORDS=""
    GENERATED_MANIFEST_WORKDIR=""
    GENERATED_MANIFEST_FAILED=false
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
    GENERATED_MANIFEST_WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/cyberpunk-generated.XXXXXX")"
    GENERATED_MANIFEST_INDEX="$GENERATED_MANIFEST_WORKDIR/index.tsv"
    GENERATED_MANIFEST_RECORDS="$GENERATED_MANIFEST_WORKDIR/records.tsv"
    : > "$GENERATED_MANIFEST_INDEX"
    : > "$GENERATED_MANIFEST_RECORDS"

    if [[ -f "$manifest_path" ]]; then
        if ! load_generated_manifest_records "$manifest_path" "$GENERATED_MANIFEST_INDEX"; then
            printf 'Malformed generated asset manifest: %s\n' "$manifest_path" >&2
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
        if [[ -f "$record_path" ]]; then
            printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$record_path" "$record_source" "$record_runtime" "$record_kind" "$record_identifier" "$record_hash" \
                >> "$GENERATED_MANIFEST_RECORDS"
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
    local updated="$GENERATED_MANIFEST_WORKDIR/records.updated.tsv"

    awk -F '\t' -v path="$path" '$1 != path' "$GENERATED_MANIFEST_RECORDS" > "$updated"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$path" "$source" "$runtime" "$kind" "$identifier" "$hash" >> "$updated"
    mv "$updated" "$GENERATED_MANIFEST_RECORDS"
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
    mkdir -p "$destination_dir"
    temporary="$destination_dir/.$(basename "$destination").tmp.$$"
    cp "$content_file" "$temporary"
    mv "$temporary" "$destination"
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

    if [[ -z "$GENERATED_MANIFEST_PATH" ]]; then
        printf 'Generated asset manifest has not been started\n' >&2
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
    prior_record="$(awk -F '\t' -v path="$relative_path" '$1 == path { print; exit }' "$GENERATED_MANIFEST_INDEX")"
    if [[ -n "$prior_record" ]]; then
        IFS=$'\t' read -r prior_path prior_source prior_runtime prior_kind prior_identifier prior_hash <<EOF
$prior_record
EOF
    fi

    if [[ ! -f "$destination" ]]; then
        replace_generated_file "$destination" "$content_file"
    elif [[ -z "$prior_path" ]]; then
        printf 'Generated asset collision: %s is not owned by Cyberpunk\n' "$relative_path" >&2
        GENERATED_MANIFEST_FAILED=true
        return 1
    else
        actual_hash="$(sha256_file "$destination")" || {
            GENERATED_MANIFEST_FAILED=true
            return 1
        }
        if [[ "$actual_hash" != "$prior_hash" && "${FORCE:-false}" != true ]]; then
            printf 'Generated asset drift: %s was modified locally; rerun with --force to replace it\n' "$relative_path" >&2
            GENERATED_MANIFEST_FAILED=true
            return 1
        fi
        if [[ "$actual_hash" != "$desired_hash" ]]; then
            replace_generated_file "$destination" "$content_file"
        fi
    fi

    record_generated_asset "$relative_path" "$source" "$runtime" "$kind" "$identifier" "$desired_hash"
}

yaml_double_quote() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

finish_generated_manifest() {
    local sorted_records
    local manifest_dir
    local temporary
    local path
    local source
    local runtime
    local kind
    local identifier
    local hash

    if [[ "$GENERATED_MANIFEST_FAILED" == true ]]; then
        cleanup_generated_manifest
        return 1
    fi
    if [[ "${DRY_RUN:-false}" == true ]]; then
        cleanup_generated_manifest
        return 0
    fi

    sorted_records="$GENERATED_MANIFEST_WORKDIR/records.sorted.tsv"
    LC_ALL=C sort -t $'\t' -k1,1 "$GENERATED_MANIFEST_RECORDS" > "$sorted_records"
    manifest_dir="$(dirname "$GENERATED_MANIFEST_PATH")"
    mkdir -p "$manifest_dir"
    temporary="$manifest_dir/.$(basename "$GENERATED_MANIFEST_PATH").tmp.$$"

    printf 'version: 1\n' > "$temporary"
    if [[ ! -s "$sorted_records" ]]; then
        printf 'assets: []\n' >> "$temporary"
    else
        printf 'assets:\n' >> "$temporary"
        while IFS=$'\t' read -r path source runtime kind identifier hash; do
            printf '  - path: "%s"\n' "$(yaml_double_quote "$path")" >> "$temporary"
            printf '    source: "%s"\n' "$(yaml_double_quote "$source")" >> "$temporary"
            printf '    runtime: "%s"\n' "$(yaml_double_quote "$runtime")" >> "$temporary"
            printf '    kind: "%s"\n' "$(yaml_double_quote "$kind")" >> "$temporary"
            printf '    identifier: "%s"\n' "$(yaml_double_quote "$identifier")" >> "$temporary"
            printf '    sha256: "%s"\n' "$hash" >> "$temporary"
        done < "$sorted_records"
    fi

    if [[ -f "$GENERATED_MANIFEST_PATH" ]] && cmp -s "$temporary" "$GENERATED_MANIFEST_PATH"; then
        rm -f "$temporary"
    else
        mv "$temporary" "$GENERATED_MANIFEST_PATH"
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

    if [[ -f "$path" ]]; then
        start_count="$(grep -Fxc "$start_marker" "$path" || true)"
        end_count="$(grep -Fxc "$end_marker" "$path" || true)"
    fi

    if [[ "$start_count" -eq 0 && "$end_count" -eq 0 ]]; then
        if [[ "${DRY_RUN:-false}" == true ]]; then
            return 0
        fi
        path_dir="$(dirname "$path")"
        mkdir -p "$path_dir"
        temporary="$path_dir/.$(basename "$path").tmp.$$"
        if [[ -f "$path" ]]; then
            cp "$path" "$temporary"
            if [[ -s "$path" ]]; then
                last_byte="$(tail -c 1 "$path")"
                if [[ -n "$last_byte" ]]; then
                    printf '\n\n' >> "$temporary"
                else
                    printf '\n' >> "$temporary"
                fi
            fi
            cat "$body_file" >> "$temporary"
        else
            cp "$body_file" "$temporary"
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
        temporary="$path_dir/.$(basename "$path").tmp.$$"
        : > "$temporary"
        if [[ "$start_line" -gt 1 ]]; then
            head -n "$((start_line - 1))" "$path" >> "$temporary"
        fi
        cat "$body_file" >> "$temporary"
        tail -n "+$((end_line + 1))" "$path" >> "$temporary"
    else
        printf 'Malformed managed markers in %s\n' "$path" >&2
        return 1
    fi

    if [[ -f "$path" ]] && cmp -s "$temporary" "$path"; then
        rm -f "$temporary"
    else
        mv "$temporary" "$path"
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
        mkdir -p "$path_dir"
        printf '%s\n' '[agents]' 'max_concurrent_threads_per_session = 3' > "$path"
        return 0
    fi

    agents_count="$(grep -Ec '^[[:space:]]*\[agents\][[:space:]]*$' "$path" || true)"
    if [[ "$agents_count" -gt 1 ]]; then
        printf 'Malformed Codex settings: duplicate [agents] tables in %s\n' "$path" >&2
        return 1
    fi
    if [[ "$agents_count" -eq 0 ]]; then
        if [[ "${DRY_RUN:-false}" == true ]]; then
            return 0
        fi
        path_dir="$(dirname "$path")"
        temporary="$path_dir/.$(basename "$path").tmp.$$"
        cp "$path" "$temporary"
        if [[ -s "$path" ]]; then
            last_byte="$(tail -c 1 "$path")"
            if [[ -n "$last_byte" ]]; then
                printf '\n\n' >> "$temporary"
            else
                printf '\n' >> "$temporary"
            fi
        fi
        printf '%s\n' '[agents]' 'max_concurrent_threads_per_session = 3' >> "$temporary"
        mv "$temporary" "$path"
        return 0
    fi

    agents_line="$(grep -En '^[[:space:]]*\[agents\][[:space:]]*$' "$path" | head -n 1 | cut -d: -f1)"
    key_line="$(awk -v start="$agents_line" '
        NR <= start { next }
        /^[[:space:]]*\[[^]]+\][[:space:]]*$/ { exit }
        /^[[:space:]]*max_concurrent_threads_per_session[[:space:]]*=/ { print NR; exit }
    ' "$path")"
    if [[ -n "$key_line" ]]; then
        return 0
    fi
    if [[ "${DRY_RUN:-false}" == true ]]; then
        return 0
    fi

    next_table_line="$(awk -v start="$agents_line" 'NR > start && /^[[:space:]]*\[[^]]+\][[:space:]]*$/ { print NR; exit }' "$path")"
    path_dir="$(dirname "$path")"
    temporary="$path_dir/.$(basename "$path").tmp.$$"
    if [[ -n "$next_table_line" ]]; then
        head -n "$((next_table_line - 1))" "$path" > "$temporary"
        printf '%s\n' 'max_concurrent_threads_per_session = 3' >> "$temporary"
        tail -n "+$next_table_line" "$path" >> "$temporary"
    else
        cp "$path" "$temporary"
        if [[ -s "$path" ]]; then
            last_byte="$(tail -c 1 "$path")"
            [[ -z "$last_byte" ]] || printf '\n' >> "$temporary"
        fi
        printf '%s\n' 'max_concurrent_threads_per_session = 3' >> "$temporary"
    fi
    mv "$temporary" "$path"
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

    [[ -f "$manifest_path" ]] || {
        printf 'Generated asset manifest not found: %s\n' "$manifest_path" >&2
        return 1
    }
    validation_dir="$(mktemp -d "${TMPDIR:-/tmp}/cyberpunk-validate-generated.XXXXXX")"
    records="$validation_dir/records.tsv"
    if ! load_generated_manifest_records "$manifest_path" "$records"; then
        printf 'Malformed generated asset manifest: %s\n' "$manifest_path" >&2
        rm -f "$records"
        rmdir "$validation_dir" 2>/dev/null || true
        return 1
    fi
    project_root="$(cd "$(dirname "$manifest_path")/.." && pwd)"

    while IFS=$'\t' read -r path source runtime kind identifier expected_hash; do
        [[ -n "$path" ]] || continue
        if [[ ! "$expected_hash" =~ ^[0-9a-f]{64}$ ]]; then
            printf 'Invalid generated asset SHA-256: %s\n' "$path" >&2
            failures=$((failures + 1))
        elif [[ ! -f "$project_root/$path" ]]; then
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
    rm -f "$records"
    rmdir "$validation_dir" 2>/dev/null || true
    [[ "$failures" -eq 0 ]]
}
