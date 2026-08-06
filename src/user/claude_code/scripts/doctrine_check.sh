#!/bin/bash
# Deterministic doctrine-consistency checks for team-doctrine, mechanizing 4
# manual checks found violated/unverified this cycle: (a) team-doctrine/
# SKILL.md's reference-file index parity, (b) every CANONICAL:*-LOCAL
# "Master:" pointer resolves to an existing file (both the ~/.claude and
# repo: forms), (c) CANONICAL:<TAG> blocks stay byte-identical — optionally
# after a per-carrier strip-transform from the manifest's 3rd column — across
# the carriers listed in doctrine_check_manifest.tsv, rejecting outright any
# carrier whose strip transform empties its block, (d) each references/*.md
# row's "Cited by" cell names exactly the set of agent/skill files that
# actually cite that reference file's path on disk. Read-only; exits 1 if any
# arm fails.
set -uo pipefail

usage() {
    echo "Usage: doctrine_check.sh [--emit-hashes]" >&2
    echo "  Runs 4 check arms (index parity, pointer resolution, CANONICAL" >&2
    echo "  tag byte-parity, 'Cited by' citer-set parity) against the current" >&2
    echo "  repo state. Emits a PASS/FAIL line per arm (failure reasons" >&2
    echo "  indented above it) and exits 0 if every arm passes, 1 if any" >&2
    echo "  arm fails." >&2
    echo "  --emit-hashes: machine mode. Skip arms (a)/(b)/(d); emit one" >&2
    echo "  'tag<TAB>ref_hash<TAB>carrier_count<TAB>parity' line per manifest" >&2
    echo "  tag (parity = ok|fail|single) and exit 0 unless a tag's carriers" >&2
    echo "  diverge. Consumed by coherence_xref.py for its canonical_blocks key." >&2
    exit 1
}

EMIT_HASHES=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --emit-hashes) EMIT_HASHES=1; shift ;;
        -h|--help) usage ;;
        *) usage ;;
    esac
done

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "doctrine_check.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

# Overridable via env for test fixtures (tests/doctrine_check.test.sh); unset
# in normal use so real-repo defaults below apply.
: "${SKILL_MD:=src/user/claude-code/skills/team-doctrine/SKILL.md}"
: "${REFERENCES_DIR:=src/user/claude-code/skills/team-doctrine/references}"
: "${MANIFEST:=src/user/claude-code/scripts/doctrine_check_manifest.tsv}"
: "${POINTER_SEARCH_DIRS:=src/user/claude-code .claude/skills}"

for required in "$SKILL_MD" "$REFERENCES_DIR" "$MANIFEST"; do
    if [ ! -e "$required" ]; then
        echo "doctrine_check.sh: required path missing: ${required}" >&2
        exit 1
    fi
done

overall_status=0

hash_of() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 | awk '{print $1}'
    else
        sha256sum | awk '{print $1}'
    fi
}

# Extract a carrier's CANONICAL:<marker> block, drop the BEGIN/END marker lines,
# apply the manifest strip-transform (3rd column) if any, and print the
# comparable block on stdout. Returns 0 (printed block), 1 (file missing),
# 2 (block not found), 3 (strip transform emptied the block), 4 (BEGIN/END
# marker count imbalance). Single source of the extract+strip pipeline,
# shared by arm (c) and --emit-hashes.
#
# The BEGIN/END sed range below is anchored to the actual marker's
# comment-line form (line starts with "<!-- CANONICAL:") rather than an
# unanchored substring match. Prose that merely discusses/describes a marker
# (e.g. "wrapped in `CANONICAL:BANNER:BEGIN/END` markers") does not start a
# line that way, so it can no longer be misread as opening a second block
# that never closes and swallows the rest of the file (DKT-169).
carrier_compare_block() {
    local tag="$1" marker="$2" f="$3"
    [ -f "$f" ] || return 1
    local block body strip_expr compare_block begin_count end_count
    begin_count=$(grep -cE "^<!-- CANONICAL:${marker}:BEGIN -->" "$f")
    end_count=$(grep -cE "^<!-- CANONICAL:${marker}:END -->" "$f")
    [ "$begin_count" -ne "$end_count" ] && return 4
    block=$(sed -n "/^<!-- CANONICAL:${marker}:BEGIN -->/,/^<!-- CANONICAL:${marker}:END -->/p" "$f")
    [ -z "$block" ] && return 2
    # Drop the BEGIN/END marker lines before hashing: they're constant
    # per-marker literal text, so leaving them in the comparison content lets a
    # strip transform that empties only the body (but leaves the markers intact)
    # hash-match vacuously across carriers with genuinely different bodies.
    body=$(printf '%s\n' "$block" | sed -e "/^<!-- CANONICAL:${marker}:BEGIN -->/d" -e "/^<!-- CANONICAL:${marker}:END -->/d")
    strip_expr=$(awk -F'\t' -v t="$tag" -v ff="$f" '$1==t && $2==ff {print $3; exit}' "$MANIFEST")
    if [ -n "$strip_expr" ]; then
        compare_block=$(printf '%s' "$body" | sed "$strip_expr")
    else
        compare_block="$body"
    fi
    [ -z "$compare_block" ] && return 3
    printf '%s' "$compare_block"
}

# --emit-hashes machine mode: skip the human arms (a)/(b)/(c) and emit one
# 'tag<TAB>ref_hash<TAB>carrier_count<TAB>parity' line per manifest tag.
if [ "$EMIT_HASHES" -eq 1 ]; then
    emit_status=0
    emit_tags=$(grep -vE '^[[:space:]]*#' "$MANIFEST" | grep -vE '^[[:space:]]*$' | awk -F'\t' '{print $1}' | sort -u)
    for tag in $emit_tags; do
        files=$(awk -F'\t' -v t="$tag" '$1==t {print $2}' "$MANIFEST")
        marker=$(awk -F'\t' -v t="$tag" '$1==t && $4!="" {print $4; exit}' "$MANIFEST")
        marker="${marker:-$tag}"
        ref_hash=""
        parity="ok"
        ccount=0
        for f in $files; do
            [ -z "$f" ] && continue
            ccount=$((ccount + 1))
            compare_block=$(carrier_compare_block "$tag" "$marker" "$f") || { parity="fail"; continue; }
            h=$(printf '%s' "$compare_block" | hash_of)
            if [ -z "$ref_hash" ]; then
                ref_hash="$h"
            elif [ "$h" != "$ref_hash" ]; then
                parity="fail"
            fi
        done
        [ "$ccount" -lt 2 ] && parity="single"
        printf '%s\t%s\t%s\t%s\n' "$tag" "$ref_hash" "$ccount" "$parity"
        [ "$parity" = "fail" ] && emit_status=1
    done
    exit "$emit_status"
fi

# ---------------------------------------------------------------------------
echo "== Arm (a): team-doctrine/SKILL.md index parity =="

disk_count=$(ls -1 "$REFERENCES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
row_count=$(grep -cE '^\| `references/' "$SKILL_MD")
arm_a_ok=1

for f in "$REFERENCES_DIR"/*.md; do
    base=$(basename "$f")
    if ! grep -qF "references/${base}\`" "$SKILL_MD"; then
        echo "  - ${base} is on disk but not cited as a table row in ${SKILL_MD}"
        arm_a_ok=0
    fi
done

for base in $(grep -oE '`references/[A-Za-z0-9_.-]+\.md`' "$SKILL_MD" | tr -d '`' | sed 's#references/##' | sort -u); do
    if [ ! -f "${REFERENCES_DIR}/${base}" ]; then
        echo "  - ${base} is cited in the SKILL.md table but missing from ${REFERENCES_DIR}/"
        arm_a_ok=0
    fi
done

if [ "$disk_count" -ne "$row_count" ]; then
    echo "  - ${disk_count} reference file(s) on disk != ${row_count} table row(s) in ${SKILL_MD}"
    arm_a_ok=0
fi

if [ "$arm_a_ok" -eq 1 ]; then
    echo "PASS: ${disk_count} reference files == ${row_count} table rows, all cross-referenced"
else
    echo "FAIL: index parity violated (see above)"
    overall_status=1
fi

# ---------------------------------------------------------------------------
echo
echo "== Arm (b): CANONICAL Master: pointer resolution =="

home_root="$HOME/.claude"
home_checkable=1
if [ ! -d "$home_root" ]; then
    echo "  - NOTE: ${home_root} not found on this machine — skipping ~/.claude existence checks (repo: paths still checked)"
    home_checkable=0
fi

master_re='Master: `([^`]+)`'
repo_re='repo: `([^`]+)`'

pointer_total=0
pointer_fail=0

hits=$(grep -rn "Master: \`" $POINTER_SEARCH_DIRS --include="*.md" 2>/dev/null || true)
if [ -n "$hits" ]; then
    while IFS= read -r LINE; do
        [ -z "$LINE" ] && continue
        pointer_total=$((pointer_total + 1))

        FILEPATH="${LINE%%:*}"
        REST="${LINE#*:}"
        LINE_NO="${REST%%:*}"
        CONTENT="${REST#*:}"

        home_path=""
        repo_path=""
        [[ "$CONTENT" =~ $master_re ]] && home_path="${BASH_REMATCH[1]}"
        [[ "$CONTENT" =~ $repo_re ]] && repo_path="${BASH_REMATCH[1]}"

        line_ok=1
        if [ -z "$repo_path" ]; then
            echo "  - ${FILEPATH}:${LINE_NO} — no repo: path found on this Master: line"
            line_ok=0
        elif [ ! -f "$repo_path" ]; then
            echo "  - ${FILEPATH}:${LINE_NO} — repo path does not exist: ${repo_path}"
            line_ok=0
        fi

        if [ "$home_checkable" -eq 1 ] && [ -n "$home_path" ]; then
            expanded="${home_path/#\~/$HOME}"
            if [ ! -f "$expanded" ]; then
                echo "  - ${FILEPATH}:${LINE_NO} — home path does not exist: ${home_path}"
                line_ok=0
            fi
        fi

        [ "$line_ok" -eq 0 ] && pointer_fail=$((pointer_fail + 1))
    done <<< "$hits"
fi

if [ "$pointer_total" -eq 0 ]; then
    echo "FAIL: 0 Master: pointer(s) found under ${POINTER_SEARCH_DIRS} — a drift-guard that checks nothing is not a pass"
    overall_status=1
elif [ "$pointer_fail" -eq 0 ]; then
    echo "PASS: ${pointer_total} Master: pointer(s) resolved"
else
    echo "FAIL: ${pointer_fail} of ${pointer_total} Master: pointer(s) failed to resolve"
    overall_status=1
fi

# ---------------------------------------------------------------------------
echo
echo "== Arm (c): CANONICAL tag byte-parity (${MANIFEST}) =="

tags=$(grep -vE '^[[:space:]]*#' "$MANIFEST" | grep -vE '^[[:space:]]*$' | awk -F'\t' '{print $1}' | sort -u)

for tag in $tags; do
    files=$(awk -F'\t' -v t="$tag" '$1==t {print $2}' "$MANIFEST")
    marker=$(awk -F'\t' -v t="$tag" '$1==t && $4!="" {print $4; exit}' "$MANIFEST")
    marker="${marker:-$tag}"

    manifest_line_count=0
    while IFS= read -r f; do
        [ -n "$f" ] && manifest_line_count=$((manifest_line_count + 1))
    done <<< "$files"

    if [ "$manifest_line_count" -eq 0 ]; then
        echo "FAIL: ${tag} has 0 carrier line(s) with a path in ${MANIFEST} — cannot be checked"
        overall_status=1
        continue
    fi

    if [ "$manifest_line_count" -lt 2 ]; then
        echo "WARN: ${tag} has only ${manifest_line_count} carrier(s) in ${MANIFEST} — parity requires >=2 to compare anything, skipping"
        continue
    fi

    ref_hash=""
    ref_file=""
    tag_ok=1
    carrier_count=0
    for f in $files; do
        [ -z "$f" ] && continue
        carrier_count=$((carrier_count + 1))
        compare_block=$(carrier_compare_block "$tag" "$marker" "$f")
        case "$?" in
            1)
                echo "  - ${tag} carrier missing from disk: ${f}"
                tag_ok=0
                continue
                ;;
            2)
                echo "  - ${tag} block not found in ${f}"
                tag_ok=0
                continue
                ;;
            3)
                echo "  - ${tag} carrier ${f}: strip transform reduced the block to an empty string (vacuous-empty-match trap) — refusing to compare"
                tag_ok=0
                continue
                ;;
            4)
                echo "  - ${tag} carrier ${f}: CANONICAL:${marker} BEGIN/END marker count imbalance (unclosed or duplicate marker) — refusing to compare"
                tag_ok=0
                continue
                ;;
        esac

        h=$(printf '%s' "$compare_block" | hash_of)
        if [ -z "$ref_hash" ]; then
            ref_hash="$h"
            ref_file="$f"
        elif [ "$h" != "$ref_hash" ]; then
            echo "  - ${tag} block in ${f} differs from ${ref_file}"
            tag_ok=0
        fi
    done
    if [ "$tag_ok" -eq 1 ]; then
        echo "PASS: ${tag} byte-identical across ${carrier_count} carrier(s)"
    else
        echo "FAIL: ${tag} parity violated (see above)"
        overall_status=1
    fi
done

# ---------------------------------------------------------------------------
echo
echo "== Arm (d): team-doctrine/SKILL.md 'Cited by' citer-set parity =="

# Candidate citer files: every agent *.md under an agents/ dir, and every
# skill's SKILL.md, across $POINTER_SEARCH_DIRS — excluding the team-doctrine
# skill itself (its own index row and references/ dir cross-cite each other
# and are not "citers" of themselves).
citer_files=$(
    for d in $POINTER_SEARCH_DIRS; do
        find "$d" -type f \( -path "*/agents/*.md" -o -name "SKILL.md" \) 2>/dev/null
    done | grep -v "/skills/team-doctrine/" | sort -u
)

# A citer's declared-table key: an agent's own basename (e.g. team-lead.md),
# or a skill's directory name (e.g. evolve-agents) for a SKILL.md file.
citer_key_for() {
    local f="$1" base
    base=$(basename "$f")
    if [ "$base" = "SKILL.md" ]; then
        basename "$(dirname "$f")"
    else
        echo "$base"
    fi
}

worker_agents=$(
    for f in $citer_files; do
        [[ "$f" == */agents/*.md ]] || continue
        k=$(citer_key_for "$f")
        [ "$k" = "team-lead.md" ] && continue
        echo "$k"
    done | sort -u
)

arm_d_ok=1
arm_d_row_count=0

while IFS= read -r row; do
    ref=$(printf '%s' "$row" | awk -F'|' '{print $2}' | grep -oE '`references/[A-Za-z0-9_.-]+\.md`' | tr -d '`' | sed 's#references/##')
    cell=$(printf '%s' "$row" | awk -F'|' '{print $4}')
    [ -z "$ref" ] && continue
    arm_d_row_count=$((arm_d_row_count + 1))

    # Parse the declared citer set out of the cell's free-text prose: an
    # "all but `X`" exclusion (if present) is stripped and X excluded from
    # the worker-agent roster; an "N agents" shorthand expands to that full
    # roster (minus any exclusion) AND asserts N equals the resolved roster
    # size; an "N ... skills (`a`, `b`, ...)" shorthand asserts N equals the
    # count of backtick-quoted names in its own parenthetical list; every
    # remaining backtick-quoted token (agent basename or bare skill dir name)
    # is taken literally. Either numeral check failing is a count-divergence
    # FAIL even when set membership (missing/extra) otherwise matches.
    work="$cell"
    excl=""
    if [[ "$work" =~ all\ but\ \`([A-Za-z0-9_.-]+)\` ]]; then
        excl="${BASH_REMATCH[1]}"
        work="${work/${BASH_REMATCH[0]}/}"
    fi

    declared=""
    count_ok=1
    if [[ "$work" =~ ([0-9]+)\ agents ]]; then
        agents_n="${BASH_REMATCH[1]}"
        agents_expected=$(printf '%s\n' "$worker_agents" | grep -c .)
        if [ -n "$excl" ] && printf '%s\n' "$worker_agents" | grep -qxF "$excl"; then
            agents_expected=$((agents_expected - 1))
        fi
        if [ "$agents_n" -ne "$agents_expected" ]; then
            echo "  - ${ref}: cell states \"${agents_n} agents\" but the resolved agent roster is ${agents_expected}"
            count_ok=0
        fi
        while IFS= read -r a; do
            [ -z "$a" ] && continue
            [ "$a" = "$excl" ] && continue
            declared="${declared}${a}"$'\n'
        done <<< "$worker_agents"
    fi
    while IFS= read -r shorthand; do
        [ -z "$shorthand" ] && continue
        skills_n=$(printf '%s' "$shorthand" | grep -oE '^[0-9]+')
        skills_list_count=$(printf '%s' "$shorthand" | grep -oE '`[A-Za-z0-9_.-]+`' | grep -c .)
        if [ "$skills_n" -ne "$skills_list_count" ]; then
            echo "  - ${ref}: cell states \"${skills_n} ... skills\" shorthand but its parenthetical list names ${skills_list_count} skill(s)"
            count_ok=0
        fi
    done < <(printf '%s' "$work" | grep -oE '[0-9]+ [^()`]*skills[^()]*\([^)]*\)' || true)
    for tok in $(printf '%s' "$work" | grep -oE '`[A-Za-z0-9_.-]+`' | tr -d '`'); do
        declared="${declared}${tok}"$'\n'
    done
    declared=$(printf '%s' "$declared" | sed '/^$/d' | sort -u)

    # A citer's live detection accepts either the literal master-file path
    # (as before) or its matching CANONICAL:<TAG>-LOCAL pointer marker (the
    # tag derived from the reference's own basename, e.g.
    # runtime-discipline.md -> RUNTIME-DISCIPLINE-LOCAL) — a file may carry
    # only the compact LOCAL-copy marker without ever spelling out the path.
    # Require the literal ":BEGIN" suffix so a prose mention of the tag name
    # elsewhere (e.g. describing another file's marker) doesn't count as
    # this file carrying the block itself.
    marker_tag="$(printf '%s' "${ref%.md}" | tr '[:lower:]' '[:upper:]')-LOCAL"
    live=""
    for f in $citer_files; do
        if grep -qF "references/${ref}" "$f" 2>/dev/null || grep -qF "CANONICAL:${marker_tag}:BEGIN" "$f" 2>/dev/null; then
            live="${live}$(citer_key_for "$f")"$'\n'
        fi
    done
    live=$(printf '%s' "$live" | sed '/^$/d' | sort -u)

    missing=$(comm -23 <(printf '%s\n' "$declared") <(printf '%s\n' "$live") 2>/dev/null)
    extra=$(comm -13 <(printf '%s\n' "$declared") <(printf '%s\n' "$live") 2>/dev/null)

    if [ -n "$missing" ] || [ -n "$extra" ] || [ "$count_ok" -eq 0 ]; then
        arm_d_ok=0
        if [ -n "$missing" ] || [ -n "$extra" ]; then
            dcount=$(printf '%s\n' "$declared" | grep -c .)
            lcount=$(printf '%s\n' "$live" | grep -c .)
            echo "  - ${ref}: ${dcount} declared citer(s) in the 'Cited by' cell != ${lcount} live citer(s) found on disk"
        fi
        while IFS= read -r m; do
            [ -z "$m" ] && continue
            echo "      missing: ${m} is listed in the 'Cited by' cell but does not cite \`references/${ref}\` in any agent/skill file"
        done <<< "$missing"
        while IFS= read -r e; do
            [ -z "$e" ] && continue
            echo "      extra: ${e} cites \`references/${ref}\` on disk but is not listed in the 'Cited by' cell"
        done <<< "$extra"
    fi
done < <(grep -E '^\| `references/' "$SKILL_MD")

if [ "$arm_d_row_count" -eq 0 ]; then
    echo "FAIL: 0 reference row(s) parsed from ${SKILL_MD} — a drift-guard that checks nothing is not a pass"
    overall_status=1
elif [ "$arm_d_ok" -eq 1 ]; then
    echo "PASS: ${arm_d_row_count} reference row(s), 'Cited by' citer sets match live grep results"
else
    echo "FAIL: 'Cited by' citer-set parity violated (see above)"
    overall_status=1
fi

# ---------------------------------------------------------------------------
echo
if [ "$overall_status" -eq 0 ]; then
    echo "doctrine_check.sh: all arms PASS"
else
    echo "doctrine_check.sh: one or more arms FAILED"
fi
exit "$overall_status"
