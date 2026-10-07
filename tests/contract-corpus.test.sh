#!/bin/bash

# Regression coverage for the docket contract corpus's denial-disclosure
# duty: nothing else in this tree checks it. frozen-drift-check's own header
# puts contracts/*.md and policy.toml out of its scope, doc-validate scopes
# to docs/*.md, and `just tests` runs only Rust unit tests under src/*.rs
# that never read src/user/docket/config/. A duty added to a contract or
# fragment today could be weakened or deleted tomorrow with every other gate
# green.
#
# This suite pins four clause tokens of the denial-disclosure duty in
# fragments/completion-gates.md (the refusal-match rule, the both-channels
# disclosure requirement, the retry-disclosure clause, and the redaction
# clause) plus the Denials slot in contracts/implement.md's # Emit. Each
# clause is checked by grepping the exact phrase that carries the invariant,
# not by a word alone, so a mutant that keeps the word but reverses or drops
# the requirement it states is caught. It also pins the attempt bounds on
# each workflow's non-loop executor steps (section 6).
#
# CORPUS_DIR overrides the directory under test, so a mutation probe can
# point this suite at a deliberately-broken COPY under $TMPDIR without
# touching the checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CORPUS="${CORPUS_DIR:-${SCRIPT_DIR}/../src/user/docket/config}"

GATES="${CORPUS}/fragments/completion-gates.md"
IMPLEMENT="${CORPUS}/contracts/implement.md"

fail=0

# Prose in this corpus wraps at ~90 columns, so a clause worth pinning can
# span a line break. Join each file's paragraphs (blank-line-separated) onto
# single lines before matching, collapsing internal whitespace, so a fixed
# string never has to guess where the source wrapped.
normalize() { # <file>
    awk 'BEGIN{buf=""} /^[[:space:]]*$/{if(buf!=""){print buf; buf=""}; next} {buf=(buf==""?$0:buf" "$0)} END{if(buf!="")print buf}' "$1" \
        | tr -s ' '
}

require() { # <file> <label> <fixed-string pattern>
    local file="$1" label="$2" pattern="$3"
    if [ ! -f "$file" ]; then
        echo "FAIL ${label}: no file at ${file}"
        fail=1
        return
    fi
    # Normalize into a variable first: under pipefail, `normalize | grep -q`
    # fails when grep exits on an early match and SIGPIPEs the writer.
    local text
    text=$(normalize "$file")
    if ! grep -qF -- "$pattern" <<<"$text"; then
        echo "FAIL ${label}: expected clause not found in $(basename "$file")"
        echo "     expected (substring): ${pattern}"
        fail=1
    fi
}

# 1. Refusal-match rule: a refusal is recognized from the returned decision,
#    not from matching one particular message string. A mutant that deletes
#    or inverts this would license a classifier-message-sniffing workaround.
require "$GATES" "refusal-match rule" \
    "Recognize the refusal from the returned decision rather than one particular message string."

# 2. Both-channels wording: a denial goes in BOTH the live step response and
#    the persisted artifact, because the step's return is read live and
#    discarded while the artifact is what the record keeps.
require "$GATES" "both-channels disclosure" \
    "Disclose each denial in both your final step response and the persisted summary"

# 3. Retry-disclosure clause: a retry is reported beside the original denial
#    in both destinations, and the reporting duty itself grants no retry
#    authorization — reporting is not authorizing.
require "$GATES" "retry reported beside the denial" \
    "report its command, authorization if any, and outcome beside the"
require "$GATES" "retry disclosure does not license retrying" \
    "This reporting requirement does not authorize"

# 4. Redaction clause: credentials are redacted from commands, output, and
#    refusal reasons, with each redaction explicitly marked.
require "$GATES" "redaction clause" \
    "Redact credentials from commands, output, and refusal reasons"

# 5. The Denials slot in implement.md's # Emit — the artifact-side half of
#    the duty needs an enumerated slot to land in, or the fragment's
#    requirement has nowhere to be satisfied.
require "$IMPLEMENT" "Denials slot in implement.md's Emit" \
    "**Denials:**"

# 6. Attempt bounds on each workflow's executor steps: a step without
#    max_attempts returns to ready after every failed attempt, so a step the
#    safety classifier keeps stopping is re-offered indefinitely. Each bounded
#    step parks waiting-human instead, leaving any retry past a refusal to the
#    operator. Every [[step]] that declares `executor` and not `loop = true`
#    is listed; a loop body (`fix`, `revise-*`) is bounded by its workflow's
#    max_fix_loops instead.

# Prints the one [[step]] block whose `name` line is <step>, from its header
# to the next table header, so a key is attributed to the step that declares
# it rather than to any line in the file.
step_block() { # <toml> <step>
    awk -v want="name = \"$2\"" '
        /^\[/ { if (in_step && found) exit; in_step = ($0 == "[[step]]"); block = ""; found = 0 }
        in_step { block = block $0 "\n"; if ($0 == want) found = 1 }
        END { if (in_step && found) printf "%s", block }
    ' "$1"
}

require_step_line() { # <toml> <step> <exact line>
    local toml="$1" step="$2" line="$3" block
    block=$(step_block "$toml" "$step")
    if [ -z "$block" ]; then
        echo "FAIL $(basename "$toml") ${step}: no [[step]] block named ${step}"
        fail=1
    elif ! grep -qxF -- "$line" <<<"$block"; then
        echo "FAIL $(basename "$toml") ${step}: its [[step]] block lacks the line: ${line}"
        fail=1
    fi
}

bounded=0
require_bounded() { # <workflow> <step>...
    local toml="${CORPUS}/workflows/$1.toml" step
    shift
    if [ ! -f "$toml" ]; then
        echo "FAIL attempt bounds: no file at ${toml}"
        fail=1
        return
    fi
    for step in "$@"; do
        require_step_line "$toml" "$step" 'max_attempts = 2'
        require_step_line "$toml" "$step" 'on_fail = "waiting-human"'
        bounded=$((bounded + 1))
    done
}

require_bounded security-change threat-model implement synthesize-findings drain-highs verify-ac
require_bounded standard-change implement synthesize-findings drain-highs verify-ac
require_bounded disposition dispose verify-ac
require_bounded docs-only implement review verify-ac

if [ "$fail" -ne 0 ]; then
    echo "contract-corpus: FAIL" >&2
    exit 1
fi
echo "contract-corpus: PASS (6 clauses checked across completion-gates.md and implement.md; ${bounded} workflow steps bounded)"
