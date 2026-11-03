#!/bin/bash

# direnv-env — SessionStart and CwdChanged.
#
# The corpus calls `go` bare (fragments/vorpal-toolchain.md): each Go
# repository's Vorpal dev shell, loaded from its `.envrc`, supplies it. The
# Bash tool starts from the launch environment (through its shell snapshot)
# plus CLAUDE_ENV_FILE, and runs no direnv hook of its own, so a session
# launched anywhere but a direnv-loaded repository never sees that
# repository's `go`, and neither do its executors or the gates `docket` runs
# for them, which inherit the session's PATH. This hook loads the dev shell
# for the session's directory into CLAUDE_ENV_FILE, whose exports reach every
# later Bash command.
#
# THE DIRECTORY is `new_cwd` on CwdChanged and `cwd` on SessionStart. The
# hook runs `direnv export bash` there, which diffs the target directory's
# environment against the harness's own (the launch shell's), so the output
# is a complete replacement: an empty diff means the directory needs nothing
# beyond the launch environment.
#
# THE LAUNCH ENVIRONMENT IS THE FLOOR. Under `direnv exec . claude`, or a
# launch shell whose direnv hook loaded a repo, the harness environment
# already carries that dev shell and direnv's DIRENV_DIFF for it. In a
# directory with no `.envrc` of its own (a scratch dir, ~/.claude/workflows)
# `direnv export` would unload it, and the Bash tool would lose `go` and
# `cargo` until a `cd` back into the repo. So the hook asks `direnv status`
# first, which evaluates nothing, and treats a directory without an rc file
# as an empty diff. A directory with its own `.envrc` still gets the full
# export, which swaps in that repository's dev shell.
#
# ONE BLOCK. The hook owns the lines between its two markers in
# CLAUDE_ENV_FILE and rewrites them on every run, leaving other hooks' lines
# alone. An empty diff removes the block, which returns the session to the
# launch environment.
#
# UNSANDBOXED. A hook is a harness child process, not a Bash-tool call, so
# `.envrc` runs outside the Claude Code sandbox; in a Vorpal repository that
# includes `vorpal build --path <shell>`. direnv's own allow list is the
# gate: a `.envrc` the operator has not `direnv allow`ed is never executed,
# and the hook names it instead. A cold dev-shell build can be slow; the
# harness timeout on this hook bounds it, and the next CwdChanged or session
# start retries.
#
# STDOUT IS CONTEXT on SessionStart, so the hook prints one line when it loads
# or clears an environment, or when direnv refuses, and nothing otherwise.
#
# EXIT 0 ALWAYS. Neither event can block, and a failed export leaves
# CLAUDE_ENV_FILE as it was.

BEGIN_MARK='# >>> direnv-env-hook >>>'
END_MARK='# <<< direnv-env-hook <<<'

[ -n "${CLAUDE_ENV_FILE:-}" ] || exit 0
command -v direnv >/dev/null 2>&1 || exit 0

INPUT=$(cat)
DIR=$(printf '%s' "$INPUT" | jq -r '.new_cwd // .cwd // empty' 2>/dev/null)
[ -n "$DIR" ] || DIR=$PWD
[ -d "$DIR" ] || exit 0

ERR=$(mktemp "${TMPDIR:-/tmp}/direnv-env-hook.XXXXXX") || exit 0
trap 'rm -f "$ERR" "${NEXT:-}"' EXIT

# FOUND is the rc path direnv would load in $DIR, empty when there is none,
# or `?` when status is unavailable, which falls back to the plain export.
FOUND='?'
if STATUS=$(cd "$DIR" && direnv status --json 2>/dev/null) && [ -n "$STATUS" ]; then
    FOUND=$(printf '%s' "$STATUS" | jq -r \
        'if (.state | type) == "object" then (.state.foundRC.path // "") else "?" end' \
        2>/dev/null) || FOUND='?'
fi

if [ -z "$FOUND" ]; then
    EXPORTS=''
elif ! EXPORTS=$(cd "$DIR" && direnv export bash 2>"$ERR"); then
    if grep -q 'is blocked' "$ERR"; then
        echo "direnv-env: $DIR has a .envrc that is not allowed; run \`direnv allow\` there to load its dev shell"
    else
        echo "direnv-env: direnv export failed in $DIR; CLAUDE_ENV_FILE unchanged: $(tail -n 1 "$ERR")"
    fi
    exit 0
fi
if grep -q 'is blocked' "$ERR"; then
    echo "direnv-env: $DIR has a .envrc that is not allowed; run \`direnv allow\` there to load its dev shell"
    exit 0
fi

had_block=0
[ -f "$CLAUDE_ENV_FILE" ] && grep -qxF "$BEGIN_MARK" "$CLAUDE_ENV_FILE" && had_block=1

NEXT=$(mktemp "${TMPDIR:-/tmp}/direnv-env-hook.XXXXXX") || exit 0
if [ -f "$CLAUDE_ENV_FILE" ]; then
    awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
        $0 == b { skip = 1; next }
        $0 == e { skip = 0; next }
        !skip
    ' "$CLAUDE_ENV_FILE" >"$NEXT" || exit 0
fi
if [ -n "$EXPORTS" ]; then
    {
        printf '%s\n' "$BEGIN_MARK"
        printf '%s\n' "$EXPORTS"
        printf '%s\n' "$END_MARK"
    } >>"$NEXT"
fi
cat "$NEXT" >"$CLAUDE_ENV_FILE" || exit 0

if [ -n "$EXPORTS" ]; then
    echo "direnv-env: loaded the environment for $DIR"
elif [ "$had_block" -eq 1 ]; then
    echo "direnv-env: cleared the loaded environment; $DIR needs none beyond the launch shell"
fi

exit 0
