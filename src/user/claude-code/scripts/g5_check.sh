#!/bin/bash
# Mechanizes code-review-verdict's Hard Gate G5 (unexecuted AC regex): a
# TDD/spec diff that introduces or modifies a regex intended to gate
# verification must actually be RUN against its named target files, not
# merely asserted in prose. This script finds every backtick-quoted `grep`
# command added by the diff within docs/tdd/ or docs/spec/ (G5's own
# detection scope), validates + executes each for real against the
# current working tree, and reports its actual exit code + hit count --
# turning "was this regex ever run" into a mechanical fact instead of
# reviewer diligence.
#
# It ALSO statically flags the specific documented false-negative class:
# under `grep -E`, a `\|` is a LITERAL escaped pipe character (BRE
# alternation syntax), not ERE alternation -- `'a\|b'` matches the literal
# string "a|b", never "a OR b". This is detectable on the pattern text
# alone, independent of execution outcome.
#
# Security: candidate grep commands come from untrusted diff content (a PR
# author controls docs/tdd|docs/spec prose). Every candidate is validated
# before execution -- a quote-aware raw metacharacter scan, a shlex-split
# argv with an exact `argv[0] == "grep"` check, an option-aware flag
# parser that confines FILE operands to the repo root (rejecting
# absolute/traversal paths) and hard-rejects flags that read arbitrary
# files or dereference symlinks out of the repo (-f/--file,
# -R/--dereference-recursive), and a per-command subprocess timeout --
# then executed via subprocess.run(argv, shell=False) with cwd pinned to
# the repo root. Never bash -c.
#
# What this script does NOT do: parse freeform prose for an "expected hit
# count" and diff it against the actual count -- that comparison is exactly
# what G5 exists to force a human/reviewing-agent to do explicitly; this
# script's contribution is guaranteeing the regex was actually executed
# (or safely rejected) and reporting its real result, plus the BRE-pipe
# static check.
set -euo pipefail

usage() {
    echo "Usage: g5_check.sh <scope>" >&2
    echo "  <scope>: \"staged\" | \"uncommitted\" | <branch-name> | <file-path> [<file-path> ...]" >&2
    echo "  Extracts every backtick-quoted 'grep ...' command added (in the diff's" >&2
    echo "  + lines) within docs/tdd/ or docs/spec/, validates + runs each for real" >&2
    echo "  against the current working tree (never via a shell), and reports" >&2
    echo "  [RAN <n> hits], [FAIL], [TIMEOUT], or [REJECTED: <reason>] per command," >&2
    echo "  plus a [BRE-PIPE-WARNING] static flag for an escaped '\\|' under -E." >&2
    echo "  Exit 0 = all candidates ran clean, no rejections/timeouts/warnings." >&2
    echo "  Exit 1 = a candidate failed, was rejected, timed out, or warned." >&2
    echo "  Exit 2 = no candidate regex commands found in scope." >&2
    exit 2
}

[ "$#" -ge 1 ] || usage
SCOPE="$1"
shift

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "g5_check.sh: not inside a git repository" >&2
    exit 2
}
cd "$REPO_ROOT"

PATHSPEC=(-- 'docs/tdd/*' 'docs/spec/*')

case "$SCOPE" in
    staged)
        DIFF=$(git diff --staged "${PATHSPEC[@]}")
        ;;
    uncommitted)
        DIFF=$(printf '%s\n%s' "$(git diff HEAD "${PATHSPEC[@]}")" "$(git diff --staged "${PATHSPEC[@]}")")
        ;;
    *)
        if git rev-parse --verify "$SCOPE" >/dev/null 2>&1; then
            DIFF=$(git diff "main...$SCOPE" "${PATHSPEC[@]}" 2>/dev/null || git diff "$SCOPE" "${PATHSPEC[@]}")
        elif [ -e "$SCOPE" ]; then
            FILES=("$SCOPE" "$@")
            DIFF=$(git diff HEAD -- "${FILES[@]}"; git diff --staged -- "${FILES[@]}")
        else
            echo "g5_check.sh: could not resolve scope '${SCOPE}' (not staged/uncommitted, not a branch, not a file)" >&2
            exit 2
        fi
        ;;
esac

if [ -z "$DIFF" ]; then
    echo "g5_check.sh: no docs/tdd/ or docs/spec/ diff in scope '${SCOPE}'" >&2
    exit 2
fi

# Extraction, validation, execution, and reporting all happen in a single
# python3 process (fed via env vars -- G5_CHECK_DIFF, not stdin, since the
# heredoc already owns stdin to deliver this script to `python3 -`) so
# that no untrusted diff content ever reaches a shell. `set +e` around the
# invocation lets us capture python's real exit code as this script's own,
# instead of `set -e` aborting the script on a nonzero (expected) exit.
set +e
G5_CHECK_DIFF="$DIFF" \
G5_CHECK_REPO_ROOT="$REPO_ROOT" \
G5_CHECK_SCOPE="$SCOPE" \
G5_CHECK_TIMEOUT="${G5_CHECK_TIMEOUT:-10}" \
python3 - <<'PYEOF'
import os
import re
import shlex
import subprocess
import sys

diff = os.environ["G5_CHECK_DIFF"]
repo_root = os.path.realpath(os.environ["G5_CHECK_REPO_ROOT"])
scope = os.environ.get("G5_CHECK_SCOPE", "")
timeout = float(os.environ.get("G5_CHECK_TIMEOUT", "10"))

BT = chr(96)
inline_re = re.compile(BT + r"([^" + BT + r"\n]+)" + BT)

commands = []
seen = set()
for line in diff.split("\n"):
    if not line.startswith("+") or line.startswith("+++"):
        continue
    added_text = line[1:]
    for m in inline_re.finditer(added_text):
        span = m.group(1).strip()
        if not span or not span.startswith("grep"):
            continue
        if span not in seen:
            seen.add(span)
            commands.append(span)

if not commands:
    print(
        "g5_check.sh: no backtick-quoted 'grep ...' commands added in "
        f"docs/tdd/ or docs/spec/ diff for scope '{scope}'",
        file=sys.stderr,
    )
    sys.exit(2)


class Rejected(Exception):
    def __init__(self, reason):
        super().__init__(reason)
        self.reason = reason


METACHARS = set(";|&`<>\n")


def has_unquoted_metachar(span):
    # Quote-aware: a `|` inside 'single quotes' is legitimate ERE
    # alternation text (e.g. `grep -E 'a|b' file`), not a shell
    # metacharacter -- only flag one that appears OUTSIDE any quoting,
    # which is what an actual injection attempt requires (shell=False
    # already makes these inert; this is a belt-and-suspenders signal).
    quote = None
    i = 0
    n = len(span)
    while i < n:
        c = span[i]
        if quote:
            if quote == '"' and c == "\\" and i + 1 < n:
                i += 2
                continue
            if c == quote:
                quote = None
        else:
            if c in ("'", '"'):
                quote = c
            elif c == "\\" and i + 1 < n:
                i += 2
                continue
            elif c in METACHARS:
                return True
            elif c == "$" and i + 1 < n and span[i + 1] == "(":
                return True
        i += 1
    return False


# GNU grep flag tables used by the option-aware argv walker below.
# Fail-closed: any '-'-prefixed token not recognized in these tables
# rejects the whole command rather than guessing its arity.
BOOLEAN_SHORT = set("ivwxlLnHhoqsrIcEGFPTUza")
NUMERIC_ARG_SHORT = set("ABCm")
REJECT_LONG = {
    "--file": "-f/--file (external pattern file) is not allowed",
    "--dereference-recursive": (
        "-R/--dereference-recursive not allowed: follows symlinks "
        "encountered during recursion, escaping repo-root confinement"
    ),
}
BOOLEAN_LONG = {
    "--ignore-case", "--invert-match", "--word-regexp", "--line-regexp",
    "--files-with-matches", "--files-without-match", "--line-number",
    "--with-filename", "--no-filename", "--only-matching", "--quiet",
    "--silent", "--no-messages", "--recursive", "--text", "--binary",
    "--extended-regexp", "--fixed-strings", "--basic-regexp",
    "--perl-regexp", "--null-data", "--count", "--byte-offset",
    "--line-buffered", "--null", "--help", "--version", "--color",
    "--colour",
}
ARG_LONG = {
    "--regexp", "--after-context", "--before-context", "--context",
    "--max-count", "--include", "--exclude", "--exclude-dir",
    "--exclude-from", "--devices", "--directories", "--label",
    "--binary-files",
}


def confine_file_operand(tok, repo_root):
    if tok == "-":
        return  # stdin sentinel, no filesystem access
    if ".." in tok.split(os.sep):
        raise Rejected(f"file operand contains parent-directory traversal: {tok!r}")
    candidate = tok if os.path.isabs(tok) else os.path.join(repo_root, tok)
    resolved = os.path.realpath(candidate)
    if resolved != repo_root and not resolved.startswith(repo_root + os.sep):
        raise Rejected(f"file operand resolves outside repo root: {tok!r} -> {resolved}")


def parse_grep_argv(argv, repo_root):
    if not argv or argv[0] != "grep":
        raise Rejected("argv[0] != 'grep' (exact match required)")

    pattern_supplied = False
    no_more_options = False
    i = 1
    n = len(argv)
    while i < n:
        tok = argv[i]

        if no_more_options:
            if not pattern_supplied:
                pattern_supplied = True
            else:
                confine_file_operand(tok, repo_root)
            i += 1
            continue

        if tok == "--":
            no_more_options = True
            i += 1
            continue

        if tok.startswith("--"):
            name, sep, _value = tok.partition("=")
            if name in REJECT_LONG:
                raise Rejected(REJECT_LONG[name])
            if name == "--regexp":
                pattern_supplied = True
                i += 1
                continue
            if name in ARG_LONG:
                if sep:
                    i += 1
                    continue
                if i + 1 >= n:
                    raise Rejected(f"{name} missing required argument")
                i += 2
                continue
            if name in BOOLEAN_LONG:
                i += 1
                continue
            raise Rejected(f"unrecognized long flag {name!r}")

        if tok.startswith("-") and tok != "-" and len(tok) > 1:
            # Only -e/-f/-A/-B/-C/-m/-D/-d take a value (glued or next
            # token); -f and -R are hard-rejected wherever they appear in
            # the cluster; everything else must be a known boolean flag.
            cluster = tok[1:]
            j = 0
            consumed_next = False
            while j < len(cluster):
                c = cluster[j]
                if c == "f":
                    raise Rejected(REJECT_LONG["--file"])
                elif c == "R":
                    raise Rejected(REJECT_LONG["--dereference-recursive"])
                elif c in NUMERIC_ARG_SHORT:
                    rest = cluster[j + 1:]
                    if rest:
                        if not rest.isdigit():
                            raise Rejected(f"malformed -{c} argument {rest!r}")
                    else:
                        if i + 1 >= n:
                            raise Rejected(f"-{c} missing required argument")
                        consumed_next = True
                    break
                elif c == "e":
                    pattern_supplied = True
                    rest = cluster[j + 1:]
                    if not rest:
                        if i + 1 >= n:
                            raise Rejected("-e missing required argument")
                        consumed_next = True
                    break
                elif c in ("D", "d"):
                    rest = cluster[j + 1:]
                    if not rest:
                        if i + 1 >= n:
                            raise Rejected(f"-{c} missing required argument")
                        consumed_next = True
                    break
                elif c in BOOLEAN_SHORT:
                    j += 1
                else:
                    raise Rejected(f"unrecognized short flag -{c}")
            i += 2 if consumed_next else 1
            continue

        # Positional operand: PATTERN (first one, unless -e/--regexp
        # already supplied it -- PATTERN is regex text, never opened as a
        # file, so it needs no path confinement even if it looks like a
        # path), then FILE operands (confined to repo_root).
        if not pattern_supplied:
            pattern_supplied = True
        else:
            confine_file_operand(tok, repo_root)
        i += 1


results = []
total = 0
flagged = 0

for cmd in commands:
    total += 1
    lines_out = []

    bre_pipe = bool(re.search(r"-[A-Za-z]*E[A-Za-z]*\b", cmd)) and ("\\|" in cmd)

    try:
        if has_unquoted_metachar(cmd):
            raise Rejected("unquoted shell metacharacter present")
        try:
            argv = shlex.split(cmd)
        except ValueError as e:
            raise Rejected(f"could not parse quoting: {e}")
        parse_grep_argv(argv, repo_root)
    except Rejected as e:
        lines_out.append(f"[REJECTED: {e.reason}] {cmd}")
        flagged += 1
    else:
        try:
            proc = subprocess.run(
                argv,
                shell=False,
                cwd=repo_root,
                capture_output=True,
                text=True,
                timeout=timeout,
                stdin=subprocess.DEVNULL,
            )
        except subprocess.TimeoutExpired:
            lines_out.append(f"[TIMEOUT >{timeout:g}s] {cmd}")
            flagged += 1
        else:
            output = proc.stdout + proc.stderr
            hits = len(output.splitlines())
            if proc.returncode == 0:
                lines_out.append(f"[RAN {hits} hits] {cmd}")
            else:
                lines_out.append(f"[FAIL rc={proc.returncode}] {cmd}")
                lines_out.extend("    " + l for l in output.splitlines())
                flagged += 1

    if bre_pipe:
        lines_out.append(
            "[BRE-PIPE-WARNING] escaped '\\|' under -E flag "
            f"(literal pipe, not alternation): {cmd}"
        )
        flagged += 1

    results.append("\n".join(lines_out))

print("\n".join(results))
print(f"{total - flagged}/{total} clean")
sys.exit(0 if flagged == 0 else 1)
PYEOF
RC=$?
set -e
exit "$RC"
