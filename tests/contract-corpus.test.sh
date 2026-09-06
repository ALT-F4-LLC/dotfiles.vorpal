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
# the requirement it states is caught.
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
    if ! normalize "$file" | grep -qF -- "$pattern"; then
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

if [ "$fail" -ne 0 ]; then
    echo "contract-corpus: FAIL" >&2
    exit 1
fi
echo "contract-corpus: PASS (6 clauses checked across completion-gates.md and implement.md)"
