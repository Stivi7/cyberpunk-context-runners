#!/usr/bin/env bash

# Capture the physical invocation directory. Runtime, generated, managed, and
# configuration destinations are project-relative to this root.
CYBERPUNK_PROJECT_PHYSICAL_ROOT="$(pwd -P)"
CYBERPUNK_CONFINED_PROJECT_PATH=""

normalize_project_destination() {
    local input="$1"
    local relative="$input"
    local remaining
    local component
    local normalized=""

    case "$relative" in
        "$CYBERPUNK_PROJECT_PHYSICAL_ROOT") relative="." ;;
        "$CYBERPUNK_PROJECT_PHYSICAL_ROOT"/*)
            relative="${relative#"$CYBERPUNK_PROJECT_PHYSICAL_ROOT"/}"
            ;;
        /*)
            printf 'Refusing project destination outside physical project root: %s\n' "$input" >&2
            return 1
            ;;
    esac

    case "$relative" in
        *$'\n'*|*$'\r'*|*$'\t'*)
            printf 'Refusing malformed project destination: %s\n' "$input" >&2
            return 1
            ;;
    esac

    remaining="$relative"
    while :; do
        case "$remaining" in
            */*)
                component="${remaining%%/*}"
                remaining="${remaining#*/}"
                ;;
            *)
                component="$remaining"
                remaining=""
                ;;
        esac
        case "$component" in
            ""|.) ;;
            ..)
                printf 'Refusing project destination with parent traversal: %s\n' "$input" >&2
                return 1
                ;;
            *)
                if [[ -n "$normalized" ]]; then
                    normalized="$normalized/$component"
                else
                    normalized="$component"
                fi
                ;;
        esac
        [[ -n "$remaining" ]] || break
    done

    [[ -n "$normalized" ]] || normalized="."
    CYBERPUNK_CONFINED_PROJECT_PATH="$normalized"
}

require_confined_project_destination() {
    local input="$1"
    local relative
    local remaining
    local component
    local candidate="$CYBERPUNK_PROJECT_PHYSICAL_ROOT"
    local display=""
    local physical

    normalize_project_destination "$input" || return 1
    relative="$CYBERPUNK_CONFINED_PROJECT_PATH"
    [[ "$relative" != . ]] || return 0

    remaining="$relative"
    while :; do
        case "$remaining" in
            */*)
                component="${remaining%%/*}"
                remaining="${remaining#*/}"
                ;;
            *)
                component="$remaining"
                remaining=""
                ;;
        esac
        candidate="$candidate/$component"
        if [[ -n "$display" ]]; then
            display="$display/$component"
        else
            display="$component"
        fi

        if [[ -L "$candidate" ]]; then
            printf 'Refusing project destination through symlinked component: %s (collision)\n' "$display" >&2
            return 1
        fi
        if [[ -e "$candidate" && -n "$remaining" && ! -d "$candidate" ]]; then
            printf 'Refusing project destination through non-directory component: %s\n' "$display" >&2
            return 1
        fi
        if [[ -d "$candidate" ]]; then
            physical="$(cd -P "$candidate" && pwd -P)" || return 1
            case "$physical" in
                "$CYBERPUNK_PROJECT_PHYSICAL_ROOT"|"$CYBERPUNK_PROJECT_PHYSICAL_ROOT"/*) ;;
                *)
                    printf 'Refusing project destination outside physical project root: %s\n' "$input" >&2
                    return 1
                    ;;
            esac
        fi
        [[ -n "$remaining" ]] || break
    done
}

create_confined_project_sibling_temp() {
    local destination="$1"
    local directory
    local basename_value

    require_confined_project_destination "$destination" || return 1
    directory="$(dirname "$destination")"
    basename_value="$(basename "$destination")"
    mktemp "$directory/.$basename_value.tmp.XXXXXX"
}
