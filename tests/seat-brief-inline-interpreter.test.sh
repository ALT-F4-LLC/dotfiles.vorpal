#!/bin/bash

# Guard suite: no rendered seat or judge brief instructs an inline
# interpreter that the harness deny list refuses.
#
# Defect class. In one run every in-wave vote seat and several verify and
# judge steps read their evidence bundle with one compound call shaped like
# `docket step context STEP-N --json > file; python3 -c "..."`. The installed
# settings deny interpreter code arguments (`SHELL_INDIRECTION_DENY_PATTERNS`
# in src/user/claude_code.rs), so the whole call was refused before it ran,
# no hook fired, the seat's no-retry rule applied, and it voted on the
# proposal summary alone. The block-probe brief in wave.js even offered
# "python3 or jq" as the way to parse JSON. No other gate reads the brief
# sources for this: the Rust tests pin the deny rules themselves, and the
# tribunal and wave suites assert what a brief renders, not what parser it
# names.
#
# What this suite pins, over the sources every seat and judge brief renders
# from (workflows/tribunal.js, workflows/wave.js, and the docket contracts
# and fragments):
#
#   (a) deny-derived: no line matches any interpreter code-argument pattern
#       from the deny list. The patterns are read from the Rust source and
#       converted glob-to-regex here, so a new deny row is enforced on the
#       briefs without editing this suite, and the two cannot drift.
#   (b) census: the token `python` appears nowhere in those sources. The
#       "(python3 or jq)" shape matches no deny glob, so (a) alone would
#       pass it; a legitimate future mention must be admitted here on
#       purpose.
#   (c) positive pins: tribunal.js carries the jq-or-plain-read rule and
#       renders it into BOTH seat-brief modes (the interpolation count);
#       fragments/evidence-rules.md, which every judge, verify and report
#       contract includes, carries the same rule for docket steps; and
#       wave.js's block probe says to parse with jq.
#
# WORKFLOWS_DIR, CORPUS_DIR and SETTINGS_SOURCE override the inputs, so a
# mutation probe can point the suite at deliberately-broken COPIES under
# $TMPDIR. The self-checks below do exactly that, each proving one assertion
# red against a copy that reintroduces the defect.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="${SCRIPT_DIR}/.."
WORKFLOWS="${WORKFLOWS_DIR:-${ROOT}/src/user/claude_code/workflows}"
CORPUS="${CORPUS_DIR:-${ROOT}/src/user/docket/config}"
SETTINGS="${SETTINGS_SOURCE:-${ROOT}/src/user/claude_code.rs}"

RULE_SENTENCE='Never hand parsing code to an inline interpreter'
PROBE_SENTENCE='parse the JSON with jq, one command per call'

fail=0
pass=0
ok() { echo "ok   $1"; pass=$((pass + 1)); }
bad() { echo "FAIL $1"; fail=1; }

# The interpreter code-argument rows of the deny list: `<name> -*<flag> *`
# and `node --eval/--print *`. Rows such as `env *` or `find * -exec*` wrap a
# command rather than take code, and a brief may name those verbs in prose.
deny_globs() { # <claude_code.rs>
    awk '/^const SHELL_INDIRECTION_DENY_PATTERNS/{on=1; next} on && /^\];/{exit} on' "$1" \
        | sed -n 's/^[[:space:]]*"Bash(\(.*\))",$/\1/p' \
        | grep -E ' -\*?[a-z] \*$| --(eval|print) \*$'
}

# Glob to ERE: `*` is any run of non-space characters (a glob star in a
# permission rule never crosses a word boundary the brief would print), and
# the only other metacharacter these rows use is `.`.
glob_to_ere() {
    sed -e 's/\./\\./g' -e 's/\*/[^[:space:]]*/g'
}

# The files a seat or judge brief renders from.
brief_sources() { # <workflows> <corpus>
    printf '%s\n' "$1/tribunal.js" "$1/wave.js"
    ls "$2"/contracts/*.md "$2"/fragments/*.md 2>/dev/null
}

# Runs assertions (a), (b) and (c) against one tree; prints its findings and
# returns non-zero when any assertion is red. The mutants below call this
# on a copy, so the real run and the self-checks share one code path.
check_tree() { # <workflows> <corpus> <settings>
    local wf="$1" corpus="$2" settings="$3" red=0 n=0 glob ere hits
    local sources
    sources=$(brief_sources "$wf" "$corpus")
    # Exit 2 is a setup fault, not a finding: a mutant that reads no sources
    # must not count as red.
    if [ -z "$sources" ] || [ ! -f "$wf/tribunal.js" ] || [ ! -f "$wf/wave.js" ] \
        || [ ! -f "$settings" ]; then
        echo "  no brief sources under $wf and $corpus, or no settings source at $settings"
        return 2
    fi

    # (a) deny-derived patterns
    while IFS= read -r glob; do
        [ -n "$glob" ] || continue
        n=$((n + 1))
        ere=$(printf '%s' "$glob" | glob_to_ere)
        hits=$(printf '%s\n' "$sources" | xargs grep -nE -- "$ere" 2>/dev/null)
        if [ -n "$hits" ]; then
            echo "  deny pattern 'Bash($glob)' matched a brief source:"
            printf '%s\n' "$hits" | sed 's/^/    /'
            red=1
        fi
    done < <(deny_globs "$settings")
    if [ "$n" -eq 0 ]; then
        echo "  no interpreter code-argument rows found in $settings (constant renamed?)"
        red=1
    fi

    # (b) python census
    hits=$(printf '%s\n' "$sources" | xargs grep -nwi -- 'python[0-9]*' 2>/dev/null)
    if [ -n "$hits" ]; then
        echo "  the token python names a parser in a brief source:"
        printf '%s\n' "$hits" | sed 's/^/    /'
        red=1
    fi

    # (c) positive pins
    if ! grep -qF -- "$RULE_SENTENCE" "$wf/tribunal.js"; then
        echo "  tribunal.js no longer carries the rule sentence: $RULE_SENTENCE"
        red=1
    fi
    local renders
    renders=$(grep -c '^\${evidenceParseRule}' "$wf/tribunal.js")
    if [ "$renders" -ne 2 ]; then
        echo "  tribunal.js renders the parse rule into $renders seat-brief mode(s), expected 2"
        red=1
    fi
    if ! grep -qF -- "$PROBE_SENTENCE" "$wf/wave.js"; then
        echo "  wave.js block probe no longer says: $PROBE_SENTENCE"
        red=1
    fi
    if ! grep -qF -- "$RULE_SENTENCE" "$corpus/fragments/evidence-rules.md"; then
        echo "  fragments/evidence-rules.md no longer carries the rule sentence: $RULE_SENTENCE"
        red=1
    fi
    return "$red"
}

# ---- the real tree ----------------------------------------------------------

globs=$(deny_globs "$SETTINGS")
if [ "$(printf '%s\n' "$globs" | grep -c .)" -ge 5 ] && printf '%s\n' "$globs" | grep -qx 'python\* -\*c \*'; then
    ok "deny list yields the interpreter code-argument rows, python among them"
else
    bad "deny list extraction: got: $(printf '%s' "$globs" | tr '\n' '|')"
fi

if out=$(check_tree "$WORKFLOWS" "$CORPUS" "$SETTINGS"); then
    ok "no brief source instructs an interpreter the deny list refuses; jq rule rendered in both modes"
else
    bad "brief sources"
    printf '%s\n' "$out"
fi

# ---- mutants: each reintroduces one defect in a copy and must be red -------

TMP="${TMPDIR:-/tmp}/seat-brief-inline-interpreter.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

mutant() { # <label> <setup-fn>
    local label="$1" setup="$2"
    local wf="$TMP/$label/workflows" corpus="$TMP/$label/config"
    rm -rf "$TMP/$label"
    mkdir -p "$wf" "$corpus"
    cp "$WORKFLOWS/tribunal.js" "$WORKFLOWS/wave.js" "$wf/"
    cp -R "$CORPUS/contracts" "$CORPUS/fragments" "$corpus/"
    "$setup" "$wf" "$corpus"
    check_tree "$wf" "$corpus" "$SETTINGS" > "$TMP/$label.out" 2>&1
    case $? in
        1) ok "mutant $label is red" ;;
        0) bad "mutant $label passed the check (should be red)" ;;
        *) bad "mutant $label could not be checked: $(cat "$TMP/$label.out")" ;;
    esac
}

# m1: the block probe offers python3 again (matches no deny glob; census only)
m1() { sed -i.bak "s/${PROBE_SENTENCE}/parse the JSON (python3 or jq)/" "$1/wave.js"; }
# m2: a contract instructs the exact refused shape
m2() { printf '\nRead the bundle with `python3 -c "import json,sys; print(json.load(sys.stdin))"`.\n' >> "$2/contracts/verify-ac.md"; }
# m3: a fragment instructs a sibling interpreter with a combined flag
m3() { printf '\nParse it with `node -pe "JSON.parse(require(\\"fs\\").readFileSync(0))"`.\n' >> "$2/fragments/evidence-rules.md"; }
# m4: the rule is defined but rendered into only one seat-brief mode
m4() { awk 'BEGIN{seen=0} /^\$\{evidenceParseRule\}$/{ if (seen==0) {seen=1; next} } {print}' "$1/tribunal.js" > "$1/t.tmp" && mv "$1/t.tmp" "$1/tribunal.js"; }
# m5: the rule sentence itself is reworded away
m5() { sed -i.bak "s/${RULE_SENTENCE}/Parse it however you like/" "$1/tribunal.js"; }
# m7: the docket-step side of the rule is dropped from the shared fragment,
# so judge and verify contracts render without it while tribunal.js keeps it
m7() { sed -i.bak "s/${RULE_SENTENCE}/Parse it however you like/" "$2/fragments/evidence-rules.md"; }

mutant m1 m1
mutant m2 m2
mutant m3 m3
mutant m4 m4
mutant m5 m5
mutant m7 m7

# m6: the deny-list source loses its interpreter rows, so (a) must go red
# rather than silently checking nothing.
mkdir -p "$TMP/m6"
sed '/^const SHELL_INDIRECTION_DENY_PATTERNS/,/^\];/{/ -\*[a-z] \*)"/d;/ --\(eval\|print\) \*)"/d}' "$SETTINGS" > "$TMP/m6/claude_code.rs"
check_tree "$WORKFLOWS" "$CORPUS" "$TMP/m6/claude_code.rs" > "$TMP/m6.out" 2>&1
case $? in
    1) ok "mutant m6 is red" ;;
    0) bad "mutant m6 (deny rows removed) passed the check (should be red)" ;;
    *) bad "mutant m6 could not be checked: $(cat "$TMP/m6.out")" ;;
esac

if [ "$fail" -ne 0 ]; then
    echo "seat-brief-inline-interpreter: FAIL" >&2
    exit 1
fi
echo "seat-brief-inline-interpreter: PASS ($pass checks)"
