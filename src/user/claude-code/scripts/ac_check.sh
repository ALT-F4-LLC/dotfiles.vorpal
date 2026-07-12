#!/bin/bash
# Extracts acceptance-criteria commands from a Docket issue's description and
# runs them, reporting per-AC pass/fail. Replaces the hand-run verification
# ritual duplicated across senior-engineer.md, sdet.md, staff-engineer.md,
# and distinguished-engineer.md.
#
# Extraction heuristic (audited against 203 done issues in this repo's own
# docket: 175 use an "Acceptance Criteria" bold heading; zero use fenced
# bash/sh/shell triple-backtick blocks -- inline single-backtick
# command-shaped spans inside that section are the dominant real-world
# convention here):
#   1. PRIMARY: fenced bash/sh/shell code blocks anywhere in the
#      description (unambiguous signal, kept unscoped for forward
#      compatibility with issues/repos that do use them). Each non-blank,
#      non-comment line inside the fence is one command.
#   2. SECONDARY: inline single-backtick spans, but ONLY within the
#      "Acceptance Criteria" section (from that heading to the next bold
#      heading line, or end of description) -- this section-scope is what
#      keeps false positives out, since backticked spans elsewhere in a
#      description (Where/Design Contracts/template placeholders like
#      {foo}) are overwhelmingly file paths and prose, not commands. A
#      span only counts as a command if its first token is a known command
#      word or a path-like invocation (./, ../, ~/, /, .claude/), and it
#      does not contain a <placeholder> or {template} token.
#   Known gap: a minority of issues continue AC-shaped content under a
#   differently-named heading (e.g. "Additionally") after closing the
#   Acceptance Criteria section -- those commands are not picked up.
set -euo pipefail

usage() {
    echo "Usage: ac_check.sh <issue-id> [--pre]" >&2
    echo "  Default: runs each extracted AC command, reports [PASS|FAIL]," >&2
    echo "    exits non-zero if any failed (PASS = exit 0)." >&2
    echo "  --pre: inverts the expectation -- each AC command is expected to" >&2
    echo "    FAIL against current pre-implementation state (a discriminating" >&2
    echo "    AC must not already be true). Reports [EXPECTED-FAIL|UNEXPECTED-PASS]," >&2
    echo "    exits non-zero if any command unexpectedly passes." >&2
    exit 1
}

[ "$#" -ge 1 ] || usage

ID="$1"
shift
PRE=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --pre) PRE=1 ;;
        *) usage ;;
    esac
    shift
done

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "ac_check.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

ISSUE_JSON=$(docket issue show "$ID" --json) || {
    echo "ac_check.sh: failed to show ${ID}" >&2
    exit 1
}

DESCRIPTION=$(printf '%s' "$ISSUE_JSON" | jq -r '.data.description')

# AC_CHECK_DESCRIPTION is read via os.environ below, not sys.stdin: the
# heredoc already owns stdin to deliver this script to `python3 -`, so
# piping the description in over stdin as well would race the heredoc for
# the same channel and be silently dropped.
COMMANDS=$(AC_CHECK_DESCRIPTION="$DESCRIPTION" python3 - <<'PYEOF'
import os
import re

text = os.environ["AC_CHECK_DESCRIPTION"]
commands = []
seen = set()


def add(cmd):
    if cmd and cmd not in seen:
        seen.add(cmd)
        commands.append(cmd)


BT = chr(96)  # backtick, built at runtime to avoid odd-parity backticks in this heredoc's source

# PRIMARY: fenced bash/sh/shell blocks, anywhere in the description.
fence_re = re.compile(BT * 3 + r"(?:bash|sh|shell)\n(.*?)" + BT * 3, re.DOTALL)
for fence in fence_re.finditer(text):
    for line in fence.group(1).split("\n"):
        line = line.strip()
        if line and not line.startswith("#"):
            add(line)

# Scope inline-backtick extraction to the Acceptance Criteria section only.
lines = text.split("\n")
ac_start = re.compile(r"^\*\*Acceptance Criteria\b", re.IGNORECASE)
bold_heading = re.compile(r"^\*\*[A-Za-z]")
section = []
in_section = False
for line in lines:
    stripped = line.strip()
    if ac_start.match(stripped):
        in_section = True
        continue
    if in_section:
        if bold_heading.match(stripped):
            break
        section.append(line)
scope = "\n".join(section)

CMD_WORDS = {
    "grep", "test", "git", "ls", "cat", "jq", "docket", "python3", "python",
    "bash", "sh", "curl", "find", "diff", "wc", "awk", "sed", "go", "cargo",
    "npm", "node", "rg", "stat", "head", "tail", "file", "env", "vorpal",
    "printf", "echo",
}
PATH_PREFIXES = ("./", "../", "~/", "/", ".claude/")
placeholder = re.compile(r"<[A-Za-z][A-Za-z0-9_-]*>")

inline_re = re.compile(BT + r"([^" + BT + r"\n]+)" + BT)
for m in inline_re.finditer(scope):
    span = m.group(1).strip()
    if not span or "{" in span or placeholder.search(span):
        continue
    first = span.split()[0]
    if first in CMD_WORDS or first.startswith(PATH_PREFIXES):
        add(span)

for c in commands:
    print(c)
PYEOF
)

if [ -z "$COMMANDS" ]; then
    echo "ac_check.sh: no AC-shaped commands found in ${ID}'s description" >&2
    exit 2
fi

TMP_OUT=$(mktemp "${TMPDIR:-/tmp}/ac_check.XXXXXX")
trap 'rm -f "$TMP_OUT"' EXIT

TOTAL=0
GOOD=0
FAILED_ANY=0

while IFS= read -r cmd; do
    [ -n "$cmd" ] || continue
    TOTAL=$((TOTAL + 1))
    RC=0
    bash -c "$cmd" >"$TMP_OUT" 2>&1 || RC=$?

    if [ "$PRE" -eq 1 ]; then
        if [ "$RC" -ne 0 ]; then
            echo "[EXPECTED-FAIL] ${cmd}"
            GOOD=$((GOOD + 1))
        else
            echo "[UNEXPECTED-PASS] ${cmd}"
            FAILED_ANY=1
            sed 's/^/    /' "$TMP_OUT"
        fi
    else
        if [ "$RC" -eq 0 ]; then
            echo "[PASS] ${cmd}"
            GOOD=$((GOOD + 1))
        else
            echo "[FAIL] ${cmd}"
            FAILED_ANY=1
            sed 's/^/    /' "$TMP_OUT"
        fi
    fi
done <<< "$COMMANDS"

if [ "$PRE" -eq 1 ]; then
    echo "${GOOD}/${TOTAL} expected-fail"
else
    echo "${GOOD}/${TOTAL} passed"
fi

[ "$FAILED_ANY" -eq 0 ]
