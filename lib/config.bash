#!/usr/bin/env bash

SUPPORTED_RUNTIMES=(codex claude cursor)
ROLE_IDS=(nexus fixer operator mind interrogator fragmenter coder daemon neon grid-master gatekeeper)

strip_config_scalar() {
    local value="$1"

    value="$(printf '%s' "$value" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    value="${value#\"}"
    value="${value%\"}"
    printf '%s\n' "$value"
}

normalize_runtime_selection() {
    local requested="${*:-all}"
    local runtime
    local token
    local valid

    for token in $requested; do
        valid=false
        for runtime in all "${SUPPORTED_RUNTIMES[@]}"; do
            if [[ "$token" == "$runtime" ]]; then
                valid=true
                break
            fi
        done
        if [[ "$valid" != true ]]; then
            printf 'Unknown runtime: %s\n' "$token" >&2
            return 1
        fi
    done

    [[ " $requested " == *" all "* ]] && requested="codex claude cursor"
    for runtime in "${SUPPORTED_RUNTIMES[@]}"; do
        [[ " $requested " == *" $runtime "* ]] && printf '%s\n' "$runtime"
    done
    return 0
}

configured_list() {
    local config_path="$1"
    local section="$2"
    local key="$3"

    awk -v section="$section" -v key="$key" '
        function trim(value) {
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            return value
        }
        $0 == section ":" { in_section=1; next }
        in_section && /^[^[:space:]]/ { exit }
        in_section && $0 ~ "^[[:space:]]+" key ":[[:space:]]*" {
            value=$0
            sub("^[[:space:]]+" key ":[[:space:]]*", "", value)
            value=trim(value)
            if (value != "") {
                gsub(/^\[/, "", value)
                gsub(/\]$/, "", value)
                gsub(/,/, " ", value)
                print value
            } else {
                in_list=1
            }
            next
        }
        in_section && in_list && $0 ~ /^[[:space:]]+-[[:space:]]*/ {
            value=$0
            sub(/^[[:space:]]+-[[:space:]]*/, "", value)
            print value
            next
        }
        in_section && in_list { exit }
    ' "$config_path" | while IFS= read -r item; do
        for item in $item; do
            strip_config_scalar "$item"
        done
    done
}

configured_runtimes() {
    configured_list "$1" runtimes enabled
}

configured_project_skills() {
    configured_list "$1" skills enabled_project | LC_ALL=C sort -u
}

config_has_section() {
    local config_path="$1"
    local section="$2"

    grep -Fqx "${section}:" "$config_path"
}

append_v2_section() {
    local section="$1"

    case "$section" in
        runtimes)
            cat <<'EOF'
runtimes:
  enabled: [codex, claude, cursor]
EOF
            ;;
        execution)
            cat <<'EOF'
execution:
  parallelism: auto
  max_concurrent_agents: 3
  unavailable_runtime_fallback: sequential
EOF
            ;;
        models)
            cat <<'EOF'
models:
  fallback: inherit
  profiles:
    deep:
      codex: "gpt-5.6-sol"
      claude: "opus"
      cursor: "gpt-5.6-sol"
    balanced:
      codex: "gpt-5.6-terra"
      claude: "sonnet"
      cursor: "composer-2.5[]"
    fast:
      codex: "gpt-5.6-luna"
      claude: "haiku"
      cursor: "composer-2.5"
  roles:
    nexus: deep
    fixer: deep
    operator: fast
    mind: deep
    interrogator: deep
    fragmenter: balanced
    coder: balanced
    daemon: balanced
    neon: balanced
    grid-master: balanced
    gatekeeper: deep
  overrides: {}
EOF
            ;;
    esac
}

migrate_config_v1() {
    local config_path="$1"
    local config_dir
    local temp_path
    local version
    local section
    local found_version=false

    [[ -f "$config_path" ]] || {
        printf 'Configuration not found: %s\n' "$config_path" >&2
        return 1
    }

    version="$(awk '/^version:[[:space:]]*/ { sub(/^version:[[:space:]]*/, ""); print; exit }' "$config_path")"
    case "$version" in
        2)
            return 0
            ;;
        1)
            ;;
        *)
            printf 'Unsupported configuration version: %s\n' "${version:-missing}" >&2
            return 1
            ;;
    esac

    if [[ "${DRY_RUN:-false}" == true ]]; then
        return 0
    fi

    config_dir="$(dirname "$config_path")"
    temp_path="$config_dir/.config.yml.tmp.$$"
    trap 'rm -f "$temp_path"' RETURN

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$found_version" == false && "$line" == "version: 1" ]]; then
            printf 'version: 2\n' >> "$temp_path"
            found_version=true
        else
            printf '%s\n' "$line" >> "$temp_path"
        fi
    done < "$config_path"

    for section in runtimes execution models; do
        if ! config_has_section "$config_path" "$section"; then
            printf '\n' >> "$temp_path"
            append_v2_section "$section" >> "$temp_path"
        fi
    done

    mv "$temp_path" "$config_path"
    trap - RETURN
}

write_configured_runtimes() {
    local config_path="$1"
    shift
    local selected
    local runtime
    local temp_path
    local config_dir
    local enabled=""

    [[ -f "$config_path" ]] || {
        printf 'Configuration not found: %s\n' "$config_path" >&2
        return 1
    }

    selected="$(normalize_runtime_selection "$@")" || return 1
    while IFS= read -r runtime; do
        [[ -n "$runtime" ]] || continue
        if [[ -n "$enabled" ]]; then
            enabled="$enabled, $runtime"
        else
            enabled="$runtime"
        fi
    done <<EOF
$selected
EOF

    if [[ "${DRY_RUN:-false}" == true ]]; then
        return 0
    fi

    config_dir="$(dirname "$config_path")"
    temp_path="$config_dir/.config.yml.tmp.$$"
    trap 'rm -f "$temp_path"' RETURN
    awk -v enabled="$enabled" '
        $0 == "runtimes:" { in_runtimes=1 }
        in_runtimes && $0 ~ /^  enabled:[[:space:]]*/ {
            print "  enabled: [" enabled "]"
            value=$0
            sub(/^  enabled:[[:space:]]*/, "", value)
            if (value == "") skip_list=1
            next
        }
        skip_list && $0 ~ /^    -[[:space:]]*/ { next }
        skip_list { skip_list=0 }
        { print }
    ' "$config_path" > "$temp_path"
    mv "$temp_path" "$config_path"
    trap - RETURN
}

merge_configured_runtimes() {
    local config_path="$1"
    shift
    local current

    current="$(configured_runtimes "$config_path" | tr '\n' ' ')"
    write_configured_runtimes "$config_path" $current "$@"
}

role_profile() {
    local config_path="$1"
    local role="$2"

    awk -v role="$role" '
        $0 == "models:" { in_models=1; next }
        in_models && /^[^[:space:]]/ { exit }
        in_models && $0 == "  roles:" { in_roles=1; next }
        in_roles && /^  [^[:space:]][^:]*:/ { exit }
        in_roles && $0 ~ "^    " role ":[[:space:]]*" {
            value=$0
            sub("^    " role ":[[:space:]]*", "", value)
            print value
            exit
        }
    ' "$config_path" | while IFS= read -r value; do strip_config_scalar "$value"; done
}

profile_model() {
    local config_path="$1"
    local profile="$2"
    local runtime="$3"

    awk -v profile="$profile" -v runtime="$runtime" '
        $0 == "models:" { in_models=1; next }
        in_models && /^[^[:space:]]/ { exit }
        in_models && $0 == "  profiles:" { in_profiles=1; next }
        in_profiles && /^    [^[:space:]][^:]*:/ {
            current=$0
            sub(/^    /, "", current)
            sub(/:.*/, "", current)
            next
        }
        in_profiles && $0 ~ "^      " runtime ":[[:space:]]*" && current == profile {
            value=$0
            sub("^      " runtime ":[[:space:]]*", "", value)
            print value
            exit
        }
    ' "$config_path" | while IFS= read -r value; do strip_config_scalar "$value"; done
}

role_model_override() {
    local config_path="$1"
    local role="$2"
    local runtime="$3"

    awk -v role="$role" -v runtime="$runtime" '
        $0 == "models:" { in_models=1; next }
        in_models && /^[^[:space:]]/ { exit }
        in_models && $0 == "  overrides:" { in_overrides=1; next }
        in_overrides && /^    [^[:space:]][^:]*:/ {
            current=$0
            sub(/^    /, "", current)
            sub(/:.*/, "", current)
            next
        }
        in_overrides && $0 ~ "^      " runtime ":[[:space:]]*" && current == role {
            value=$0
            sub("^      " runtime ":[[:space:]]*", "", value)
            print value
            exit
        }
    ' "$config_path" | while IFS= read -r value; do strip_config_scalar "$value"; done
}

role_override_profile() {
    local config_path="$1"
    local role="$2"

    awk -v role="$role" '
        $0 == "models:" { in_models=1; next }
        in_models && /^[^[:space:]]/ { exit }
        in_models && $0 == "  overrides:" { in_overrides=1; next }
        in_overrides && /^    [^[:space:]][^:]*:/ {
            current=$0
            sub(/^    /, "", current)
            sub(/:.*/, "", current)
            next
        }
        in_overrides && /^      profile:[[:space:]]*/ && current == role {
            value=$0
            sub(/^      profile:[[:space:]]*/, "", value)
            print value
            exit
        }
    ' "$config_path" | while IFS= read -r value; do strip_config_scalar "$value"; done
}

resolve_role_model() {
    local config_path="$1"
    local role="$2"
    local runtime="$3"
    local model
    local profile

    model="$(role_model_override "$config_path" "$role" "$runtime")"
    [[ -n "$model" ]] && {
        printf '%s\n' "$model"
        return 0
    }

    profile="$(role_model_override "$config_path" "$role" profile)"
    [[ -n "$profile" ]] || profile="$(role_profile "$config_path" "$role")"
    model="$(profile_model "$config_path" "$profile" "$runtime")"
    [[ -n "$model" ]] && printf '%s\n' "$model" || printf '%s\n' inherit
}

model_fallback() {
    local config_path="$1"

    awk '
        $0 == "models:" { in_models=1; next }
        in_models && /^[^[:space:]]/ { exit }
        in_models && /^  fallback:[[:space:]]*/ {
            value=$0
            sub(/^  fallback:[[:space:]]*/, "", value)
            print value
            exit
        }
    ' "$config_path" | while IFS= read -r value; do strip_config_scalar "$value"; done
}

execution_setting() {
    local config_path="$1"
    local key="$2"

    awk -v key="$key" '
        $0 == "execution:" { in_execution=1; next }
        in_execution && /^[^[:space:]]/ { exit }
        in_execution && $0 ~ "^  " key ":[[:space:]]*" {
            value=$0
            sub("^  " key ":[[:space:]]*", "", value)
            print value
            exit
        }
    ' "$config_path" | while IFS= read -r value; do strip_config_scalar "$value"; done
}

validate_runtime_configuration() {
    local config_path="$1"
    local runtime
    local known
    local duplicate=false
    local count=0
    local maximum
    local parallelism
    local errors=0
    local seen=" "

    while IFS= read -r runtime; do
        [[ -n "$runtime" ]] || continue
        count=$((count + 1))
        known=false
        for known_runtime in "${SUPPORTED_RUNTIMES[@]}"; do
            [[ "$runtime" == "$known_runtime" ]] && known=true
        done
        if [[ "$known" != true ]]; then
            printf 'Unknown configured runtime: %s\n' "$runtime" >&2
            errors=$((errors + 1))
        fi
        if [[ "$seen" == *" $runtime "* ]]; then
            printf 'Duplicate configured runtime: %s\n' "$runtime" >&2
            errors=$((errors + 1))
        else
            seen="$seen$runtime "
        fi
    done < <(configured_runtimes "$config_path")
    if [[ "$count" -eq 0 ]]; then
        printf 'Missing configured runtimes\n' >&2
        errors=$((errors + 1))
    fi

    maximum="$(execution_setting "$config_path" max_concurrent_agents)"
    if [[ ! "$maximum" =~ ^[0-9]+$ ]] || [[ "$maximum" -lt 1 || "$maximum" -gt 3 ]]; then
        printf 'max_concurrent_agents must be an integer from 1 to 3 (got: %s)\n' "${maximum:-missing}" >&2
        errors=$((errors + 1))
    fi
    parallelism="$(execution_setting "$config_path" parallelism)"
    if [[ "$parallelism" != auto && "$parallelism" != sequential ]]; then
        printf 'parallelism must be auto or sequential (got: %s)\n' "${parallelism:-missing}" >&2
        errors=$((errors + 1))
    fi
    [[ "$errors" -eq 0 ]]
}

validate_model_configuration() {
    local config_path="$1"
    local role
    local runtime
    local profile
    local override_profile
    local model
    local fallback
    local error_count=0
    local profiles=(deep balanced fast)

    fallback="$(model_fallback "$config_path")"
    if [[ "$fallback" != inherit ]]; then
        printf 'Model fallback must be inherit\n' >&2
        error_count=$((error_count + 1))
    fi

    for role in "${ROLE_IDS[@]}"; do
        role_count="$(awk -v role="$role" '
            $0 == "models:" { in_models=1; next }
            in_models && /^[^[:space:]]/ { exit }
            in_models && $0 == "  roles:" { in_roles=1; next }
            in_roles && /^  [^[:space:]][^:]*:/ { exit }
            in_roles && $0 ~ "^    " role ":[[:space:]]*" { count++ }
            END { print count + 0 }
        ' "$config_path")"
        if [[ "$role_count" -ne 1 ]]; then
            printf 'Model role must appear exactly once: %s\n' "$role" >&2
            error_count=$((error_count + 1))
        fi
        profile="$(role_profile "$config_path" "$role")"
        if [[ -z "$profile" ]]; then
            printf 'Missing model profile for role: %s\n' "$role" >&2
            error_count=$((error_count + 1))
        else
            case "$profile" in
                deep|balanced|fast) ;;
                *)
                    printf 'Invalid model profile for role %s: %s\n' "$role" "$profile" >&2
                    error_count=$((error_count + 1))
                    ;;
            esac
        fi

        override_profile="$(role_model_override "$config_path" "$role" profile)"
        if [[ -n "$override_profile" ]]; then
            case "$override_profile" in
                deep|balanced|fast) ;;
                *)
                    printf 'Invalid model override profile for %s: %s\n' "$role" "$override_profile" >&2
                    error_count=$((error_count + 1))
                    ;;
            esac
        fi
    done

    for profile in "${profiles[@]}"; do
        while IFS= read -r runtime; do
            [[ -n "$runtime" ]] || continue
            model="$(profile_model "$config_path" "$profile" "$runtime")"
            if [[ -z "$model" ]]; then
                printf 'Missing %s model mapping for profile: %s\n' "$runtime" "$profile" >&2
                error_count=$((error_count + 1))
            fi
        done < <(configured_runtimes "$config_path")
    done

    [[ "$error_count" -eq 0 ]]
}
