#!/bin/bash
# Copy-literal acceptance-surface verification for ux-designer.md's content
# rule: "Quote each proposed copy string as a verbatim literal so @sdet and
# design-QA can verify it mechanically against built output (grep -F
# '<string>') ... the copy block IS the spec's executable acceptance surface."
#
# Extracts each verbatim copy literal from a UX spec and `grep -F`s it against
# the implementation/rendered output, emitting PASS/FAIL per string. A UX spec
# denotes copy literals as inline-code spans (`Save changes`), matching the
# repo's other markdown extractor (check_citations.py). Path/command-looking
# spans are filtered out by default so a `src/foo.rs` citation is not mistaken
# for user-facing copy; --no-filter disables that.
#
# Target resolution: if <target> exists as a file, its contents are grepped;
# otherwise <target> is run as a command string and its stdout+stderr grepped
# (the render_verify.sh cli-arm model). Force with --file / --cmd.
set -uo pipefail

usage() {
    echo "Usage: copy_verify.sh [opts] <spec.md> <target-cmd-or-path>" >&2
    echo "" >&2
    echo "  <spec.md>     UX spec to extract inline-code copy literals from." >&2
    echo "  <target>      A file path (grepped) or a command string (run," >&2
    echo "                its stdout+stderr grepped). Auto-detected by" >&2
    echo "                whether the file exists; override with --file/--cmd." >&2
    echo "" >&2
    echo "  --section <s>   Only extract literals from spec sections whose" >&2
    echo "                  heading contains <s> (case-insensitive), e.g." >&2
    echo "                  --section Copy. Repeatable-substring, single value." >&2
    echo "  --quotes        Extract double-quoted \"strings\" instead of" >&2
    echo "                  inline-code spans." >&2
    echo "  --no-filter     Do not drop path/command-looking literals." >&2
    echo "  --file          Force treating <target> as a file path." >&2
    echo "  --cmd           Force treating <target> as a command string." >&2
    echo "" >&2
    echo "  Emits 'PASS <literal>' / 'FAIL <literal>' per extracted string." >&2
    echo "  Exits 0 if every literal is found, 1 if any FAIL or none found," >&2
    echo "  2 on usage error." >&2
    exit 2
}

SECTION=""
MODE_QUOTES=0
NO_FILTER=0
TARGET_KIND="auto"
SPEC=""
TARGET=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) usage ;;
        --section)
            [ "$#" -ge 2 ] || usage
            SECTION="$2"
            shift 2
            ;;
        --quotes) MODE_QUOTES=1; shift ;;
        --no-filter) NO_FILTER=1; shift ;;
        --file) TARGET_KIND="file"; shift ;;
        --cmd) TARGET_KIND="cmd"; shift ;;
        -*) usage ;;
        *)
            if [ -z "$SPEC" ]; then
                SPEC="$1"
            elif [ -z "$TARGET" ]; then
                TARGET="$1"
            else
                usage
            fi
            shift
            ;;
    esac
done

[ -n "$SPEC" ] && [ -n "$TARGET" ] || usage
[ -f "$SPEC" ] || {
    echo "copy_verify.sh: spec file not found: $SPEC" >&2
    exit 2
}

# Optionally narrow the spec to the section(s) whose heading contains SECTION,
# from that heading up to the next heading of the same or higher level.
spec_text() {
    if [ -z "$SECTION" ]; then
        cat "$SPEC"
        return
    fi
    awk -v want="$(printf '%s' "$SECTION" | tr '[:upper:]' '[:lower:]')" '
        function level(s,   n) { n = 0; while (substr(s, n+1, 1) == "#") n++; return n }
        /^#+[[:space:]]/ {
            lvl = level($0)
            hdr = tolower($0)
            if (index(hdr, want) > 0) { inseg = 1; seglvl = lvl; print; next }
            if (inseg && lvl <= seglvl) { inseg = 0 }
        }
        inseg { print }
    ' "$SPEC"
}

# Extract literals (inline-code spans by default, double-quoted with --quotes),
# fence-aware, de-duplicated in first-seen order.
extract_literals() {
    local pattern
    if [ "$MODE_QUOTES" -eq 1 ]; then
        pattern='"'
    else
        pattern='`'
    fi
    spec_text | awk -v q="$pattern" '
        /^[[:space:]]*```/ { infence = !infence; next }
        infence { next }
        {
            line = $0
            re = q "[^" q "]+" q
            while (match(line, re)) {
                span = substr(line, RSTART + 1, RLENGTH - 2)
                if (!(span in seen)) { seen[span] = 1; print span }
                line = substr(line, RSTART + RLENGTH)
            }
        }
    '
}

# A literal looks like a path/command (not copy) if it contains a slash, is a
# bare dotted filename (foo.md), or begins with a flag dash.
looks_like_path() {
    local s="$1"
    case "$s" in
        */*) return 0 ;;
        -*) return 0 ;;
    esac
    if printf '%s' "$s" | grep -qE '^[[:alnum:]_.-]+\.[[:alnum:]]{1,10}$'; then
        return 0
    fi
    return 1
}

# Resolve the target haystack once.
if [ "$TARGET_KIND" = "auto" ]; then
    if [ -f "$TARGET" ]; then TARGET_KIND="file"; else TARGET_KIND="cmd"; fi
fi

if [ "$TARGET_KIND" = "file" ]; then
    [ -f "$TARGET" ] || { echo "copy_verify.sh: target file not found: $TARGET" >&2; exit 2; }
    HAYSTACK=$(cat "$TARGET")
else
    HAYSTACK=$(bash -c "$TARGET" 2>&1 || true)
fi

total=0
passed=0
overall=0

while IFS= read -r literal; do
    [ -n "$literal" ] || continue
    if [ "$NO_FILTER" -eq 0 ] && [ "$MODE_QUOTES" -eq 0 ] && looks_like_path "$literal"; then
        continue
    fi
    total=$((total + 1))
    if printf '%s' "$HAYSTACK" | grep -qF -- "$literal"; then
        printf '  PASS  %s\n' "$literal"
        passed=$((passed + 1))
    else
        printf '  FAIL  %s\n' "$literal"
        overall=1
    fi
done < <(extract_literals)

if [ "$total" -eq 0 ]; then
    echo "copy: no copy literals extracted from $SPEC (check --section/--quotes/--no-filter)" >&2
    exit 1
fi

if [ "$overall" -eq 0 ]; then
    echo "copy: OK ($passed/$total literals found in target)"
else
    echo "copy: FAIL ($passed/$total found; $((total - passed)) missing)" >&2
fi
exit "$overall"
