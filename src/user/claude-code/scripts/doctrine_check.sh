#!/bin/bash
# Deterministic doctrine-consistency checks for team-doctrine, mechanizing 3
# manual checks found violated/unverified this cycle: (a) team-doctrine/
# SKILL.md's reference-file index parity, (b) every CANONICAL:*-LOCAL
# "Master:" pointer resolves to an existing file (both the ~/.claude and
# repo: forms), (c) CANONICAL:<TAG> blocks stay byte-identical — optionally
# after a per-carrier strip-transform from the manifest's 3rd column — across
# the carriers listed in doctrine_check_manifest.tsv, rejecting outright any
# carrier whose strip transform empties its block. Read-only; exits 1 if any
# arm fails.
set -uo pipefail

usage() {
    echo "Usage: doctrine_check.sh [--emit-hashes]" >&2
    echo "  Runs 3 check arms (index parity, pointer resolution, CANONICAL" >&2
    echo "  tag byte-parity) against the current repo state. Emits a PASS/FAIL" >&2
    echo "  line per arm (failure reasons indented above it) and exits 0 if" >&2
    echo "  every arm passes, 1 if any arm fails." >&2
    echo "  --emit-hashes: machine mode. Skip arms (a)/(b); emit one" >&2
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
# 2 (block not found), 3 (strip transform emptied the block). Single source of
# the extract+strip pipeline, shared by arm (c) and --emit-hashes.
carrier_compare_block() {
    local tag="$1" marker="$2" f="$3"
    [ -f "$f" ] || return 1
    local block body strip_expr compare_block
    block=$(sed -n "/CANONICAL:${marker}:BEGIN/,/CANONICAL:${marker}:END/p" "$f")
    [ -z "$block" ] && return 2
    # Drop the BEGIN/END marker lines before hashing: they're constant
    # per-marker literal text, so leaving them in the comparison content lets a
    # strip transform that empties only the body (but leaves the markers intact)
    # hash-match vacuously across carriers with genuinely different bodies.
    body=$(printf '%s\n' "$block" | sed -e "/CANONICAL:${marker}:BEGIN/d" -e "/CANONICAL:${marker}:END/d")
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
if [ "$overall_status" -eq 0 ]; then
    echo "doctrine_check.sh: all arms PASS"
else
    echo "doctrine_check.sh: one or more arms FAILED"
fi
exit "$overall_status"
