#!/bin/bash
# Parses docket/SKILL.md's "## Complete Command & Flag Reference" section into
# a per-subcommand documented-flag map (one entry per `#{3,4} \`docket ...\``
# heading, expanding "add/rm/list/delete"-style multi-verb headings and
# "Command"-column tables (issue label, doc link) into one entry per verb),
# runs `docket <cmd> --help` for each documented subcommand, and reports any
# flag present in one source but not the other. Read-only; never edits
# SKILL.md. Mechanizes the ground-truth check the SKILL.md intro references
# (see the "flag reference is complete and current" callout) instead of
# relying on manual re-reading after a docket CLI upgrade.
#
# Deliberately bash 3.2 compatible (this host's /bin/bash) -- no associative
# arrays, no namerefs, no mapfile/readarray.
set -uo pipefail

usage() {
    echo "Usage: docket_ref_check.sh [skill-md-path]" >&2
    echo "  Diffs docket/SKILL.md's flag tables against the installed docket" >&2
    echo "  CLI's --help output, per documented subcommand. Prints one DRIFT" >&2
    echo "  line per mismatch and exits nonzero if any subcommand drifted." >&2
    echo "  Default skill-md-path: src/user/claude-code/skills/docket/SKILL.md" >&2
    echo "  (repo-root-relative)." >&2
    exit 1
}

if [ "$#" -gt 1 ]; then
    usage
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "docket_ref_check.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

SKILL_MD="${1:-src/user/claude-code/skills/docket/SKILL.md}"

if [ ! -f "$SKILL_MD" ]; then
    echo "docket_ref_check.sh: file not found: ${SKILL_MD}" >&2
    exit 1
fi

if ! command -v docket >/dev/null 2>&1; then
    echo "docket_ref_check.sh: 'docket' binary not found in PATH" >&2
    exit 1
fi

SECTION_HEADING="Complete Command & Flag Reference"
SPEC_PATTERN='`docket [^`]+`'
PLACEHOLDER=$'\x01'

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# Splits a markdown table row "$1" into the global array CELLS, trimmed.
# Escaped pipes ("\|", used in enum-list Notes cells) are protected from
# the column split so they don't shift later columns.
split_row() {
    local row
    row="$(trim "$1")"
    row="${row//\\|/$PLACEHOLDER}"
    row="${row#|}"
    row="${row%|}"
    local IFS='|'
    CELLS=()
    read -ra CELLS <<< "$row"
    local k
    for ((k = 0; k < ${#CELLS[@]}; k++)); do
        CELLS[$k]="$(trim "${CELLS[$k]//$PLACEHOLDER/\\|}")"
    done
}

is_separator_row() {
    local c
    for c in "${CELLS[@]}"; do
        if ! [[ "$c" =~ ^:?-+:?$ ]]; then
            return 1
        fi
    done
    return 0
}

# Strips backticks/whitespace from a Flag or Short cell and prints the flag
# token (e.g. "--title", "-t"), or nothing if the cell is empty/"—" (none).
extract_flag_token() {
    local cell="${1//\`/}"
    cell="$(trim "$cell")"
    if [[ "$cell" =~ ^(--?[A-Za-z][A-Za-z0-9-]*)$ ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
    fi
}

# Expands a stripped heading spec (e.g. "issue label add/rm/list/delete")
# into one full command per line, splitting a trailing "a/b/c" multi-verb
# token against its base ("issue label add", "issue label rm", ...). Specs
# with no "/" in the last token print unchanged.
expand_spec() {
    local spec="$1"
    local last="${spec##* }"
    if [[ "$last" == */* ]]; then
        local base=""
        if [[ "$spec" == *" "* ]]; then
            base="${spec% $last}"
        fi
        local IFS='/'
        local verbs=($last)
        unset IFS
        local v
        for v in "${verbs[@]}"; do
            if [ -n "$base" ]; then
                printf '%s\n' "$base $v"
            else
                printf '%s\n' "$v"
            fi
        done
    else
        printf '%s\n' "$spec"
    fi
}

# COMMANDS[i] / DOC_FLAGS[i] / HELP_FLAGS[i] are parallel indexed arrays
# (no associative arrays -- bash 3.2 doesn't have them). FOUND_INDEX is the
# out-param for find_or_add_command since bash functions can't return strings.
COMMANDS=()
DOC_FLAGS=()
FOUND_INDEX=-1

find_or_add_command() {
    local cmd="$1"
    local i
    for ((i = 0; i < ${#COMMANDS[@]}; i++)); do
        if [ "${COMMANDS[$i]}" = "$cmd" ]; then
            FOUND_INDEX=$i
            return
        fi
    done
    COMMANDS+=("$cmd")
    DOC_FLAGS+=("")
    FOUND_INDEX=$((${#COMMANDS[@]} - 1))
}

add_flag_to_cmd() {
    local cmd="$1" flag="$2"
    [ -z "$flag" ] && return
    find_or_add_command "$cmd"
    DOC_FLAGS[$FOUND_INDEX]="${DOC_FLAGS[$FOUND_INDEX]} ${flag}"
}

CUR_CMDS=()
BLOCK_LINES=()

# Processes the accumulated BLOCK_LINES for the heading that set CUR_CMDS:
# finds the (single) markdown table if one exists and records each row's
# flags against the command(s) it applies to. No table -> the commands in
# CUR_CMDS are documented as taking zero flags (still checked against
# --help, catching an undocumented flag added without a table).
process_block() {
    [ "${#CUR_CMDS[@]}" -eq 0 ] && return

    local -a rows=()
    local line
    for line in "${BLOCK_LINES[@]}"; do
        if [[ "$line" =~ ^[[:space:]]*\| ]]; then
            rows+=("$line")
        fi
    done
    [ "${#rows[@]}" -eq 0 ] && return

    split_row "${rows[0]}"
    local -a header=("${CELLS[@]}")
    local flag_idx=-1 short_idx=-1 notes_idx=-1 command_idx=-1
    local j lc
    for ((j = 0; j < ${#header[@]}; j++)); do
        lc=$(printf '%s' "${header[$j]}" | tr '[:upper:]' '[:lower:]')
        case "$lc" in
            flag) flag_idx=$j ;;
            short) short_idx=$j ;;
            notes) notes_idx=$j ;;
            command) command_idx=$j ;;
        esac
    done
    [ "$flag_idx" -lt 0 ] && return

    local start=1
    if [ "${#rows[@]}" -gt 1 ]; then
        split_row "${rows[1]}"
        if is_separator_row; then
            start=2
        fi
    fi

    local r
    for ((r = start; r < ${#rows[@]}; r++)); do
        split_row "${rows[$r]}"
        [ "${#CELLS[@]}" -eq 0 ] && continue

        local flag_tok short_tok
        flag_tok=$(extract_flag_token "${CELLS[$flag_idx]:-}")
        short_tok=""
        [ "$short_idx" -ge 0 ] && short_tok=$(extract_flag_token "${CELLS[$short_idx]:-}")

        local -a target_cmds=()
        if [ "$command_idx" -ge 0 ]; then
            local cmd_cell="${CELLS[$command_idx]//\`/}"
            local verb="${cmd_cell%% *}"
            local c
            for c in "${CUR_CMDS[@]}"; do
                if [[ "$c" == *" $verb" || "$c" == "$verb" ]]; then
                    target_cmds+=("$c")
                fi
            done
        elif [ "${#CUR_CMDS[@]}" -gt 1 ] && [ "$notes_idx" -ge 0 ]; then
            local notes_cell="${CELLS[$notes_idx]:-}"
            local restrict=""
            if [[ "$notes_cell" =~ \`([A-Za-z]+)\`[[:space:]]+only ]]; then
                restrict="${BASH_REMATCH[1]}"
            fi
            if [ -n "$restrict" ]; then
                local c
                for c in "${CUR_CMDS[@]}"; do
                    if [[ "$c" == *" $restrict" || "$c" == "$restrict" ]]; then
                        target_cmds+=("$c")
                    fi
                done
            else
                target_cmds=("${CUR_CMDS[@]}")
            fi
        else
            target_cmds=("${CUR_CMDS[@]}")
        fi

        local tc
        for tc in "${target_cmds[@]}"; do
            add_flag_to_cmd "$tc" "$flag_tok"
            add_flag_to_cmd "$tc" "$short_tok"
        done
    done
}

# ---------------------------------------------------------------------------
# Phase 1: parse SKILL.md's Complete Command & Flag Reference section.
# ---------------------------------------------------------------------------

LINES=()
while IFS= read -r line || [ -n "$line" ]; do
    LINES+=("$line")
done < "$SKILL_MD"

IN_SECTION=0
i=0
n=${#LINES[@]}
while [ "$i" -lt "$n" ]; do
    line="${LINES[$i]}"
    if [[ "$line" =~ ^(#+)[[:space:]]+(.*)$ ]]; then
        hashes="${BASH_REMATCH[1]}"
        heading_text="${BASH_REMATCH[2]}"
        level=${#hashes}
        if [ "$level" -eq 2 ]; then
            process_block
            CUR_CMDS=()
            BLOCK_LINES=()
            if [ "$heading_text" = "$SECTION_HEADING" ]; then
                IN_SECTION=1
            elif [ "$IN_SECTION" -eq 1 ]; then
                break
            fi
            i=$((i + 1))
            continue
        elif [ "$level" -ge 3 ] && [ "$level" -le 4 ] && [ "$IN_SECTION" -eq 1 ]; then
            process_block
            CUR_CMDS=()
            BLOCK_LINES=()
            while IFS= read -r raw_match; do
                spec="${raw_match#\`docket }"
                spec="${spec%\`}"
                spec="$(printf '%s' "$spec" | sed -E 's/[[<].*$//')"
                spec="$(trim "$spec")"
                while IFS= read -r cmd; do
                    find_or_add_command "$cmd"
                    CUR_CMDS+=("$cmd")
                done < <(expand_spec "$spec")
            done < <(grep -oE "$SPEC_PATTERN" <<< "$heading_text" || true)
            i=$((i + 1))
            continue
        fi
    fi
    if [ "$IN_SECTION" -eq 1 ] && [ "${#CUR_CMDS[@]}" -gt 0 ]; then
        BLOCK_LINES+=("$line")
    fi
    i=$((i + 1))
done
process_block

if [ "${#COMMANDS[@]}" -eq 0 ]; then
    echo "docket_ref_check.sh: found no documented subcommands under '## ${SECTION_HEADING}' in ${SKILL_MD}" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Phase 2: run `docket <cmd> --help` for each documented subcommand.
# ---------------------------------------------------------------------------

HELP_FLAGS=()
for ((ci = 0; ci < ${#COMMANDS[@]}; ci++)); do
    cmd="${COMMANDS[$ci]}"
    read -ra cmd_args <<< "$cmd"
    help_output="$(docket "${cmd_args[@]}" --help 2>&1)"
    help_exit=$?
    tokens=""
    if [ "$help_exit" -ne 0 ]; then
        echo "ERROR [${cmd}]: 'docket ${cmd} --help' exited ${help_exit}: ${help_output}" >&2
        HELP_FLAGS+=("__ERROR__")
        continue
    fi
    in_flags=0
    while IFS= read -r hline; do
        if [ "$hline" = "Flags:" ]; then
            in_flags=1
            continue
        fi
        if [ "$hline" = "Global Flags:" ]; then
            in_flags=0
            continue
        fi
        [ "$in_flags" -eq 0 ] && continue
        [ -z "$(trim "$hline")" ] && continue
        if [[ "$hline" =~ ^[[:space:]]*(-[A-Za-z]),[[:space:]]+(--[A-Za-z][A-Za-z0-9-]*) ]]; then
            long="${BASH_REMATCH[2]}"
            if [ "$long" != "--help" ]; then
                tokens="${tokens} ${BASH_REMATCH[1]} ${long}"
            fi
        elif [[ "$hline" =~ ^[[:space:]]*(--[A-Za-z][A-Za-z0-9-]*) ]]; then
            long="${BASH_REMATCH[1]}"
            if [ "$long" != "--help" ]; then
                tokens="${tokens} ${long}"
            fi
        fi
    done <<< "$help_output"
    HELP_FLAGS+=("$tokens")
done

# ---------------------------------------------------------------------------
# Phase 3: compare documented flags vs. installed --help output.
# ---------------------------------------------------------------------------

contains_token() {
    local needle="$1" hay=" $2 "
    [[ "$hay" == *" $needle "* ]]
}

DRIFT_COUNT=0
for ((ci = 0; ci < ${#COMMANDS[@]}; ci++)); do
    cmd="${COMMANDS[$ci]}"
    doc_str="${DOC_FLAGS[$ci]}"
    help_str="${HELP_FLAGS[$ci]}"

    if [ "$help_str" = "__ERROR__" ]; then
        DRIFT_COUNT=$((DRIFT_COUNT + 1))
        continue
    fi

    cmd_drift=0
    for tok in $doc_str; do
        if ! contains_token "$tok" "$help_str"; then
            echo "DRIFT [${cmd}]: documented flag missing from --help: ${tok}"
            cmd_drift=1
        fi
    done
    for tok in $help_str; do
        if ! contains_token "$tok" "$doc_str"; then
            echo "DRIFT [${cmd}]: --help flag undocumented in SKILL.md: ${tok}"
            cmd_drift=1
        fi
    done
    [ "$cmd_drift" -eq 1 ] && DRIFT_COUNT=$((DRIFT_COUNT + 1))
done

TOTAL=${#COMMANDS[@]}
if [ "$DRIFT_COUNT" -eq 0 ]; then
    echo "docket_ref_check.sh: OK -- ${TOTAL} documented subcommands checked, no drift"
    exit 0
else
    echo "docket_ref_check.sh: FAIL -- drift found in ${DRIFT_COUNT} of ${TOTAL} documented subcommands"
    exit 1
fi
