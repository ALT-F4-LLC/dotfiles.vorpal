#!/bin/bash

# git-gh-guard: PreToolUse: Bash.
#
# The operator's rule for git and the GitHub CLI: every command is allowed
# except three.
#   1. A push to a default branch (`main`, `master`, or the branch GitHub
#      reports as the repository's default). A push to any other branch is
#      fine.
#   2. Merging a pull request.
#   3. Overriding a git or GitHub permission that exists outside the sandbox:
#      credentials and sign-in, hook and signature bypasses, config that
#      reroutes or re-authenticates a push, and GitHub access controls
#      (default branch, visibility, protection, rulesets, keys, members).
#      Ordinary repository administration is not on the list.
# This hook is the mechanical half of that rule. It exits 2, a pre-permission
# hard stop, in every seat: main conversation, subagents and workflow agents
# alike. The operator runs an excepted command themselves with `! <command>`.
# The auto-mode `hard_deny` prose in src/user/claude_code.rs is the other
# half and covers intent this text reader cannot see.
#
# WHAT LEAVES THE SANDBOX. `sandbox.excludedCommands` lifts the sandbox only
# when its entries cover every top-level command in the Bash call. Measured
# on Claude Code 2.1.323: `gh ...; other`, `true && gh ...` and `gh ... |
# head` all stay sandboxed, while `gh a && gh b` leaves it. `git push`,
# `git fetch` and `git ls-remote` are excluded so such a call reaches the
# operator's SSH agent; beside any other command they have no SSH. This hook
# treats a call as one that MAY leave the sandbox unless some top-level
# command in it is a literal name outside OUT_NAMES below, a list a test in
# src/user/claude_code.rs holds equal to the excluded commands. A call with
# a subshell or a substitution always counts as one that may leave. Sandboxed
# `gh` still reads its keyring token and reaches the API, so the gh rules
# below apply in every position.
#
# THE TWO CLASSES.
#   Transport, checked strictly: `git push` anywhere, and `git fetch` or
#     `git ls-remote` in a call that may leave the sandbox. A push must be
#     the only command: `git push [flags] <remote> <branch>...`, every word a
#     plain literal, flags from an allowlist, the remote a configured name
#     whose push URLs are all github.com repositories, every destination a
#     literal branch or tag that is not a default branch, and a source with
#     no `:<destination>` the plain name of a local branch or tag. The
#     repository must be the session's project repository, its local config
#     may hold only allowlisted keys, and no hook that a push, fetch or
#     checkout runs may exist, because the unsandboxed git would execute
#     them. One push is exempt: inside a call that stays sandboxed, from a
#     scratch repository, to a configured remote whose URLs are local paths.
#   Other verbs that leave the sandbox, checked as strictly in a call that
#     may leave it: `git pull`, `git clone`, `git remote update|prune`,
#     `git worktree add|remove|move|prune`, `git branch` with an upstream
#     flag, `git config set|unset` and `git submodule update|init|sync`. The
#     sandbox denies them SSH, the repository `config` or its `worktrees`
#     directory, so the operator ruled them out of it. Each must be the only
#     command, every word a plain literal, flags from an allowlist, in the
#     session's project repository under the same config rule. A verb that
#     checks out, merges or commits (pull, worktree add, submodule) is
#     refused when any hook file exists. A directory git creates (clone,
#     worktree add or move, and `gh repo clone`) must lie in a Claude scratch
#     root or the project, never inside `.git` or `.claude` except a
#     checkout's `.claude/worktrees/<name>`, with those names read in any
#     letter case. `git config set` writes only an allowlisted,
#     non-dangerous key of the repository's own config, and under `remote.`
#     only `tagopt` and `prune`. `git worktree remove|move` names a
#     registered worktree other than the checkout the call runs in, without
#     `--force`. `git submodule` reads `.gitmodules` from the file, the index
#     and HEAD, reads each git directory under `modules`, requires every
#     submodule path's `.git` to be a gitfile into `modules`, and refuses
#     `--recursive`. A repository counts as having submodules when any of
#     those copies, an index gitlink or a `modules` entry exists. Beside
#     `cd <dir> &&` such a call stays sandboxed and gets the loose checks
#     instead.
#   Everything else, checked for the excepted spellings only: the gh command
#     tree (merge, sign-in, keys, aliases, extensions, `gh api` writes to
#     merge, default-branch, protection and access endpoints, GraphQL
#     mutations of the same kind), and sandboxed git that sets a dangerous
#     config key, edits remotes, or skips hooks or signing in a real
#     repository. A repository under a temp root that is not the project's
#     counts as scratch and is left alone when the git command names it as
#     `git -C <absolute dir>`, so throwaway test repositories keep working.
#     The shell's directory is never followed. gh's short subcommand names (`new`, `ls`, `pr co`) get
#     the long name's checks. A hook manager's off switch (`HUSKY=0`,
#     `HUSKY_SKIP_HOOKS`, `LEFTHOOK=0`) counts as a hook skip.
#   Run alone: `gh gist create|edit`, `gh repo create|fork|delete` and
#     `gh release create|upload|delete` must be the only command in the call
#     and start with the word `gh` (no wrapper, no prefix), the one form
#     known to leave the sandbox, where the permission classifier judges it.
#
# IN-CALL INDIRECTION. Git or gh behind a wrapper (`env`, `timeout`,
# `command`, `xargs`) or behind any command that is not a text command
# (`ssh host gh ...`, `fd -x gh ...`) is read as the command that runs and
# checked like a direct call, and so is a path that ends in the name
# (`"$HOMEBREW_PREFIX/bin/gh"`). A name with a flag after it counts only when
# one of its own subcommands follows, so `tree ~/.config/gh -L 2` is a path.
# `command -v` is a lookup. Names are read without regard to case,
# because the volume folds it. A git or gh command the call hides is refused
# where this reader can see the hiding: text handed to a shell (also behind
# a wrapper flag that takes a value, `xargs -I {} sh -c '...'`, and behind
# another command when the text holds git or gh with a subcommand or a flag,
# `nix develop -c bash -c 'gh pr merge 5'`), `eval`,
# `trap`, `env -S`, `find -exec` or a git verb that runs commands
# (`rebase --exec`, `bisect run`, `submodule foreach`); a shell reading
# standard input; a command word that is a variable, a lookup
# (`$(which gh)`), a `${X:-gh}` default, a brace list or a loop variable in
# a call that names git or gh as a value; a second name made with `ln`,
# `cp` or `hash -p`; an editor, pager or helper setting whose value is a git
# or gh command; and git or gh behind a runner that builds the environment
# (`op run`, `doppler run`). An array whose first word is git or gh
# (`cmd=(gh pr merge 5)`) is checked as that command. A git or gh command
# with a bare `{`, `}` or `]]` among its words is refused, because zsh ends
# the command there and bash reads an argument.
#
# KNOWN RESIDUALS, listed so a reader can tell a decision from a miss.
#   - This hook reads text. It stops the spellings an agent writes by habit
#     or by mistake and is not a boundary against a command built to get
#     past it: a script file, an interpreter, a variable set in an earlier
#     call, or a glob that resolves to the program without spelling its name
#     all run where this hook reads nothing. Sandboxed `gh` reads its keyring
#     token and reaches the API, so such a command can merge or write a
#     default branch. The hard_deny prose covers the calls the classifier
#     sees; a sandboxed call reaches no classifier. Server-side branch
#     protection is what stands there, and protection that exempts
#     administrators does not stop an administrator's token.
#   - Writes to `.git/config` and `.git/hooks` by other programs (`printf
#     ... >> .git/config`) are not read; the sandbox's write protection of
#     those paths is the control.
#   - `--body-file`, `--input` and `-F name=@file` contents are not read,
#     and neither are shell aliases or functions defined outside the call.
#   - A variable that holds a git or gh command, passed as an argument to a
#     command this hook does not know (`cmd='gh pr merge 5'; retry 3 $cmd`),
#     is not read, and neither is a flag kept in one
#     (`f=(--no-verify); git commit "${f[@]}"`) or an array that puts a
#     wrapper first (`cmd=(env gh pr merge 5); run "${cmd[@]}"`).
#   - Hook-manager switches with generic names (pre-commit's `SKIP=`,
#     `PRE_COMMIT_ALLOW_NO_CONFIG=`) are not read.
#   - `gh api` writes and `gh pr create|comment|edit` beside other commands
#     stay sandboxed and reach no classifier; only the commands under "Run
#     alone" are forced out.
#   - A variable in a `gh api` write endpoint is tried as a fixed list of
#     words; a value outside that list that spells a blocked path passes.
#   - Scratch is decided from a literal absolute `git -C` path. A `cd`, a
#     relative `-C` word and `git -C "$TMPDIR/r"` leave the target unknown,
#     so the scratch exemptions do not apply to that call.
#   - Every verb that leaves the sandbox is refused in a repository whose
#     local config holds a key outside the allowlist or that has a hook the
#     verb runs: husky's `core.hooksPath`, git-lfs, a partial clone, a
#     submodule URL off github.com. The operator runs the command there.
#   - The repository checks read state before the command runs. A process
#     left running by an earlier sandboxed call can change sandbox-writable
#     state in between.
#   - `git worktree remove` of another session's clean checkout passes this
#     hook; only git's own lock and dirty-tree checks and the classifier
#     stand there.
#   - Nested submodules over SSH stay out of reach: `--recursive` is
#     refused, and a submodule's own repository is not the project's.
#
# Exit 0 allow / exit 2 deny with the reason on stderr, this hook family's
# contract. Fails CLOSED when it cannot read a command that names git or gh:
# no `jq`, no lexer result, an unreadable construct, or its own wall-clock
# bound. Behavior is pinned by tests/git-gh-guard-hook.test.sh.

set -o pipefail

PREFIX='git-gh-guard:'
OPERATOR='If the operator wants it run, they type it themselves as `! <command>`.'

deny() {
    printf '%s %s\n' "$PREFIX" "$1" >&2
    exit 2
}

INPUT=$(cat 2>/dev/null) || exit 0

RE_MENTION='(^|[^[:alnum:]_])([Gg][Ii][Tt]|[Gg][Hh])([^[:alnum:]_]|$)'
# The same test for input this hook could not parse as JSON. It asks for a
# blank after the name, so a path such as `repo.git/main` in the cwd field
# does not refuse every Bash call of a session with no jq.
RE_RAW_MENTION='(^|[^[:alnum:]_./-])([Gg][Ii][Tt]|[Gg][Hh])([[:space:]]|\\[nt])'

if ! command -v jq >/dev/null 2>&1; then
    if [[ $INPUT =~ $RE_RAW_MENTION ]]; then
        deny "jq is not on PATH, so this hook cannot read the command to check its git or gh use. This is an installation defect; report it."
    fi
    exit 0
fi

TOOL_NAME='' CTRL='' HOOK_CWD='' COMMAND=''
{
    IFS= read -r -d $'\036' TOOL_NAME
    IFS= read -r -d $'\036' CTRL
    IFS= read -r -d $'\036' HOOK_CWD
    IFS= read -r -d $'\036' COMMAND
} < <(printf '%s' "$INPUT" | jq -j '
    (.tool_input.command // "" | tostring) as $c
    | (.tool_name // "" | tostring), "\u001e",
      (if ($c | test("[\u001d-\u001f]")) then "1" else "0" end), "\u001e",
      (.cwd // "" | tostring), "\u001e",
      ($c | gsub("[\u001d-\u001f]"; "")), "\u001e"' 2>/dev/null)

if [ -z "$TOOL_NAME" ]; then
    if [[ $INPUT =~ $RE_RAW_MENTION ]]; then
        deny "the hook input is not readable JSON, so a command naming git or gh cannot be checked."
    fi
    exit 0
fi
[ "$TOOL_NAME" = "Bash" ] || exit 0
[ -n "$COMMAND" ] || exit 0

# Cheap exit for the common case. The test runs on the text with quotes,
# backslashes and line continuations removed, so `g'i't` still reads as git.
STRIPPED=${COMMAND//$'\\\n'/}
STRIPPED=${STRIPPED//[\'\"\\]/}
# A second reading with each quote, backslash and `\n` escape as a break:
# `su -c"gh pr merge 5"`, `bash -c $'set -e\ngh pr merge 5'`.
SPACED=${COMMAND//\\[ntr]/ }
SPACED=${SPACED//[\'\"\\]/ }
[[ $STRIPPED =~ $RE_MENTION ]] || [[ $SPACED =~ $RE_MENTION ]] || exit 0

[ "$CTRL" = "0" ] || deny "this command carries a control byte (0x1d to 0x1f) that the hook uses to frame its own analysis. Remove the byte."
[ "${#COMMAND}" -le 262144 ] || deny "this command is over 256 KiB, more than the hook checks in one call. Split it into smaller Bash calls."

# --- Wall-clock bound. ----------------------------------------------------
# The harness runs the Bash call unchecked when a hook outlives its timeout,
# so the check runs in a child under a bound and a fired bound denies. The
# default-branch lookup is the only step that waits on the network. Same
# construction as docket-commit-guard-hook.sh.
if [ -z "${GIT_GH_GUARD_BOUNDED:-}" ]; then
    GUARD_BOUND=${GIT_GH_GUARD_BOUND_SECONDS:-30}
    case $GUARD_BOUND in
        [1-9] | [1-9][0-9] | [12][0-9][0-9] | 300) ;;
        *) GUARD_BOUND=30 ;;
    esac
    exec 4>&1 5>&2
    GUARD_STATUS=$(
        exec 2>/dev/null
        set -m
        {
            printf '%s' "$INPUT" | GIT_GH_GUARD_BOUNDED=1 "$BASH" "$0" >&4 2>&5 4>&- 5>&-
            printf '%s\n' "${PIPESTATUS[1]}"
        } | {
            if read -t "$GUARD_BOUND" -r guard_rc; then
                printf '%s' "$guard_rc"
                exit 0
            fi
            printf 'bound'
            kill -KILL 0
        }
    )
    case $GUARD_STATUS in
        bound) deny "the check did not finish within its ${GUARD_BOUND} s wall-clock bound (GIT_GH_GUARD_BOUND_SECONDS), so the command is refused rather than passed through unchecked." ;;
        [0-9] | [0-9][0-9] | [0-9][0-9][0-9]) exit "$GUARD_STATUS" ;;
    esac
    exit 1
fi

# --- Lexer. -----------------------------------------------------------------
# One awk pass turns the command text into words grouped by simple command
# ("segment"): quote-aware, heredoc bodies skipped, command substitutions and
# subshells opened as their own segments. Each word carries flags:
#   D  an expansion inside double quotes (one word, unknown text)
#   U  an unquoted expansion (unknown text, may be several words)
#   X  ANSI-C quoting, read as unknown text
#   G  an unquoted glob, brace list or tilde
#   R  the target of a file redirection     P  the target of an fd duplication
# Every expansion is written into the word as one 0x1f byte. Records are
# seg 0x1d flags 0x1d text 0x1e, after one status record that also counts
# the subshells and substitutions the command opens.
# shellcheck disable=SC2016
LEXER='
function endword(   k, f) {
    if (inw) {
        k = ++NW[cur]; W[cur, k] = w; f = wf
        if (nextR == 1) f = f "R"
        if (nextR == 2) f = f "P"
        nextR = 0; F[cur, k] = f
    }
    w = ""; wf = ""; inw = 0
}
function endseg() {
    endword(); nextR = 0
    if (NW[cur] > 0) cur = ++nseg
}
function push(t) {
    nstruct++
    sp++; ST[sp] = t; Scur[sp] = cur; Sw[sp] = w; Swf[sp] = wf
    Sinw[sp] = inw; Smode[sp] = mode; SnR[sp] = nextR
    cur = ++nseg; w = ""; wf = ""; inw = 0; mode = "n"; nextR = 0
}
function pop() {
    endword()
    cur = Scur[sp]; w = Sw[sp]; wf = Swf[sp]; inw = Sinw[sp]
    mode = Smode[sp]; nextR = SnR[sp]; sp--
}
function names(t) {
    return tolower(t) ~ /(^|[^a-z0-9_])(git|gh)([^a-z0-9_]|$)/
}
function btick(i, fl) {
    # The shell ends a backtick body at the first backtick with no backslash
    # before it and unescapes the body before it parses it. This lexer reads
    # the body in place, so anything that would make the two readings differ
    # (a backslash, or a quote, comment or heredoc that runs past the closing
    # backtick) sets bbad and the command is refused.
    if (sp > 0 && ST[sp] == "b") { pop(); inb--; return i + 1 }
    wf = wf fl; inw = 1; w = w "\037"; push("b"); inb++
    return i + 1
}
function arith(k,   depth, body, e) {
    # An arithmetic body: from k to the `))` that closes the two parens
    # already open. Returns the index after it, or 0 when it never closes or
    # its closing parens are apart, in which case the caller reads it as a
    # substitution or a subshell. A body that names git or gh is read as
    # commands too, so a substitution inside it is checked
    # (`$(( $(git rev-list --count HEAD) + 1 ))`), unless it holds a
    # character the two readings treat differently (a shift reads as a
    # heredoc, `#` as a comment, a quote or backslash as quoting): that body
    # is refused.
    depth = 2; body = ""
    while (k <= n) {
        e = CH[k]
        if (e == "(") depth++
        else if (e == ")") {
            depth--
            if (depth == 1 && CH[k + 1] != ")") return 0
            if (depth == 0) break
        }
        body = body e; k++
    }
    if (k > n) return 0
    if (names(body)) {
        if (!(index(body, "<<") || index(body, "#") || index(body, "\\") || index(body, SQ) || index(body, "\""))) return 0
        abad = 1
    }
    return k + 1
}
function dollar(i, q,   d, fl, j, depth, body, e) {
    d = CH[i + 1]; fl = q ? "D" : "U"
    if (d == "(") {
        if (CH[i + 2] == "(") {
            j = arith(i + 3)
            if (j > 0) { wf = wf fl; inw = 1; w = w "\037"; return j }
        }
        wf = wf fl; inw = 1; w = w "\037"; push("s"); return i + 2
    }
    if (d == "[") {
        # `$[ ... ]`, the old arithmetic form: its body is not read here.
        abad = 1
        wf = wf fl; inw = 1; w = w "\037"
        return i + 2
    }
    if (d == "{") {
        depth = 1; j = i + 2; body = ""
        while (j <= n && depth > 0) {
            e = CH[j]
            if (e == "{") depth++
            else if (e == "}") depth--
            else if (e == "\\") { j++; if (inb > 0) bbad = 1 }
            if (depth > 0) body = body e
            j++
        }
        if (index(body, "$(") || index(body, "`") || index(body, "\"") || index(body, SQ)) complex = 1
        # `${X:-gh}` can put the name in a command word.
        if (names(body)) vtaint = 1
        wf = wf fl; inw = 1; w = w "\037"
        return j
    }
    if (d == SQ && !q) {
        j = i + 2
        while (j <= n && CH[j] != SQ) {
            if (inb > 0 && (CH[j] == "\\" || CH[j] == "`")) bbad = 1
            # An escape spells a character this lexer does not decode
            # (`$'core.hooksP\x61th'`): it is unknown text, like an expansion.
            if (CH[j] == "\\") { w = w "\037"; j += 2; continue }
            w = w CH[j]; j++
        }
        if (j > n) unq = 1
        wf = wf "X"; inw = 1
        return j + 1
    }
    if (d == "\"" && !q) return i + 1
    if (d ~ /[A-Za-z_]/) {
        j = i + 1
        while (j <= n && CH[j] ~ /[A-Za-z0-9_]/) j++
        wf = wf fl; inw = 1; w = w "\037"
        return j
    }
    if (d ~ /[0-9@*#?$!-]/) { wf = wf fl; inw = 1; w = w "\037"; return i + 2 }
    w = w "$"; inw = 1
    return i + 1
}
function heredoc_decl(i,   strip, delim, q, c) {
    if (inb > 0) bbad = 1
    strip = 0
    if (CH[i] == "-") { strip = 1; i++ }
    while (CH[i] == " " || CH[i] == "\t") i++
    delim = ""; q = 0
    while (i <= n) {
        c = CH[i]
        if (c == SQ) {
            q = 1; i++
            while (i <= n && CH[i] != SQ) { delim = delim CH[i]; i++ }
            i++; continue
        }
        if (c == "\"") {
            q = 1; i++
            while (i <= n && CH[i] != "\"") { delim = delim CH[i]; i++ }
            i++; continue
        }
        if (c == "\\") { q = 1; delim = delim CH[i + 1]; i += 2; continue }
        if (c == " " || c == "\t" || c == "\n" || c == ";" || c == "&" || c == "|" || c == "<" || c == ">" || c == "(" || c == ")") break
        delim = delim c; i++
    }
    nh++; HD[nh] = delim; HQ[nh] = q; HS[nh] = strip
    return i
}
function heredocs(i,   h, line, t, found) {
    for (h = 1; h <= nh; h++) {
        found = 0
        while (i <= n) {
            line = ""
            while (i <= n && CH[i] != "\n") { line = line CH[i]; i++ }
            i++
            t = line
            if (HS[h]) sub(/^\t+/, "", t)
            if (t == HD[h]) { found = 1; break }
            if (!HQ[h] && (index(line, "$(") || index(line, "`"))) hexec = 1
        }
        if (!found) hunterm = 1
    }
    nh = 0
    return i
}
BEGIN {
    RS = "\036"; SQ = "\047"
    ARRCH = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_ ./:=,+@%-"
}
{ src = src $0 }
END {
    n = split(src, CH, "")
    nseg = 1; cur = 1; sp = 0; mode = "n"; w = ""; wf = ""; inw = 0; nextR = 0; nh = 0
    i = 1
    while (i <= n) {
        c = CH[i]
        if (c == "\\" && inb > 0) bbad = 1
        if (mode == "d") {
            if (c == "\\") {
                d = CH[i + 1]
                if (d == "\n") { i += 2; continue }
                if (d == "$" || d == "`" || d == "\"" || d == "\\") { w = w d; i += 2; continue }
                w = w c; i++; continue
            }
            if (c == "\"") { mode = "n"; i++; continue }
            if (c == "$") { i = dollar(i, 1); continue }
            if (c == "`") { i = btick(i, "D"); continue }
            w = w c; i++; continue
        }
        if (c == "\\") {
            d = CH[i + 1]
            if (d == "\n") { i += 2; continue }
            if (i < n) { w = w d; inw = 1 }
            i += 2; continue
        }
        if (c == SQ) {
            j = i + 1
            while (j <= n && CH[j] != SQ) {
                if (inb > 0 && CH[j] == "`") bbad = 1
                w = w CH[j]; j++
            }
            if (j > n) unq = 1
            inw = 1; i = j + 1; continue
        }
        if (c == "\"") { mode = "d"; inw = 1; i++; continue }
        if (c == "$") { i = dollar(i, 0); continue }
        if (c == "`") { i = btick(i, "U"); continue }
        if (c == " " || c == "\t" || c == "\r") { endword(); i++; continue }
        if (c == "\n") { endword(); endseg(); i = heredocs(i + 1); continue }
        if (c == "#" && !inw) {
            while (i <= n && CH[i] != "\n") {
                if (inb > 0 && CH[i] == "`") bbad = 1
                i++
            }
            continue
        }
        if (c == "&") {
            if (CH[i + 1] == ">") {
                endword(); i += 2
                if (CH[i] == ">") i++
                nextR = 1; continue
            }
            endword(); endseg(); i++
            if (CH[i] == "&") i++
            continue
        }
        if (c == ";") {
            endword(); endseg(); i++
            while (CH[i] == ";" || CH[i] == "&") i++
            continue
        }
        if (c == "|") {
            endword(); endseg(); i++
            if (CH[i] == "|" || CH[i] == "&") i++
            continue
        }
        if (c == "(") {
            # `name=(a b c)`: an array of plain words is one assignment, not a
            # subshell. One that names git or gh taints the call, since
            # `"${name[@]}"` can run it.
            if (inw && wf == "" && w ~ /^[A-Za-z_][A-Za-z0-9_]*[+]?=$/ && (NW[cur] == 0 || W[cur, 1] ~ /^(local|declare|typeset|readonly|export)$/)) {
                j = i + 1; body = ""
                while (j <= n && index(ARRCH, CH[j]) > 0) { body = body CH[j]; j++ }
                if (j <= n && CH[j] == ")") {
                    if (names(body)) vtaint = 1
                    w = w "(" body ")"; i = j + 1; continue
                }
            }
            if (CH[i + 1] == "(" && !inw) {
                j = arith(i + 2)
                if (j > 0) { endword(); endseg(); nstruct++; i = j; continue }
            }
            endword(); endseg(); sp++; ST[sp] = "p"; nstruct++; i++; continue
        }
        if (c == ")") {
            endword(); endseg()
            if (sp > 0) {
                if (ST[sp] == "p") sp--
                else if (ST[sp] == "s") pop()
            }
            i++; continue
        }
        if (c == "<" || c == ">") {
            if (inw && wf == "" && w ~ /^[0-9]+$/) { w = ""; inw = 0 } else endword()
            d = CH[i + 1]
            if (d == "(") { wf = wf "U"; inw = 1; w = w "\037"; push("s"); i += 2; continue }
            if (c == "<" && d == "<") {
                if (CH[i + 2] == "<") { nextR = 1; i += 3; continue }
                i = heredoc_decl(i + 2); continue
            }
            i++; nextR = 1
            while (i <= n && (CH[i] == ">" || CH[i] == "&" || CH[i] == "|")) {
                if (CH[i] == "&") nextR = 2
                i++
            }
            continue
        }
        if (c == "*" || c == "?" || c == "[") { w = w c; wf = wf "G"; inw = 1; i++; continue }
        if (c == "~" && !inw) { w = w c; wf = wf "G"; inw = 1; i++; continue }
        if (c == "{") {
            d = CH[i + 1]
            # A `{` word opens a group. zsh also takes one straight after a
            # test or a command (`if [[ -n $x ]] { gh pr merge 5 }`), so it
            # starts a new command wherever it stands.
            # bash reads the same word as an argument of the command before
            # it (`git commit -m { -n`), so the word also stays there, marked
            # Z, and pass 2 refuses a git or gh command that holds one.
            if (!inw && (i == n || d == " " || d == "\t" || d == "\n")) {
                if (NW[cur] > 0) { w = "{"; wf = "Z"; inw = 1; endword() }
                endseg(); w = "{"; inw = 1; endword(); i++; continue
            }
            # A brace list: `{a,b}` or `{1..3}` up to the closing brace. A
            # quoted or escaped blank inside it does not end the word.
            j = i + 1; body = ""; bq = ""
            while (j <= n) {
                e = CH[j]
                if (bq != "") {
                    if (e == bq) { bq = "" } else if (e == "\\" && bq == "\"") { j++ }
                    j++; continue
                }
                if (e == SQ || e == "\"") { bq = e; j++; continue }
                if (e == "\\") { j += 2; continue }
                # A substitution or `$'...'` is one item, blanks and all.
                if (e == "$" && (CH[j + 1] == "(" || CH[j + 1] == "{")) {
                    bo = CH[j + 1]; bc = (bo == "(" ? ")" : "}"); bd = 1; j += 2
                    while (j <= n && bd > 0) {
                        if (CH[j] == bo) bd++
                        else if (CH[j] == bc) bd--
                        j++
                    }
                    continue
                }
                if (e == "$" && CH[j + 1] == SQ) {
                    j += 2
                    while (j <= n && CH[j] != SQ) { if (CH[j] == "\\") j++; j++ }
                    j++; continue
                }
                if (e == "`") {
                    j++
                    while (j <= n && CH[j] != "`") j++
                    j++; continue
                }
                if (e == "}" || e == " " || e == "\t" || e == "\n") break
                body = body e; j++
            }
            if (j <= n && CH[j] == "}" && (index(body, ",") || index(body, ".."))) wf = wf "GB"
            w = w c; inw = 1; i++; continue
        }
        # A `}` or `]]` word ends a group or a test, and zsh runs a command
        # written straight after either one.
        if (c == "}" && !inw) {
            d = CH[i + 1]
            if (i == n || d == " " || d == "\t" || d == "\n" || d == ";" || d == "&" || d == "|" || d == ")") { w = "}"; wf = "Z"; inw = 1; endword(); endseg(); i++; continue }
        }
        if (c == "]" && !inw && CH[i + 1] == "]") {
            d = CH[i + 2]
            if (i + 1 == n || d == " " || d == "\t" || d == "\n" || d == ";" || d == "&" || d == "|" || d == ")") { w = "]]"; wf = "Z"; inw = 1; endword(); endseg(); i += 2; continue }
        }
        w = w c; inw = 1; i++
    }
    endword()
    st = ""
    if (mode == "d" || unq) st = st "q"
    if (sp > 0) st = st "k"
    if (hexec) st = st "h"
    if (complex) st = st "c"
    if (hunterm || nh > 0) st = st "u"
    if (abad) st = st "a"
    if (bbad) st = st "b"
    if (st == "") st = "ok"
    printf "S\035%s\035%d.%d\036", st, nstruct, vtaint
    for (s = 1; s <= nseg; s++)
        for (k = 1; k <= NW[s]; k++)
            printf "%d\035%s\035%s\036", s, (F[s, k] == "" ? "-" : F[s, k]), W[s, k]
}
'

R_SEG=() R_FL=() R_TXT=() LEX_STATUS=''
while IFS= read -r -d $'\036' rec; do
    a=${rec%%$'\035'*}
    rest=${rec#*$'\035'}
    b=${rest%%$'\035'*}
    c=${rest#*$'\035'}
    if [ "$a" = "S" ]; then
        LEX_STATUS=$b
        LEX_STRUCT=${c%%.*}
        LEX_VTAINT=${c#*.}
        continue
    fi
    R_SEG[${#R_SEG[@]}]=$a
    R_FL[${#R_FL[@]}]=$b
    R_TXT[${#R_TXT[@]}]=$c
done < <(printf '%s' "$COMMAND" | LC_ALL=C awk "$LEXER" 2>/dev/null)

case $LEX_STATUS in
    ok) ;;
    '') deny "the hook's lexer produced no result for a command that names git or gh, so the command cannot be checked. This is a hook defect; report it." ;;
    *h*) deny "a heredoc with an unquoted delimiter carries a command substitution (\`\$(...)\` or a backtick) in its body, which the shell would run and this hook cannot read. Quote the delimiter (<<'EOF') so the body is plain text." ;;
    *c*) deny "a \${...} expansion in this command carries a quote or a command substitution, which this hook cannot read past. Assign the value in an earlier Bash call or spell the command without the nested expansion." ;;
    *a*) deny "this command holds arithmetic the hook does not read: a \`\$(( ))\` or \`(( ))\` body that names git or gh, which one shell evaluates and another runs as a command, or the old \`\$[ ]\` form. Compute the value in an earlier Bash call." ;;
    *b*) deny "a backtick substitution in this command holds a backslash, or a quote, comment or heredoc that runs past its closing backtick, so the shell and this hook would read it differently. Use \`\$(...)\` in place of backticks." ;;
    *u*) deny "a heredoc in this command never reaches its closing delimiter, so the hook cannot tell where its body ends and the next command begins. Close the heredoc; if \`<<\` is a shift inside \`\$(( ))\`, keep the expression on one line with its closing parentheses." ;;
    *) deny "this command has a quote or substitution the hook could not close, so its git or gh use cannot be checked. Fix the quoting; if the command is valid, split it into smaller Bash calls." ;;
esac

# --- Segment access. ----------------------------------------------------------
TOTAL=${#R_SEG[@]}
SEG_FIRST=() SEG_LAST=()
prev=''
k=0
while [ "$k" -lt "$TOTAL" ]; do
    if [ "${R_SEG[$k]}" != "$prev" ]; then
        SEG_FIRST[${#SEG_FIRST[@]}]=$k
        [ -z "$prev" ] || SEG_LAST[${#SEG_LAST[@]}]=$((k - 1))
        prev=${R_SEG[$k]}
    fi
    k=$((k + 1))
done
[ "$TOTAL" -eq 0 ] || SEG_LAST[${#SEG_LAST[@]}]=$((TOTAL - 1))
NSEGS=${#SEG_FIRST[@]}

# load_segment <n>: sw/sf hold the words and flags, rw/rf the redirect targets.
load_segment() {
    local k=${SEG_FIRST[$1]} last=${SEG_LAST[$1]}
    sw=() sf=() rw=() rf=()
    while [ "$k" -le "$last" ]; do
        case ${R_FL[$k]} in
            *[RP]*)
                rw[${#rw[@]}]=${R_TXT[$k]}
                rf[${#rf[@]}]=${R_FL[$k]}
                ;;
            *)
                sw[${#sw[@]}]=${R_TXT[$k]}
                sf[${#sf[@]}]=${R_FL[$k]}
                ;;
        esac
        k=$((k + 1))
    done
}

is_dyn() { case $1 in *[DUX]*) return 0 ;; esac; return 1; }

RE_ASSIGN='^([A-Za-z_][A-Za-z0-9_]*)\+?=(.*)$'
RE_CMDVALUE='^([^[:space:]]*/)?([Gg][Ii][Tt]|[Gg][Hh])([[:space:]]|$)'
# Text that holds a git or gh command: the name as a word of its own, not a
# path component, with a blank or the end after it.
# A second form, the name behind a path with one of its own subcommands or a
# flag after it (`/opt/homebrew/bin/gh pr merge 5`), is added below, once the
# subcommand lists exist.
RE_CODE_MENTION='((^|[^[:alnum:]_./-])([Gg][Ii][Tt]|[Gg][Hh])([[:space:]]|$))'

# strip_prefix: skips keywords, assignment prefixes and wrapper commands.
# Sets CMD_IDX, CMD (basename, empty when absent or dynamic), CMD_DYN, and
# AS_NAME/AS_VAL/AS_FL for the assignments it passed.
# RUNNERS: commands that run their arguments as a command. Behind one of
# these, or behind a wrapper stripped below, a `git` or `gh` word followed by
# one of its own subcommands is read as the command that runs.
RUNNERS=' op doppler repeat direnv watch flock script parallel chronic ts aws-vault dotenv mise asdf nix nix-shell devbox '
GIT_BUILTINS=' add am annotate apply archive backfill bisect blame branch bugreport bundle cat-file check-attr check-ignore check-mailmap check-ref-format checkout checkout-index cherry cherry-pick citool clean clone column commit commit-graph commit-tree config count-objects daemon describe diagnose diff diff-files diff-index diff-pairs diff-tree difftool fast-export fast-import fetch fetch-pack filter-branch fmt-merge-msg for-each-ref for-each-repo format-patch fsck fsck-objects gc get-tar-commit-id grep gui hash-object help history hook http-backend http-fetch imap-send index-pack init init-db interpret-trailers last-modified lfs log ls-files ls-remote ls-tree mailinfo mailsplit maintenance merge merge-base merge-file merge-index merge-octopus merge-one-file merge-ours merge-recursive merge-recursive-ours merge-recursive-theirs merge-resolve merge-subtree merge-tree mergetool mktag mktree multi-pack-index mv name-rev notes p4 pack-objects pack-redundant pack-refs patch-id pickaxe prune prune-packed pull push quiltimport range-diff read-tree rebase receive-pack reflog refs remote repack replace replay repo request-pull rerere reset restore rev-list rev-parse revert rm send-email shell shortlog show show-branch show-index show-ref sparse-checkout stage stash status stripspace submodule subtree switch symbolic-ref tag unpack-file unpack-objects update-index update-ref update-server-info upload-archive upload-pack var verify-commit verify-pack verify-tag version whatchanged worktree write-tree '
GH_COMMANDS=' actions agent agent-task agent-tasks agents alias api at attestation auth browse cache co codespace completion config copilot cs discussion extension extensions ext gist gpg-key help issue label licenses org pr preview project reference release repo rs ruleset run search secret skill ssh-key status variable version workflow '
# GH_LEAVES: gh commands that take arguments, not a subcommand.
GH_LEAVES='actions api browse co completion copilot help licenses reference status version'
# TEXT_CMDS: commands whose arguments are text, names or paths, and the
# commands pass 2 judges itself. Behind any other command a `git` or `gh`
# word followed by one of its own subcommands is read as the command that
# runs (`ssh host gh ...`, `fd -x gh ...`, `docker exec c git ...`).
TEXT_CMDS=' : [ [[ . alias awk basename bash bat case cat cd chmod cmp column cp cut dash date declare diff dirname du echo eval exit export false file find fish for grep hash head jq ksh less ln local ls man mkdir more mv popd printf pushd pwd read readonly realpath return rg rm rmdir sed select set sh shift sleep sort source stat tail tee test tldr touch tr trap true type typeset uniq unset wc whence where which yq zsh '
# WRAPPERS: commands strip_prefix reads through. FWD_RUNNERS: programs that
# run text, looked for behind a wrapper flag's value. GIT_EMB: the git words
# that mark an embedded git command, the builtins plus the verbs check_git
# refuses by name.
WRAPPERS='command builtin exec nohup nice time timeout gtimeout noglob nocorrect stdbuf caffeinate ionice setsid unbuffer env sudo doas xargs arch'
FWD_RUNNERS='sh bash zsh dash ksh fish watch find parallel script flock'
GIT_EMB="${GIT_BUILTINS}send-pack http-push credential credential-cache credential-store credential-osxkeychain "
ALT_GIT=${GIT_EMB# }
ALT_GIT=${ALT_GIT% }
ALT_GH=${GH_COMMANDS# }
ALT_GH=${ALT_GH% }
# RE_AFTER: what marks a command after a path-qualified name besides one of
# its subcommands: a flag, an expansion (`gh \$sub`, `git "\$@"`) or the
# mark the lexer leaves for one.
RE_AFTER="[-\$\"'"$'\037'"]"
RE_CODE_MENTION="$RE_CODE_MENTION|((^|[[:space:];&|(])[^[:space:];&|()]*/(([Gg][Ii][Tt])[[:space:]]+(${RE_AFTER}|(${ALT_GIT// /|})([[:space:]]|\$))|([Gg][Hh])[[:space:]]+(${RE_AFTER}|(${ALT_GH// /|})([[:space:]]|\$))))"
# A word that starts with an expansion and whose literal rest spells a
# negated flag or only dashes: `"\$d"-no-verify`, `"\$a-\$b"`.
RE_NEGLIT='^--?(n|no(-.*)?)?$'
# ENV_RUNNERS: runners that hand the command an environment of their own
# making, a token included.
ENV_RUNNERS=' op doppler aws-vault dotenv direnv '
# lc <word>: LC_OUT is the word in lower case. The volume this runs on folds
# case, so `GH` and `Git` run the same programs as `gh` and `git`.
lc() {
    case $1 in
        *[A-Z]*) LC_OUT=$(printf '%s' "$1" | LC_ALL=C tr 'A-Z' 'a-z') ;;
        *) LC_OUT=$1 ;;
    esac
}
# later_sub <from> <list>: a literal word from <from> on is in <list>. A name
# with a flag after it (`tree ~/.config/gh -L 2`, `brew info gh --json`) is
# the command only when one of its own subcommands follows.
later_sub() {
    local j=$1 n=${#sw[@]}
    while [ "$j" -lt "$n" ]; do
        if ! is_dyn "${sf[$j]}"; then
            case $2 in *" ${sw[$j]} "*) return 0 ;; esac
        fi
        j=$((j + 1))
    done
    return 1
}
# path_cmd <i>: word <i> is a path to git or gh with one of its own
# subcommands, or an expansion, after it (`-exec /opt/homebrew/bin/gh pr ...`).
path_cmd() {
    local t nx
    is_dyn "${sf[$1]:--}" && return 1
    t=${sw[$1]:-}
    case $t in */*) ;; *) return 1 ;; esac
    lc "${t##*/}"
    nx=${sw[$(($1 + 1))]:-}
    [ -n "$nx" ] || return 1
    if is_dyn "${sf[$(($1 + 1))]:--}"; then
        case $LC_OUT in git | gh) return 0 ;; esac
        return 1
    fi
    case $LC_OUT in
        gh) case $GH_COMMANDS in *" $nx "*) return 0 ;; esac ;;
        git) case $GIT_EMB in *" $nx "*) return 0 ;; esac ;;
    esac
    return 1
}
embedded_cmd() {
    local i=$1 n=${#sw[@]} t nx
    while [ "$i" -lt "$n" ]; do
        if ! is_dyn "${sf[$i]}"; then
            t=${sw[$i]}
            t=${t#=}
            t=${t##*/}
            # `nix run nixpkgs#gh -- pr merge 5`.
            t=${t##*#}
            case $t in
                [Gg][Ii][Tt]) t=git ;;
                [Gg][Hh]) t=gh ;;
            esac
            nx=${sw[$((i + 1))]:-}
            # An expansion after the name could be any subcommand.
            if is_dyn "${sf[$((i + 1))]:--}"; then
                case $t in
                    gh) nx=pr ;;
                    git) nx=push ;;
                esac
            fi
            case $t in
                gh)
                    case $nx in -*) later_sub $((i + 2)) "$GH_COMMANDS" && nx=pr ;; esac
                    case $GH_COMMANDS in *" $nx "*)
                        CMD_IDX=$i CMD=gh
                        return 0
                        ;;
                    esac
                    ;;
                git)
                    case $nx in -*) later_sub $((i + 2)) "$GIT_EMB" && nx=push ;; esac
                    case $GIT_EMB in *" $nx "*)
                        CMD_IDX=$i CMD=git
                        return 0
                        ;;
                    esac
                    ;;
            esac
        fi
        i=$((i + 1))
    done
    return 1
}

strip_prefix() {
    local n=${#sw[@]} t f wrapped=0 base
    CMD_IDX=0 CMD='' CMD_DYN=0 XARGS_PAD=0 RUNNER='' ENV_SPLIT=0 WRAPPED=0
    AS_NAME=() AS_VAL=() AS_FL=()
    while [ "$CMD_IDX" -lt "$n" ]; do
        t=${sw[$CMD_IDX]}
        f=${sf[$CMD_IDX]}
        if [[ $t =~ $RE_ASSIGN ]]; then
            AS_NAME[${#AS_NAME[@]}]=${BASH_REMATCH[1]}
            AS_VAL[${#AS_VAL[@]}]=${BASH_REMATCH[2]}
            AS_FL[${#AS_FL[@]}]=$f
            CMD_IDX=$((CMD_IDX + 1))
            continue
        fi
        if is_dyn "$f"; then
            # A path built from an expansion that ends in the literal name
            # (`"$HOMEBREW_PREFIX/bin/gh"`) is that command. Any other
            # expansion whose last component spells the name
            # (`$commands[gh]`) is CMD_DYN 2, which pass 2 refuses.
            base=${t##*/}
            case $base in
                [Gg][Ii][Tt]) [ "$base" = "$t" ] || CMD=git ;;
                [Gg][Hh]) [ "$base" = "$t" ] || CMD=gh ;;
            esac
            [ -z "$CMD" ] || return
            # A git or gh command written out behind the expansion
            # (`env "$v" gh pr merge 5`, `$retry gh pr merge 5`) is read as
            # the command that runs, as behind any unknown command.
            if embedded_cmd $((CMD_IDX + 1)); then
                WRAPPED=1
                return
            fi
            CMD_DYN=1
            case $base in
                *[.-]*) ;;
                *) [[ $base =~ $RE_MENTION ]] && CMD_DYN=2 ;;
            esac
            return
        fi
        # A brace list or glob in the command word that spells the name
        # (`{gh,} pr merge 5`) is refused the same way.
        case $f in
            *G*)
                base=${t##*/}
                case $base in
                    [Gg][Ii][Tt] | [Gg][Hh]) ;;
                    *[{,]* | *[!.-]*)
                        case $base in
                            *[{,]*) ;;
                            *[.-]*) base='' ;;
                        esac
                        if [[ $base =~ $RE_MENTION ]]; then
                            CMD_DYN=2
                            return
                        fi
                        ;;
                esac
                ;;
        esac
        lc "$t"
        t=$LC_OUT
        case $t in
            if | then | else | elif | fi | do | done | while | until | '!' | '{' | '}' | coproc)
                CMD_IDX=$((CMD_IDX + 1))
                continue
                ;;
            function)
                CMD_IDX=$((CMD_IDX + 2))
                continue
                ;;
            command | builtin | exec | nohup | nice | time | timeout | gtimeout | noglob | nocorrect | stdbuf | caffeinate | ionice | setsid | unbuffer | env | sudo | doas | xargs | arch | -)
                # `command -v git gh jq` looks the names up and runs nothing.
                if [ "$t" = command ] && ! is_dyn "${sf[$((CMD_IDX + 1))]:--}"; then
                    case ${sw[$((CMD_IDX + 1))]:-} in
                        -v | -V | -pv | -pV)
                            CMD=command
                            return
                            ;;
                    esac
                fi
                wrapped=1 WRAPPED=1
                # xargs appends words this hook never sees: stand one unquoted
                # expansion in for them, so every check reads the command as
                # ending in unknown text.
                if [ "$t" = xargs ] && [ "$XARGS_PAD" = 0 ]; then
                    XARGS_PAD=1
                    sw[${#sw[@]}]=$'\037'
                    sf[${#sf[@]}]=U
                fi
                CMD_IDX=$((CMD_IDX + 1))
                while [ "$CMD_IDX" -lt "$n" ]; do
                    t=${sw[$CMD_IDX]}
                    is_dyn "${sf[$CMD_IDX]}" && break
                    case $t in
                        -S* | --split-string* | -[A-Za-z]*S*)
                            # `env -S 'gh pr merge 5'` runs its argument as a
                            # command line.
                            ENV_SPLIT=1
                            CMD_IDX=$((CMD_IDX + 1))
                            ;;
                        -* | [0-9]*) CMD_IDX=$((CMD_IDX + 1)) ;;
                        *)
                            # `env NAME=value command`: the assignment counts
                            # as a prefix of the command that runs.
                            [[ $t =~ $RE_ASSIGN ]] || break
                            AS_NAME[${#AS_NAME[@]}]=${BASH_REMATCH[1]}
                            AS_VAL[${#AS_VAL[@]}]=${BASH_REMATCH[2]}
                            AS_FL[${#AS_FL[@]}]=${sf[$CMD_IDX]}
                            CMD_IDX=$((CMD_IDX + 1))
                            ;;
                    esac
                done
                continue
                ;;
        esac
        break
    done
    [ "$CMD_IDX" -lt "$n" ] || return
    CMD=${sw[$CMD_IDX]}
    CMD=${CMD#=}
    CMD=${CMD##*/}
    lc "$CMD"
    CMD=$LC_OUT
    case $CMD in git | gh) return ;; esac
    # A wrapper flag that takes a value (`env -u NAME`, `timeout -s INT`,
    # `xargs -I {}`) leaves CMD on the value, and a runner or any command
    # that is not a text command hides the command behind its own words.
    if [ "$wrapped" = 1 ]; then
        embedded_cmd "$CMD_IDX" && return
        # No git or gh word. When the word under CMD follows a flag it may be
        # that flag's value (`xargs -I {} sh -c 'gh pr merge {}'`,
        # `timeout -s KILL 60 bash -c ...`), with the command after it. Read
        # on past flags, their values, numbers, assignments and further
        # wrappers: a program that runs text is the command, and an
        # expansion there is a command word this hook cannot read. Any other
        # word ends the reading, so `time go build .` is not touched.
        case $TEXT_CMDS in *" $CMD "*) return ;; esac
        [ "$CMD_IDX" -gt 0 ] || return
        case ${sw[$((CMD_IDX - 1))]} in -*) ;; *) return ;; esac
        t=$((CMD_IDX + 1))
        while [ "$t" -lt "$n" ]; do
            if is_dyn "${sf[$t]}"; then
                CMD='' CMD_DYN=1
                return
            fi
            base=${sw[$t]##*/}
            lc "$base"
            base=$LC_OUT
            case " $FWD_RUNNERS " in
                *" $base "*)
                    CMD=$base CMD_IDX=$t
                    return
                    ;;
            esac
            case " $WRAPPERS " in
                *" $base "*) ;;
                *)
                    case $base in
                        -*)
                            # The word after a flag is its value unless it is
                            # itself a flag, a wrapper or a runner.
                            if is_dyn "${sf[$((t + 1))]:--}"; then
                                CMD='' CMD_DYN=1
                                return
                            fi
                            f=${sw[$((t + 1))]:-}
                            f=${f##*/}
                            lc "$f"
                            case " $FWD_RUNNERS $WRAPPERS " in
                                *" $LC_OUT "*) ;;
                                *) case $f in -*) ;; *) t=$((t + 1)) ;; esac ;;
                            esac
                            ;;
                        [0-9]*) ;;
                        *) [[ $base =~ $RE_ASSIGN ]] || return ;;
                    esac
                    ;;
            esac
            t=$((t + 1))
        done
    else
        case $RUNNERS in
            *" $CMD "*)
                base=$CMD
                if embedded_cmd $((CMD_IDX + 1)); then RUNNER=$base; fi
                ;;
            *)
                case $TEXT_CMDS in
                    *" $CMD "*) ;;
                    *) if embedded_cmd $((CMD_IDX + 1)); then WRAPPED=1; fi ;;
                esac
                ;;
        esac
    fi
}

lower() { printf '%s' "$1" | LC_ALL=C tr 'A-Z' 'a-z'; }

# plain_dir_word <word> <flags>: the word names a directory as written. A
# word the shell expands (`~`, `~-`, `~name`, `p*`, a brace list) is not
# followed: the call can change `HOME` and the directory stack.
plain_dir_word() {
    case $2 in
        *G*) return 1 ;;
    esac
    case $1 in
        '~'*) return 1 ;;
    esac
    return 0
}

gitq() { GIT_OPTIONAL_LOCKS=0 GIT_TERMINAL_PROMPT=0 git --no-pager "$@"; }

# `-P`: a `..` after a symbolic link resolves as the kernel, and so git,
# resolves it, not textually.
physical() { (cd -P -- "$1" 2>/dev/null && pwd -P); }

# fd_dup <redirect target>: the target of `>&` or `<&` is a descriptor
# number or `-`. Any other word after `>&` names a file.
fd_dup() { [[ $1 =~ ^([0-9]+|-)$ ]]; }

# common_of <dir>: the physical path of the git common directory, or nothing.
common_of() {
    local c
    c=$(gitq -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
    [ -n "$c" ] || return 1
    physical "$c"
}

# no_repository <dir>: git itself reports the directory as outside every
# repository. Any other failure (no git on PATH, a repository this git cannot
# read) proves nothing.
no_repository() {
    local err rc
    err=$(LC_ALL=C gitq -C "$1" rev-parse --git-dir 2>&1 >/dev/null)
    rc=$?
    [ "$rc" = 128 ] || return 1
    case $err in
        'fatal: not a git repository (or any'*) return 0 ;;
    esac
    return 1
}

# PROJECT_COMMON is the project's git common directory, empty when the session
# has no project repository. PROJECT_KNOWN is 0 when that could not be told.
PROJECT_COMMON_DONE=0 PROJECT_COMMON='' PROJECT_KNOWN=1
project_common() {
    if [ "$PROJECT_COMMON_DONE" = 0 ]; then
        PROJECT_COMMON_DONE=1
        if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
            PROJECT_COMMON=$(common_of "$CLAUDE_PROJECT_DIR") || {
                PROJECT_COMMON=''
                no_repository "$CLAUDE_PROJECT_DIR" || PROJECT_KNOWN=0
            }
        fi
    fi
}

# --- Pass 1: what the whole call does to directory and environment. -----------
ENV_TAINT='' VAR_TAINT=0 VAR_TAINT_CMD=0 PIN=0
ENV_TAINT_GIT='' ENV_TAINT_GH='' ENV_HOOKMGR='' ENV_GDIR=0 CODE_ENV='' ALLEXPORT=0 BARE_NAME=() BARE_VAL=()
[ "${LEX_VTAINT:-0}" = 0 ] || VAR_TAINT=1
RE_ENVNAME='^(GH_|GITHUB_|GIT_|SSH_)'
# env_export <name> <value>: records a variable the call exports. ENV_TAINT is
# the first one that could matter to git or gh; ENV_TAINT_GIT and
# ENV_TAINT_GH are the ones the loose git checks and the gh checks refuse,
# kept apart so a harmless name exported later does not hide them.
env_export() {
    case $1 in
        *EDITOR* | *PAGER* | VISUAL | BROWSER | GIT_* | GH_*)
            [[ $2 =~ $RE_CODE_MENTION ]] && CODE_ENV=$1
            ;;
    esac
    case $1 in HUSKY | HUSKY_SKIP_HOOKS | LEFTHOOK) ENV_HOOKMGR=$1 ;; esac
    [[ $1 =~ $RE_ENVNAME ]] || return 0
    case $1 in
        GH_PROMPT_DISABLED | GH_NO_UPDATE_NOTIFIER | GH_NO_EXTENSION_UPDATE_NOTIFIER | GH_FORCE_TTY | GH_SPINNER_DISABLED | GIT_TERMINAL_PROMPT | GIT_OPTIONAL_LOCKS) return 0 ;;
        GH_PAGER | GIT_PAGER)
            case $2 in '' | cat) return 0 ;; esac
            ;;
    esac
    [ -n "$ENV_TAINT" ] || ENV_TAINT=$1
    case $1 in
        GIT_CONFIG* | GIT_SSH* | GIT_ASKPASS | GIT_PROXY_COMMAND | GIT_EXEC_PATH | GIT_ALLOW_PROTOCOL | SSH_ASKPASS | SSH_AUTH_SOCK) ENV_TAINT_GIT=$1 ;;
        GIT_DIR | GIT_WORK_TREE | GIT_COMMON_DIR | GIT_NAMESPACE) ENV_GDIR=1 ;;
        GH_* | GITHUB_*) ENV_TAINT_GH=$1 ;;
    esac
    return 0
}
# OUT_NAMES: the first word of every `sandbox.excludedCommands` entry. A call
# that runs any other literal command stays sandboxed as a whole.
OUT_NAMES=' aws docker doppler gh git kubectl terraform vorpal '
s=0
while [ "$s" -lt "$NSEGS" ]; do
    load_segment "$s"
    strip_prefix
    if [ "$CMD_DYN" = 0 ] && [ -n "$CMD" ]; then
        case $OUT_NAMES in
            *" $CMD "*) ;;
            *) PIN=1 ;;
        esac
    fi
    i=0
    while [ "$i" -lt "${#AS_NAME[@]}" ]; do
        [[ ${AS_VAL[$i]} =~ $RE_CMDVALUE ]] && VAR_TAINT=1 VAR_TAINT_CMD=1
        # A variable that moves the repository git reads, set anywhere in
        # the call, can be exported by a later `declare -x` or `set -a`.
        case ${AS_NAME[$i]} in
            GIT_DIR | GIT_WORK_TREE | GIT_COMMON_DIR | GIT_NAMESPACE | GIT_CEILING_DIRECTORIES | GIT_DISCOVERY_ACROSS_FILESYSTEM) ENV_GDIR=1 ;;
        esac
        # An assignment with no command after it is exported when the call
        # turns `set -a` on; kept until the whole call is read.
        if [ "$CMD_IDX" -ge "${#sw[@]}" ]; then
            BARE_NAME[${#BARE_NAME[@]}]=${AS_NAME[$i]}
            BARE_VAL[${#BARE_VAL[@]}]=${AS_VAL[$i]}
        fi
        i=$((i + 1))
    done
    # A git or gh name that reaches a command word through a lookup or a loop
    # variable (`$(which gh) ...`, `for g in gh; do $g ...`) taints the call
    # the same way a variable holding the command does.
    case ${sw[0]:-} in
        which | whence | where | type | command | hash | for | select)
            i=1
            while [ "$i" -lt "${#sw[@]}" ]; do
                t=${sw[$i]##*/}
                case $t in git | gh) VAR_TAINT=1 ;; esac
                i=$((i + 1))
            done
            ;;
    esac
    case $CMD in
        export | declare | typeset | readonly | local | alias)
            i=$((CMD_IDX + 1))
            while [ "$i" -lt "${#sw[@]}" ]; do
                if [[ ${sw[$i]} =~ $RE_ASSIGN ]]; then
                    name=${BASH_REMATCH[1]}
                    val=${BASH_REMATCH[2]}
                    [[ $val =~ $RE_CMDVALUE ]] && VAR_TAINT=1 VAR_TAINT_CMD=1
                    [ "$CMD" = alias ] || env_export "$name" "$val"
                elif is_dyn "${sf[$i]}"; then
                    # A name the shell computes (`export ${p}DIR=...`) can be
                    # one that moves the repository git reads.
                    ENV_GDIR=1
                elif [ "$CMD" = export ] || [ "$CMD" = declare ] || [ "$CMD" = typeset ]; then
                    env_export "${sw[$i]}" $'\037'
                fi
                i=$((i + 1))
            done
            ;;
        # Commands that set a variable under a computed name, or run text
        # that can: the repository git reads is then unknown.
        read | mapfile | readarray | getopts | printf)
            i=$((CMD_IDX + 1))
            while [ "$i" -lt "${#sw[@]}" ]; do
                if is_dyn "${sf[$i]}"; then
                    # `printf -v "$n"`, and the name attached: `-v"$n"`.
                    if [ "$CMD" != printf ] || [ "${sw[$((i - 1))]}" = -v ]; then
                        ENV_GDIR=1
                    else
                        case ${sw[$i]} in -v*) ENV_GDIR=1 ;; esac
                    fi
                fi
                i=$((i + 1))
            done
            ;;
        eval | source | . | trap) ENV_GDIR=1 ;;
        set)
            i=$((CMD_IDX + 1))
            while [ "$i" -lt "${#sw[@]}" ]; do
                case ${sw[$i]} in
                    allexport) ALLEXPORT=1 ;;
                    --*) ;;
                    -*a*) ALLEXPORT=1 ;;
                esac
                is_dyn "${sf[$i]}" && ALLEXPORT=1
                i=$((i + 1))
            done
            ;;
    esac
    s=$((s + 1))
done
if [ "$ALLEXPORT" = 1 ]; then
    i=0
    while [ "$i" -lt "${#BARE_NAME[@]}" ]; do
        env_export "${BARE_NAME[$i]}" "${BARE_VAL[$i]}"
        i=$((i + 1))
    done
fi

# SOLE: the call is one simple command with no subshell or substitution, the
# only form a push is accepted in.
# MAYOUT: no command in the call pins it inside the sandbox, so the harness
# may run all of it unsandboxed. Every SOLE git or gh call is MAYOUT. A
# command inside a substitution or a subshell is not known to pin the call,
# so a call with either counts as one that may leave.
SOLE=0
[ "$NSEGS" -eq 1 ] && [ "${LEX_STRUCT:-1}" = 0 ] && SOLE=1
MAYOUT=1
[ "$PIN" = 1 ] && [ "${LEX_STRUCT:-1}" = 0 ] && MAYOUT=0

# --- Target classification for the loose git checks. --------------------------
# TARGET is `scratch` for a directory that is not in a git repository, or is in
# one under a temp root that is not the project's; `real` for everything else,
# including every directory this hook cannot resolve.
join_path() {
    case $2 in
        /*) printf '%s' "$2" ;;
        '~') printf '%s' "$HOME" ;;
        '~/'*) printf '%s/%s' "$HOME" "${2#\~/}" ;;
        *) printf '%s/%s' "$1" "$2" ;;
    esac
}

# classify_dir <physical dir>: sets TARGET to scratch for a directory git
# itself reports as outside every repository, or a repository other than the
# project under a temp root. Any other failure of the lookup (no git on PATH,
# a repository this git cannot read) leaves TARGET as it was.
classify_dir() {
    local common part
    common=$(common_of "$1") || {
        ! no_repository "$1" || TARGET=scratch
        return 0
    }
    project_common
    [ "$PROJECT_KNOWN" = 1 ] || return 0
    [ -z "$PROJECT_COMMON" ] || [ "$common" != "$PROJECT_COMMON" ] || return 0
    # The checkout and the repository behind it both lie under a temp root:
    # a worktree there of a repository kept elsewhere is not scratch.
    case $1/ in
        /tmp/* | /private/tmp/* | /var/folders/* | /private/var/folders/*) ;;
        *) return 0 ;;
    esac
    case $common/ in
        /tmp/* | /private/tmp/* | /var/folders/* | /private/var/folders/*) ;;
        *) return 0 ;;
    esac
    # A git directory whose parts are links (the `git-new-workdir` layout)
    # writes its config, refs and hooks into another repository.
    for part in config HEAD refs refs/heads objects packed-refs hooks info; do
        [ ! -L "$common/$part" ] || return 0
    done
    TARGET=scratch
    return 0
}

# walk_word <word>: applies one `git -C` word to WP, the textual path of the
# directory the git command runs in. It fails on a `..` that would pop a
# symbolic link or a missing directory, where a textual reading and the
# kernel's would part.
WP='' WDEPTH=0
walk_word() {
    local rest=$1 comp
    case $rest in
        /*) WP='' WDEPTH=0 ;;
    esac
    while [ -n "$rest" ]; do
        comp=${rest%%/*}
        case $rest in
            */*) rest=${rest#*/} ;;
            *) rest='' ;;
        esac
        case $comp in
            '' | .) ;;
            ..)
                [ "$WDEPTH" -gt 0 ] || continue
                [ -d "$WP" ] && [ ! -L "$WP" ] || return 1
                WP=${WP%/*}
                WDEPTH=$((WDEPTH - 1))
                ;;
            *)
                WP=$WP/$comp
                WDEPTH=$((WDEPTH + 1))
                ;;
        esac
    done
    return 0
}

# The directory the git command runs in, known only when the git command
# names it itself: its first `-C` word is an absolute path, which git obeys
# whatever the shell did before. The shell's directory is never followed: a
# `cd` can fail, be skipped, be redefined or run in another shell, and a
# wrapper, a function or a sourced file can move the shell with no `cd` word.
# The path is read as the filesystem stands when the call starts, so every
# directory on the way must exist; one the call itself makes is not followed.
RE_GIT_REPO_ENV='GIT_(DIR|WORK_TREE|COMMON_DIR|NAMESPACE|INDEX_FILE|OBJECT_DIRECTORY|ALTERNATE_OBJECT_DIRECTORIES|CEILING_DIRECTORIES|DISCOVERY_ACROSS_FILESYSTEM)'
classify_target() {
    local d k w phys t
    TARGET=real TARGET_DIR=''
    [ "$GDIR" = 0 ] || return 0
    # A variable that moves the repository git reads, named anywhere in the
    # call: a prefix, `export`, `declare -x`, `read`, `printf -v`.
    [[ ! $COMMAND =~ $RE_GIT_REPO_ENV ]] || return 0
    # Git is called by name, with no wrapper in front: `xargs` appends and
    # replaces words, and `env` can set a variable under a computed name.
    [ "${WRAPPED:-0}" = 0 ] && [ -z "$RUNNER" ] || return 0
    case ${GIT_C[0]:-} in
        /*) ;;
        *) return 0 ;;
    esac
    WP='' WDEPTH=0
    k=0
    while [ "$k" -lt "${#GIT_C[@]}" ]; do
        t=${GIT_CF[$k]}
        w=${GIT_C[$k]}
        k=$((k + 1))
        is_dyn "$t" && return 0
        plain_dir_word "$w" "$t" || return 0
        walk_word "$w" || return 0
        d=${WP:-/}
        [ -d "$d" ] && [ -x "$d" ] || return 0
    done
    d=${WP:-/}
    [ -d "$d" ] || return 0
    phys=$(physical "$d") || return 0
    TARGET_DIR=$phys
    classify_dir "$phys"
}

loose_deny() {
    classify_target
    [ "$TARGET" = real ] || return 0
    deny "$1 This overrides a git permission that exists outside the sandbox. A throwaway repository under a temp root is exempt when it exists before the call and the git command names it as \`git -C <absolute dir>\`. A \`cd\` in the call is not followed. $OPERATOR"
}

# --- Repository trust for a git that runs outside the sandbox. ----------------
RE_CFG_OK='^(core\.(repositoryformatversion|filemode|bare|logallrefupdates|ignorecase|precomposeunicode|symlinks|autocrlf|eol|quotepath|untrackedcache|commitgraph|multipackindex|splitindex|abbrev)|extensions\.(objectformat|refstorage|relativeworktrees)|remote\.[A-Za-z0-9._-]+\.(url|fetch|gh-resolved|tagopt|prune)|branch\..+\.(remote|merge|rebase|description|pushremote|gh-merge-base|vscode-merge-base|github-pr-owner-number)|user\.(name|email)|init\.defaultbranch|gc\.(auto|autopacklimit|autodetach|bigpackthreshold|writecommitgraph|logexpiry|packrefs|pruneexpire|worktreepruneexpire|reflogexpire|reflogexpireunreachable|aggressivedepth|aggressivewindow|cruftpacks|maxcruftsize|rerereresolved|rerereunresolved)|maintenance\.[a-z]+|index\.[a-z]+|feature\.[a-z]+|pack\.[a-z]+|fetch\.(prune|prunetags|fsckobjects|parallel)|advice\.[a-z]+|color\.[a-z.]+|rerere\.[a-z]+|status\.[a-z]+|diff\.(renames|algorithm|colormoved)|merge\.(conflictstyle|ff)|pull\.(rebase|ff)|rebase\.(autostash|autosquash|updaterefs)|commit\.(verbose|gpgsign)|tag\.gpgsign|worktree\.[a-z]+|submodule\.active|submodule\..+\.(url|active))$'

# hooks_clean <what> <git dir>: no hook file but the samples git ships.
hooks_clean() {
    local h
    # Git runs a hook by path, which needs only search permission on the
    # directory, so a directory this hook cannot list is refused.
    if [ -e "$2/hooks" ] || [ -L "$2/hooks" ]; then
        [ -d "$2/hooks" ] && [ -r "$2/hooks" ] && [ -x "$2/hooks" ] && ls -A "$2/hooks" >/dev/null 2>&1 || deny "$1 blocked: $2/hooks cannot be listed, so the hooks git would run outside the sandbox cannot be read. $OPERATOR"
    fi
    for h in "$2"/hooks/*; do
        [ -e "$h" ] || continue
        case $h in
            *.sample) ;;
            *) deny "$1 blocked: \`${h##*/}\` exists in $2/hooks, and git would run it outside the sandbox. $OPERATOR" ;;
        esac
    done
}

# legacy_clean <what> <git dir>: git still reads a remote defined by a file
# under `remotes` or `branches`, which a config check never sees. A
# dot-named file counts: git accepts `.x` as a remote name. A directory
# that cannot be listed is refused, since git opens such a file by name.
legacy_clean() {
    local h
    for h in remotes branches; do
        [ -e "$2/$h" ] || [ -L "$2/$h" ] || continue
        [ -d "$2/$h" ] && [ ! -L "$2/$h" ] && [ -r "$2/$h" ] && [ -x "$2/$h" ] && ls -A "$2/$h" >/dev/null 2>&1 && [ -z "$(ls -A "$2/$h" 2>/dev/null)" ] || deny "$1 blocked: the git directory $2 holds a legacy remote definition under \`$h\`, which this hook does not read. $OPERATOR"
    done
}

# repo_trust <what> [all]: `all` refuses every hook file, for a verb that
# checks out, merges or commits; the default refuses the hooks a push or a
# fetch runs.
TRUST_DONE=0 REPO_COMMON=''
repo_trust() {
    local what=$1 hooks=${2:-transport} key hp h v
    [ "$TRUST_DONE" != all ] && [ "$TRUST_DONE" != "$hooks" ] || return 0
    [ -n "$HOOK_CWD" ] && [ -d "$HOOK_CWD" ] || deny "$what blocked: the hook input names no working directory, so the repository cannot be checked."
    project_common
    [ -n "$PROJECT_COMMON" ] || deny "$what blocked: this session's project directory is not a git repository, so there is no repository this hook can vouch for. $OPERATOR"
    REPO_COMMON=$(common_of "$HOOK_CWD") || deny "$what blocked: the working directory is not inside a git repository."
    [ "$REPO_COMMON" = "$PROJECT_COMMON" ] || deny "$what blocked: the working directory belongs to a different repository than this session's project. Outside the sandbox git runs that repository's config and hooks, which this hook does not vouch for. $OPERATOR"
    while IFS= read -r key; do
        [ -n "$key" ] || continue
        [[ $key =~ $RE_CFG_OK ]] || deny "$what blocked: the repository's local git config sets \`$key\`, which is not on this hook's allowlist of keys that cannot reroute, re-authenticate or run a program. Outside the sandbox git would honor it. $OPERATOR"
        if [[ $key =~ ^submodule\..+\.url$ ]]; then
            while IFS= read -r v; do
                parse_github_url "$v" || deny "$what blocked: the repository's local git config points \`$key\` at \`$v\`, which is not a github.com repository URL this hook recognizes. $OPERATOR"
            done < <(gitq -C "$HOOK_CWD" config --local --get-all "$key" 2>/dev/null)
        fi
    done < <(gitq -C "$HOOK_CWD" config --local --name-only --list 2>/dev/null)
    hp=$(gitq -C "$HOOK_CWD" config --get core.hookspath 2>/dev/null)
    [ -z "$hp" ] || deny "$what blocked: core.hooksPath is set ($hp), so git would run hooks from a directory this hook does not inspect. $OPERATOR"
    legacy_clean "$what" "$REPO_COMMON"
    if [ "$hooks" = all ]; then
        hooks_clean "$what" "$REPO_COMMON"
    else
        for h in pre-push reference-transaction post-checkout post-merge post-rewrite pre-auto-gc; do
            [ ! -e "$REPO_COMMON/hooks/$h" ] || deny "$what blocked: the repository has a \`$h\` hook, which git would run outside the sandbox. $OPERATOR"
        done
    fi
    TRUST_DONE=$hooks
}

RE_GH_SSH='^git@github\.com:([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+)$'
RE_GH_SSHURL='^ssh://git@github\.com(:22)?/([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+)/?$'
RE_GH_HTTPS='^https://github\.com/([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+)/?$'

# parse_github_url <url>: sets GH_OWNER and GH_REPO, or returns 1.
parse_github_url() {
    if [[ $1 =~ $RE_GH_SSH ]]; then
        GH_OWNER=${BASH_REMATCH[1]} GH_REPO=${BASH_REMATCH[2]}
    elif [[ $1 =~ $RE_GH_SSHURL ]]; then
        GH_OWNER=${BASH_REMATCH[2]} GH_REPO=${BASH_REMATCH[3]}
    elif [[ $1 =~ $RE_GH_HTTPS ]]; then
        GH_OWNER=${BASH_REMATCH[1]} GH_REPO=${BASH_REMATCH[2]}
    else
        return 1
    fi
    GH_REPO=${GH_REPO%.git}
    case $GH_OWNER in . | ..) return 1 ;; esac
    case $GH_REPO in '' | . | ..) return 1 ;; esac
    return 0
}

# remote_repos <what> <remote> <push|fetch> <url-ok>: appends owner/repo for
# every URL of the remote to REPOS, or denies.
remote_repos() {
    local what=$1 remote=$2 mode=$3 urlok=$4 urls url
    if [[ $remote =~ ^[A-Za-z0-9._-]+$ ]]; then
        if [ "$mode" = push ]; then
            urls=$(gitq -C "$HOOK_CWD" remote get-url --push --all "$remote" 2>/dev/null)
        else
            urls=$(gitq -C "$HOOK_CWD" remote get-url --all "$remote" 2>/dev/null)
        fi
        if [ -n "$urls" ]; then
            while IFS= read -r url; do
                [ -n "$url" ] || continue
                parse_github_url "$url" || deny "$what blocked: remote \`$remote\` resolves to \`$url\`, which is not a github.com repository URL this hook recognizes. $OPERATOR"
                REPOS[${#REPOS[@]}]=$GH_OWNER/$GH_REPO
            done <<<"$urls"
            return 0
        fi
    fi
    if [ "$urlok" = 1 ] && parse_github_url "$remote"; then
        REPOS[${#REPOS[@]}]=$GH_OWNER/$GH_REPO
        return 0
    fi
    deny "$what blocked: \`$remote\` is not a configured remote of this repository. Name a configured remote; a URL, path or remote group cannot be checked. $OPERATOR"
}

CACHE_DIR=${GIT_GH_GUARD_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/claude-git-gh-guard}

# default_branch <owner/repo>: prints the default branch GitHub reports. The
# answer is cached for an hour in a directory the sandbox cannot write.
default_branch() {
    local slug=$1 file fresh name
    file=$CACHE_DIR/${slug%%/*}/${slug#*/}
    if [ -f "$file" ]; then
        fresh=$(find "$file" -mmin -60 2>/dev/null)
        if [ -n "$fresh" ]; then
            IFS= read -r name <"$file"
            if [[ $name =~ ^[A-Za-z0-9._/-]+$ ]]; then
                printf '%s' "$name"
                return 0
            fi
        fi
    fi
    name=$(GH_PROMPT_DISABLED=1 GH_NO_UPDATE_NOTIFIER=1 gh api "repos/$slug" --jq .default_branch 2>/dev/null) || return 1
    [[ $name =~ ^[A-Za-z0-9._/-]+$ ]] || return 1
    mkdir -p "${file%/*}" 2>/dev/null && printf '%s\n' "$name" >"$file" 2>/dev/null
    printf '%s' "$name"
}

# is_default <branch>: 0 when the branch is main, master, or the default
# branch of any repository in REPOS. A failed lookup denies.
is_default() {
    local b=$1 lb slug def
    lb=$(lower "$b")
    case $lb in main | master) return 0 ;; esac
    for slug in ${REPOS[@]+"${REPOS[@]}"}; do
        def=$(default_branch "$slug") || deny "blocked: could not read the default branch of $slug from GitHub (\`gh api repos/$slug\` failed), so a default-branch push cannot be ruled out. $OPERATOR"
        [ "$lb" != "$(lower "$def")" ] || return 0
    done
    return 1
}

# --- Transport: git push / fetch / ls-remote. ---------------------------------
transport_common() {
    local what=$1 from=$2 i
    [ "${#AS_NAME[@]}" -eq 0 ] || deny "$what blocked: an environment assignment before the command (\`${AS_NAME[0]}=...\`) can change which key, config or program git uses. Run the command without it. $OPERATOR"
    [ -z "$ENV_TAINT" ] || deny "$what blocked: the call sets \`$ENV_TAINT\` first."
    [ "$GLOBAL_PLAIN" = 1 ] || deny "$what blocked: a git option before the subcommand (\`-C\`, \`-c\`, \`--git-dir\` and the like) points git at another repository or config. Run it from the repository's worktree with no global option. $OPERATOR"
    i=0
    while [ "$i" -lt "${#rw[@]}" ]; do
        case ${rf[$i]} in
            *P*) fd_dup "${rw[$i]}" || deny "$what blocked: outside the sandbox a redirection can write anywhere. Only \`2>&1\` and \`/dev/null\` are accepted here." ;;
            *) [ "${rw[$i]}" = /dev/null ] || deny "$what blocked: outside the sandbox a redirection can write anywhere. Only \`2>&1\` and \`/dev/null\` are accepted here." ;;
        esac
        i=$((i + 1))
    done
    i=$from
    while [ "$i" -lt "${#sw[@]}" ]; do
        case ${sf[$i]} in
            *[DUXG]*) deny "$what blocked: every word must be a plain literal so the destination can be read. \`\$variables\`, command substitutions and unquoted globs are refused; spell the remote and branch out." ;;
        esac
        i=$((i + 1))
    done
}

check_push() {
    local a=$1 n=${#sw[@]} w del=0 tags=0 i dst src d next_is_tag=0 nref=0 pd full want
    local pos=()
    while [ "$a" -lt "$n" ]; do
        w=${sw[$a]}
        [[ $w =~ ^[A-Za-z0-9._/@+:=,-]+$ ]] || deny "git push blocked: \`$w\` has characters outside the set this hook reads as a flag, remote or branch name."
        case $w in
            -u | --set-upstream | -f | --force | --force-with-lease | --force-with-lease=* | --force-if-includes | --no-force-if-includes | -n | --dry-run | -v | --verbose | -q | --quiet | --progress | --no-progress | --follow-tags | --no-follow-tags | --atomic | --no-atomic | --porcelain | --thin | --no-thin | -4 | -6 | --ipv4 | --ipv6 | --no-recurse-submodules | --verify | --no-signed) ;;
            --tags) tags=1 ;;
            -d | --delete) del=1 ;;
            --no-verify) deny "git push blocked: \`--no-verify\` skips the pre-push hook, a permission that exists outside the sandbox. $OPERATOR" ;;
            --all | --branches | --mirror | --prune) deny "git push blocked: \`$w\` pushes or deletes branches this hook cannot list, the default branch among them. Name each branch." ;;
            -*)
                if [[ $w =~ ^-[ufnvqd46]+$ ]]; then
                    case $w in *d*) del=1 ;; esac
                else
                    deny "git push blocked: \`$w\` is not on the push flag allowlist (it can reroute the push, run a program, or name its target in a form this hook does not read). $OPERATOR"
                fi
                ;;
            *) pos[${#pos[@]}]=$w ;;
        esac
        a=$((a + 1))
    done
    [ "${#pos[@]}" -ge 1 ] || deny "git push blocked: name the remote and the branch, as in \`git push -u origin <branch>\`. A bare \`git push\` takes its destination from config this hook does not resolve."
    [ "${#pos[@]}" -ge 2 ] || [ "$tags" = 1 ] || deny "git push blocked: name the branch after the remote, as in \`git push -u ${pos[0]} <branch>\` (\`git branch --show-current\` prints it)."
    repo_trust "git push"
    REPOS=()
    remote_repos "git push" "${pos[0]}" push 0
    [ -z "$(gitq -C "$HOOK_CWD" config --get-all "remote.${pos[0]}.push" 2>/dev/null)" ] || deny "git push blocked: remote.${pos[0]}.push is configured, so a branch name alone does not say where it lands. $OPERATOR"
    pd=$(lower "$(gitq -C "$HOOK_CWD" config --get push.default 2>/dev/null)")
    i=1
    while [ "$i" -lt "${#pos[@]}" ]; do
        w=${pos[$i]}
        i=$((i + 1))
        if [ "$next_is_tag" = 1 ]; then
            next_is_tag=0
            continue
        fi
        if [ "$w" = tag ]; then
            next_is_tag=1
            continue
        fi
        nref=$((nref + 1))
        w=${w#+}
        case $w in
            *:*)
                src=${w%%:*}
                dst=${w#*:}
                ;;
            *)
                src=$w
                dst=$w
                # With no `:<dst>` git derives the destination from what the
                # source resolves to. A symbolic ref (`head`, another
                # worktree's HEAD, a `git symbolic-ref` alias) lands on the
                # branch it points at, and `push.default=upstream` lands on
                # the tracked branch, so the name alone is not the answer.
                if [ "$del" = 0 ]; then
                    case $pd in
                        upstream | tracking) deny "git push blocked: push.default is \`$pd\`, so \`$src\` alone lands on the branch it tracks. Spell the destination, as in \`git push ${pos[0]} $src:$src\`." ;;
                    esac
                    # A name that resolves to nothing fails in git itself.
                    case $src in
                        refs/heads/* | refs/tags/*) want=$src ;;
                        *) want=refs/heads/$src ;;
                    esac
                    if full=$(gitq -C "$HOOK_CWD" rev-parse --verify --quiet --symbolic-full-name "$src" 2>/dev/null) && [ "$full" != "$want" ] && [ "$full" != "refs/tags/$src" ]; then
                        deny "git push blocked: \`$src\` is not the plain name of a local branch or tag (it resolves to \`${full:-nothing}\`), so git would choose the destination from what it points at. Spell both sides, as in \`git push ${pos[0]} <source>:<branch>\`."
                    fi
                fi
                ;;
        esac
        case $(lower "$dst") in
            head) deny "git push blocked: name the destination branch literally (\`git push ${pos[0]} <branch>\` or \`HEAD:<branch>\`); \`HEAD\` as a destination depends on the checkout at the moment of the push." ;;
        esac
        case $dst in
            '' | HEAD | @) deny "git push blocked: name the destination branch literally (\`git push ${pos[0]} <branch>\` or \`HEAD:<branch>\`); \`HEAD\` and \`@\` as a destination depend on the checkout at the moment of the push." ;;
            refs/tags/* | tags/*) continue ;;
        esac
        d=${dst#refs/heads/}
        d=${d#heads/}
        case $d in
            refs/*) deny "git push blocked: \`$dst\` is outside refs/heads and refs/tags. $OPERATOR" ;;
        esac
        if is_default "$d"; then
            deny "git push blocked: \`$d\` is a default branch (main, master, or the repository's default on GitHub). Push to another branch and open a pull request. $OPERATOR"
        fi
    done
    return 0
}

check_fetch() {
    local sub=$1 a=$2 n=${#sw[@]} w all=0 norecurse=0 r
    local pos=()
    while [ "$a" -lt "$n" ]; do
        w=${sw[$a]}
        [[ $w =~ ^[A-Za-z0-9._/@+:=,*^-]+$ ]] || deny "git $sub blocked: \`$w\` has characters outside the set this hook reads as a flag, remote or ref pattern."
        if [ "$sub" = fetch ]; then
            case $w in
                --all) all=1 ;;
                --no-recurse-submodules) norecurse=1 ;;
                -p | --prune | -t | --tags | --no-tags | -n | -q | --quiet | -v | --verbose | --progress | --no-progress | -f | --force | --dry-run | -u | --update-head-ok | --atomic | -4 | -6 | --ipv4 | --ipv6 | --unshallow | --update-shallow | --prune-tags | -P | --set-upstream | --no-auto-gc | --no-auto-maintenance | --write-fetch-head | --no-write-fetch-head | -k | --keep | --refetch | -a | --append | --porcelain | --no-filter | --depth=* | --deepen=* | --shallow-since=* | --shallow-exclude=* | --filter=* | --jobs=* | -j[0-9]*) ;;
                --depth | --deepen | --shallow-since | --shallow-exclude | -j | --jobs) a=$((a + 1)) ;;
                -*) deny "git fetch blocked: \`$w\` is not on the fetch flag allowlist (it can run a program or reach a remote this hook does not read). $OPERATOR" ;;
                *) pos[${#pos[@]}]=$w ;;
            esac
        else
            case $w in
                --heads | --branches | -b | -h | -t | --tags | --refs | -q | --quiet | --exit-code | --get-url | --symref | --sort=*) ;;
                -*) deny "git ls-remote blocked: \`$w\` is not on the ls-remote flag allowlist. $OPERATOR" ;;
                *) pos[${#pos[@]}]=$w ;;
            esac
        fi
        a=$((a + 1))
    done
    repo_trust "git $sub"
    REPOS=()
    if [ "$all" = 1 ] || [ "${#pos[@]}" -eq 0 ]; then
        while IFS= read -r r; do
            [ -n "$r" ] || continue
            remote_repos "git $sub" "$r" fetch 0
        done < <(gitq -C "$HOOK_CWD" remote 2>/dev/null)
        branch_remote_ok "git $sub"
    else
        remote_repos "git $sub" "${pos[0]}" fetch 1
    fi
    if [ "$sub" = fetch ] && [ "$norecurse" = 0 ]; then
        submodules_refuse "git fetch" 'Add `--no-recurse-submodules`.'
    fi
    return 0
}

# --- Other git verbs that leave the sandbox. ----------------------------------
# `git pull`, `git clone`, `git remote update|prune`, `git worktree
# add|remove|move|prune`, `git branch` with an upstream flag, `git config
# set|unset` and `git submodule update|init|sync` are excluded from the
# sandbox, which denies them SSH, the repository's `config` and its
# `worktrees` directory. Each is accepted there only as the sole command,
# every word a plain literal, flags from an allowlist, in the session's
# project repository after repo_trust. Beside `cd <dir> &&` the call stays
# sandboxed and the loose checks apply instead.

out_common() {
    [ "$SOLE" = 1 ] || deny "$1 blocked: outside the sandbox it is accepted only as its own Bash call with nothing else in it. Beside \`cd <dir> &&\` the call stays sandboxed and this check does not apply."
    transport_common "$1" "$2"
}

# branch_remote_ok <what>: the remote the current branch tracks, which a
# fetch or pull with no remote uses, is a configured github.com remote.
branch_remote_ok() {
    local cur r
    cur=$(gitq -C "$HOOK_CWD" symbolic-ref --short -q HEAD 2>/dev/null) || return 0
    [ -n "$cur" ] || return 0
    r=$(gitq -C "$HOOK_CWD" config --get "branch.$cur.remote" 2>/dev/null)
    [ -n "$r" ] && [ "$r" != . ] || return 0
    remote_repos "$1" "$r" fetch 0
}

# has_submodules: 0 when git could recurse into a submodule here. Git reads
# `.gitmodules` from the index and from HEAD when the file is gone, and
# fetches a submodule whose git directory exists under `modules` even when
# the index no longer lists it, so the worktree file alone decides nothing.
has_submodules() {
    local top gd root
    top=$(gitq -C "$HOOK_CWD" rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$top" ]; then
        [ ! -e "$top/.gitmodules" ] && [ ! -L "$top/.gitmodules" ] || return 0
    fi
    ! gitq -C "$HOOK_CWD" cat-file -e :.gitmodules 2>/dev/null || return 0
    ! gitq -C "$HOOK_CWD" cat-file -e HEAD:.gitmodules 2>/dev/null || return 0
    [ -z "$(gitq -C "$HOOK_CWD" ls-files -s 2>/dev/null | grep -m1 '^160000 ')" ] || return 0
    gd=$(gitq -C "$HOOK_CWD" rev-parse --absolute-git-dir 2>/dev/null)
    for root in "$gd/modules" "$REPO_COMMON/modules"; do
        [ "$root" != /modules ] && [ -d "$root" ] || continue
        [ -r "$root" ] && [ -x "$root" ] && [ -z "$(ls -A "$root" 2>/dev/null)" ] || return 0
    done
    return 1
}

# submodules_refuse <what> <hint>: a verb that would recurse into submodules.
submodules_refuse() {
    if has_submodules; then
        deny "$1 blocked: this repository has submodules, and outside the sandbox it would run git inside each with config this hook has not read. $2"
    fi
}

# Compared in lower case: the names git reserves inside a git directory.
RE_GITDIR_NAMES='^(objects|refs|hooks|info|worktrees|logs|modules|lfs|rr-cache|branches|remotes|svn|config|head|packed-refs|description|index|shallow|fetch_head|orig_head|commondir|gitdir)$'

# dest_ok <what> <path>: a directory git creates outside the sandbox must lie
# where a sandboxed command could already write: a Claude scratch root, or
# the session's project (a new worktree beside the others of a bare
# repository, a path inside the project's checkout, or a checkout's
# `.claude/worktrees/<name>`). Never inside a `.git` or `.claude` directory.
dest_ok() {
    local what=$1 p=$2 abs d rest='' phys body root='' rel first bare=0 lphys
    case "/$p/" in */../*) deny "$what blocked: the destination \`$p\` holds \`..\`. Spell the path without it." ;; esac
    # ASCII only: a case-folding or normalizing volume maps other spellings
    # onto `.git` and `.claude`.
    [[ $p =~ ^[A-Za-z0-9._/@+=,:-]+$ ]] || deny "$what blocked: the destination \`$p\` has characters outside the set this hook reads as a path (letters, digits and \`._/@+=,:-\`)."
    [ -n "$HOOK_CWD" ] && [ -d "$HOOK_CWD" ] || deny "$what blocked: the hook input names no working directory, so the destination cannot be checked."
    abs=$(join_path "$HOOK_CWD" "$p")
    while [ "$abs" != / ] && [ "${abs%/}" != "$abs" ]; do abs=${abs%/}; done
    d=$abs
    while [ ! -d "$d" ]; do
        rest=/${d##*/}$rest
        d=${d%/*}
        [ -n "$d" ] || d=/
    done
    phys=$(physical "$d") || deny "$what blocked: the destination \`$p\` cannot be resolved."
    phys=${phys%/}$rest
    body=$phys
    if [[ $phys =~ ^(.*)/\.claude/worktrees/[A-Za-z0-9._+-]+$ ]]; then
        body=${BASH_REMATCH[1]}
    fi
    # The volume may fold case, and `pwd -P` keeps the spelling it was given,
    # so the reserved names are compared in lower case.
    lphys=$(lower "$phys")
    case "$lphys/" in
        */.git/*) deny "$what blocked: the destination \`$p\` is inside a \`.git\` or \`.claude\` directory. $OPERATOR" ;;
    esac
    case "$(lower "$body")/" in
        */.claude/*) deny "$what blocked: the destination \`$p\` is inside a \`.git\` or \`.claude\` directory. $OPERATOR" ;;
    esac
    case "$phys/" in
        /tmp/claude/* | /tmp/claude-*/* | /private/tmp/claude/* | /private/tmp/claude-*/* | /var/folders/* | /private/var/folders/*)
            case "$lphys/" in
                */tasks/* | */bash-edit-diff/* | */plugin-tool-staging/*) ;;
                *) return 0 ;;
            esac
            ;;
    esac
    project_common
    if [ -n "$PROJECT_COMMON" ]; then
        if [ "$(gitq --git-dir="$PROJECT_COMMON" rev-parse --is-bare-repository 2>/dev/null)" = true ]; then
            root=$PROJECT_COMMON bare=1
        elif [ "${PROJECT_COMMON%/.git}" != "$PROJECT_COMMON" ]; then
            root=${PROJECT_COMMON%/.git}
        fi
    fi
    if [ -n "$root" ]; then
        case "$phys/" in
            "$root"/*/*)
                rel=${phys#"$root"/}
                first=${rel%%/*}
                if [ "$bare" = 1 ] && [[ $(lower "$first") =~ $RE_GITDIR_NAMES ]]; then
                    deny "$what blocked: the destination \`$p\` is inside the repository's git directory. $OPERATOR"
                fi
                return 0
                ;;
        esac
    fi
    # A session in a linked worktree away from the main checkout: its own
    # checkout is the project too.
    if [ -n "$PROJECT_COMMON" ] && [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
        root=$(gitq -C "$CLAUDE_PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null)
        [ -z "$root" ] || root=$(physical "$root")
        if [ -n "$root" ] && [ "$root" != / ]; then
            case "$phys/" in "$root"/?*/) return 0 ;; esac
        fi
    fi
    deny "$what blocked: the destination \`$p\` is outside this session's project and the Claude scratch roots, and outside the sandbox git would write there unchecked. $OPERATOR"
}

check_pull() {
    local a=$1 n=${#sw[@]} w norecurse=0 r
    local pos=()
    while [ "$a" -lt "$n" ]; do
        w=${sw[$a]}
        [[ $w =~ ^[A-Za-z0-9._/@+:=,*^-]+$ ]] || deny "git pull blocked: \`$w\` has characters outside the set this hook reads as a flag, remote or ref."
        case $w in
            --no-recurse-submodules) norecurse=1 ;;
            --no-verify) deny "git pull blocked: \`--no-verify\` skips the repository's hooks, a permission that exists outside the sandbox. $OPERATOR" ;;
            --no-gpg-sign) deny "git pull blocked: \`--no-gpg-sign\` drops the signature this environment is configured to make. $OPERATOR" ;;
            -r | --rebase | --rebase=true | --rebase=false | --rebase=merges | --no-rebase | --ff-only | --ff | --no-ff | --autostash | --no-autostash | -q | --quiet | -v | --verbose | --progress | --no-progress | -p | --prune | -t | --tags | --no-tags | --unshallow | --squash | --no-squash | --commit | --no-commit | --no-edit | --stat | --no-stat | -n | --log | --no-log | --signoff | --no-signoff | --allow-unrelated-histories | --set-upstream | -4 | -6 | --ipv4 | --ipv6 | --verify | --verify-signatures | --depth=* | --deepen=* | --shallow-since=* | --jobs=* | -j[0-9]* | -j | --jobs) ;;
            --depth | --deepen) a=$((a + 1)) ;;
            -*) deny "git pull blocked: \`$w\` is not on the pull flag allowlist (it can run a program, open an editor, or pick a merge strategy or remote this hook does not read). $OPERATOR" ;;
            *) pos[${#pos[@]}]=$w ;;
        esac
        a=$((a + 1))
    done
    repo_trust "git pull" all
    REPOS=()
    if [ "${#pos[@]}" -eq 0 ]; then
        # With no upstream, or a detached HEAD, git fetches `origin` before
        # it reports the missing upstream, so every remote is checked.
        while IFS= read -r r; do
            [ -n "$r" ] || continue
            remote_repos "git pull" "$r" fetch 0
        done < <(gitq -C "$HOOK_CWD" remote 2>/dev/null)
        branch_remote_ok "git pull"
    else
        remote_repos "git pull" "${pos[0]}" fetch 0
    fi
    [ "$norecurse" = 1 ] || submodules_refuse "git pull" 'Add `--no-recurse-submodules`.'
    return 0
}

check_clone() {
    local a=$1 n=${#sw[@]} w dir bare=0 dd=0
    local pos=()
    while [ "$a" -lt "$n" ]; do
        w=${sw[$a]}
        a=$((a + 1))
        if [ "$dd" = 1 ]; then
            pos[${#pos[@]}]=$w
            continue
        fi
        case $w in
            --) dd=1 ;;
            --depth | -b | --branch | -o | --origin) a=$((a + 1)) ;;
            --bare) bare=1 ;;
            --depth=* | --branch=* | --origin=* | --single-branch | --no-single-branch | --no-tags | --filter=* | -q | --quiet | -v | --verbose | --no-checkout | -n | --sparse | --progress | --no-recurse-submodules) ;;
            -*) deny "git clone blocked: \`$w\` is not on the clone flag allowlist (it can set config, run a program, recurse into submodules or write outside the destination). $OPERATOR" ;;
            *) pos[${#pos[@]}]=$w ;;
        esac
    done
    [ "${#pos[@]}" -ge 1 ] && [ "${#pos[@]}" -le 2 ] || deny "git clone blocked: it takes one repository URL and at most one directory."
    parse_github_url "${pos[0]}" || deny "git clone blocked: \`${pos[0]}\` is not a github.com repository URL this hook recognizes. Outside the sandbox only such a URL is cloned; a clone of a local path stays sandboxed beside \`cd <dir> &&\`. $OPERATOR"
    if [ "${#pos[@]}" -eq 2 ]; then
        dir=${pos[1]}
    else
        dir=${GH_REPO%.git}
        [ "$bare" = 0 ] || dir=$dir.git
    fi
    dest_ok "git clone" "$dir"
}

check_remote_out() {
    local verb=$1 a=$2 n=${#sw[@]} w r
    local pos=()
    while [ "$a" -lt "$n" ]; do
        w=${sw[$a]}
        a=$((a + 1))
        [[ $w =~ ^[A-Za-z0-9._-]+$ ]] || deny "git remote $verb blocked: \`$w\` has characters outside the set this hook reads as a flag or a remote name."
        case "$verb $w" in
            'update -p' | 'update --prune' | 'prune -n' | 'prune --dry-run') ;;
            *' -'*) deny "git remote $verb blocked: \`$w\` is not on its flag allowlist. $OPERATOR" ;;
            *) pos[${#pos[@]}]=$w ;;
        esac
    done
    repo_trust "git remote $verb"
    REPOS=()
    if [ "${#pos[@]}" -eq 0 ]; then
        [ "$verb" = update ] || deny "git remote prune blocked: name the remote to prune."
        while IFS= read -r r; do
            [ -n "$r" ] || continue
            remote_repos "git remote $verb" "$r" fetch 0
        done < <(gitq -C "$HOOK_CWD" remote 2>/dev/null)
    else
        for r in "${pos[@]}"; do
            remote_repos "git remote $verb" "$r" fetch 0
        done
    fi
    [ "$verb" != update ] || submodules_refuse "git remote update" 'Use `git fetch --all --prune --no-recurse-submodules`.'
    return 0
}

# worktree_other <what> <path>: the path is a registered worktree of this
# repository and not the checkout the session works in.
worktree_other() {
    local what=$1 p=$2 abs phys own line found=0
    case "/$p/" in */../*) deny "$what blocked: the path \`$p\` holds \`..\`. Spell the path without it." ;; esac
    abs=$(join_path "$HOOK_CWD" "$p")
    phys=$(physical "$abs") || deny "$what blocked: \`$p\` is not an existing directory, so it cannot be matched to a registered worktree. A stale entry is cleared by \`git worktree prune\`."
    own=$(gitq -C "$HOOK_CWD" rev-parse --show-toplevel 2>/dev/null)
    [ -z "$own" ] || own=$(physical "$own")
    case "$(physical "$HOOK_CWD")/" in
        "$phys"/*) deny "$what blocked: \`$p\` is the checkout this call runs in. $OPERATOR" ;;
    esac
    [ "$phys" != "$own" ] || deny "$what blocked: \`$p\` is the checkout this call runs in. $OPERATOR"
    if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
        case "$(physical "$CLAUDE_PROJECT_DIR")/" in
            "$phys"/*) deny "$what blocked: \`$p\` is this session's project checkout. $OPERATOR" ;;
        esac
    fi
    while IFS= read -r line; do
        case $line in
            'worktree '*)
                [ "$(physical "${line#worktree }")" != "$phys" ] || found=1
                ;;
        esac
    done < <(gitq -C "$HOOK_CWD" worktree list --porcelain 2>/dev/null)
    [ "$found" = 1 ] || deny "$what blocked: \`$p\` is not a registered worktree of this repository."
}

check_worktree_out() {
    local verb=$1 a=$2 n=${#sw[@]} w
    local pos=()
    while [ "$a" -lt "$n" ]; do
        w=${sw[$a]}
        a=$((a + 1))
        case "$verb $w" in
            'add -b' | 'add -B' | 'prune --expire')
                [[ ${sw[$a]:-} =~ ^[A-Za-z0-9._/@:+-]+$ ]] || deny "git worktree $verb blocked: \`$w\` needs a plain literal value."
                a=$((a + 1))
                ;;
            'add -d' | 'add --detach' | 'add --no-checkout' | 'add --lock' | 'add --orphan' | 'add -q' | 'add --quiet' | 'add --track' | 'add --no-track' | 'add --guess-remote' | 'add --no-guess-remote' | 'add --relative-paths' | 'add --no-relative-paths' | 'prune -n' | 'prune --dry-run' | 'prune -v' | 'prune --verbose' | 'prune --expire='*) ;;
            *' -f' | *' --force') deny "git worktree $verb blocked: \`--force\` overrides the lock and dirty-tree checks that protect another session's checkout. $OPERATOR" ;;
            *' -'*) deny "git worktree $verb blocked: \`$w\` is not on its flag allowlist. $OPERATOR" ;;
            *) pos[${#pos[@]}]=$w ;;
        esac
    done
    case $verb in
        add)
            [ "${#pos[@]}" -ge 1 ] && [ "${#pos[@]}" -le 2 ] || deny "git worktree add blocked: it takes one path and at most one commit."
            if [ "${#pos[@]}" -eq 2 ]; then
                [[ ${pos[1]} =~ ^[A-Za-z0-9._/@^~+-]+$ ]] || deny "git worktree add blocked: \`${pos[1]}\` has characters outside the set this hook reads as a commit."
            fi
            repo_trust "git worktree add" all
            dest_ok "git worktree add" "${pos[0]}"
            ;;
        remove)
            [ "${#pos[@]}" -eq 1 ] || deny "git worktree remove blocked: it takes one worktree path."
            repo_trust "git worktree remove"
            worktree_other "git worktree remove" "${pos[0]}"
            ;;
        move)
            [ "${#pos[@]}" -eq 2 ] || deny "git worktree move blocked: it takes a worktree path and a new path."
            repo_trust "git worktree move"
            worktree_other "git worktree move" "${pos[0]}"
            dest_ok "git worktree move" "${pos[1]}"
            ;;
        prune)
            [ "${#pos[@]}" -eq 0 ] || deny "git worktree prune blocked: it takes no path."
            repo_trust "git worktree prune"
            ;;
    esac
    return 0
}

check_branch_out() {
    local a=$1 n=${#sw[@]} w npos=0
    while [ "$a" -lt "$n" ]; do
        w=${sw[$a]}
        a=$((a + 1))
        [[ $w =~ ^[A-Za-z0-9._/@=+-]+$ ]] || deny "git branch blocked: \`$w\` has characters outside the set this hook reads as a flag or a branch."
        case $w in
            -u | -u?* | --set-upstream-to | --set-upstream-to=* | --unset-upstream | -q | --quiet) ;;
            -*) deny "git branch blocked: beside an upstream flag (\`-u\`, \`--set-upstream-to\`, \`--unset-upstream\`) the call leaves the sandbox, and \`$w\` is not accepted there. Run it as a separate call." ;;
            *) npos=$((npos + 1)) ;;
        esac
    done
    [ "$npos" -le 2 ] || deny "git branch blocked: an upstream change takes at most an upstream and one branch."
    repo_trust "git branch"
}

check_config_out() {
    local verb=$1 a=$2 n=${#sw[@]} w key='' val='' npos=0 lk
    while [ "$a" -lt "$n" ]; do
        w=${sw[$a]}
        a=$((a + 1))
        if [ "$npos" -eq 0 ]; then
            case $w in
                --local | --all | --append | --fixed-value | --no-type | --type=bool | --type=int | --type=bool-or-int | --type=expiry-date | --type=color | --value=*) continue ;;
                -*) deny "git config $verb blocked: \`$w\` is not accepted outside the sandbox. Only the repository's own config is written there; \`--global\`, \`--system\`, \`--worktree\` and \`--file\` stay with the operator. $OPERATOR" ;;
            esac
        fi
        npos=$((npos + 1))
        case $npos in
            1) key=$w ;;
            2) val=$w ;;
        esac
    done
    if [ "$verb" = set ]; then
        [ "$npos" -eq 2 ] || deny "git config set blocked: it takes one key and one value, flags first."
    else
        [ "$npos" -eq 1 ] || deny "git config unset blocked: it takes one key, flags first."
    fi
    [[ $key =~ ^[A-Za-z0-9._/@+-]+$ ]] || deny "git config $verb blocked: \`$key\` has characters outside the set this hook reads as a key."
    lk=$(lower "$key")
    [[ $lk =~ $RE_CFG_OK ]] || deny "git config $verb blocked: \`$key\` is not on this hook's allowlist of keys that cannot reroute, re-authenticate or run a program. A key outside it would also make this hook refuse the next push or fetch. $OPERATOR"
    # A remote or branch name may hold dots, so no key under `remote.` is
    # written but the two that cannot reroute, and no `pushremote` at all.
    if danger_key "$key" || [[ $lk =~ ^submodule\. ]] || [[ $lk =~ \.pushremote$ ]] ||
        { [[ $lk =~ ^remote\. ]] && [[ ! $lk =~ ^remote\..+\.(tagopt|prune)$ ]]; } ||
        [[ $lk =~ ^remote\..*\.(url|pushurl|push|fetch|gh-resolved|receivepack|uploadpack|proxy|vcs)\. ]]; then
        deny "git config $verb blocked: writing \`$key\` changes how git authenticates, signs, routes a push or fetch, or runs a program. $OPERATOR"
    fi
    if [ "$verb" = set ]; then
        [[ ! $val =~ $RE_CODE_MENTION ]] || deny "git config set blocked: the value holds a git or gh command."
        if [[ $lk =~ ^branch\..+\.remote$ ]] && [ "$val" != . ]; then
            gitq -C "$HOOK_CWD" remote 2>/dev/null | grep -qxF -- "$val" || deny "git config set blocked: \`$key\` must name a configured remote, and \`$val\` is not one."
        fi
        if [[ $lk =~ ^branch\..+\.merge$ ]]; then
            [[ $val =~ ^refs/heads/[A-Za-z0-9._/@+-]+$ ]] || deny "git config set blocked: \`$key\` must be a \`refs/heads/<branch>\` name."
        fi
    fi
    repo_trust "git config $verb"
}

# vet_gitdir <what> <git dir>: a submodule's git directory holds only
# allowlisted config, github.com remotes and no hook.
vet_gitdir() {
    local what=$1 d=$2 key line
    [ -f "$d/config" ] && [ -f "$d/HEAD" ] || deny "$what blocked: $d is not a git directory this hook can read. $OPERATOR"
    # A `commondir` file moves config and hooks to a directory not read here.
    [ ! -e "$d/commondir" ] && [ ! -e "$d/config.worktree" ] || deny "$what blocked: the submodule git directory $d takes config from another directory (\`commondir\` or \`config.worktree\`), which this hook does not read. $OPERATOR"
    while IFS= read -r key; do
        [ -n "$key" ] || continue
        [[ $key =~ $RE_CFG_OK ]] || [ "$key" = core.worktree ] || deny "$what blocked: the submodule git directory $d sets \`$key\`, which is not on this hook's config allowlist. $OPERATOR"
    done < <(gitq config -f "$d/config" --name-only --list 2>/dev/null)
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        parse_github_url "${line#* }" || deny "$what blocked: the submodule git directory $d points at \`${line#* }\`, which is not a github.com repository URL this hook recognizes. $OPERATOR"
    done < <(gitq config -f "$d/config" --get-regexp '^(remote|submodule)\..*\.url$' 2>/dev/null)
    legacy_clean "$what" "$d"
    hooks_clean "$what" "$d"
}

# gitmodules_cfg <top> <file|index|head> <git config arguments>
gitmodules_cfg() {
    local top=$1 src=$2
    shift 2
    case $src in
        file) gitq config -f "$top/.gitmodules" "$@" ;;
        index) gitq -C "$top" config --blob :.gitmodules "$@" ;;
        head) gitq -C "$top" config --blob HEAD:.gitmodules "$@" ;;
    esac
}

check_submodule_out() {
    local verb=$1 a=$2 n=${#sw[@]} w dd=0 top ptop gd root cfg line src out rc path sp d rest g first tp rp ok names name bytes
    while [ "$a" -lt "$n" ]; do
        w=${sw[$a]}
        a=$((a + 1))
        [[ $w =~ ^[A-Za-z0-9._/=@+-]+$ ]] || deny "git submodule $verb blocked: \`$w\` has characters outside the set this hook reads as a flag or a path."
        [ "$dd" = 0 ] || continue
        case "$verb $w" in
            *' --') dd=1 ;;
            'update --init' | 'update --remote' | 'update -N' | 'update --no-fetch' | 'update --checkout' | 'update --single-branch' | 'update --no-single-branch' | 'update --progress' | 'update --recommend-shallow' | 'update --no-recommend-shallow' | 'update --depth='* | 'update --jobs='* | 'update -j'[0-9]* | *' -q' | *' --quiet') ;;
            'update --depth' | 'update -j' | 'update --jobs') a=$((a + 1)) ;;
            *' --recursive') deny "git submodule $verb blocked: \`--recursive\` reaches nested submodules whose URLs and git directories this hook has not read. $OPERATOR" ;;
            *' -'*) deny "git submodule $verb blocked: \`$w\` is not on its flag allowlist. $OPERATOR" ;;
        esac
    done
    repo_trust "git submodule $verb" all
    top=$(gitq -C "$HOOK_CWD" rev-parse --show-toplevel 2>/dev/null)
    [ -n "$top" ] || deny "git submodule $verb blocked: the working directory is not inside a checkout, so its submodules cannot be read."
    ptop=$(physical "$top") || deny "git submodule $verb blocked: the checkout \`$top\` cannot be resolved."
    [ ! -L "$top/.gitmodules" ] || deny "git submodule $verb blocked: .gitmodules is a symbolic link."
    [ ! -e "$top/.gitmodules" ] || [ -f "$top/.gitmodules" ] || deny "git submodule $verb blocked: .gitmodules is not a regular file."
    # Git falls back from the file to the index and then to HEAD, so every
    # copy that exists is read, for its URLs and its submodule names.
    names=''
    for src in file index head; do
        case $src in
            file) [ -f "$top/.gitmodules" ] || continue ;;
            index) gitq -C "$top" cat-file -e :.gitmodules 2>/dev/null || continue ;;
            head) gitq -C "$top" cat-file -e HEAD:.gitmodules 2>/dev/null || continue ;;
        esac
        out=$(gitmodules_cfg "$top" "$src" --get-regexp '^submodule\..*\.url$' 2>/dev/null)
        rc=$?
        [ "$rc" -le 1 ] || deny "git submodule $verb blocked: the $src copy of .gitmodules cannot be parsed. $OPERATOR"
        while IFS= read -r line; do
            [ -n "$line" ] || continue
            parse_github_url "${line#* }" || deny "git submodule $verb blocked: .gitmodules ($src copy) points \`${line%% *}\` at \`${line#* }\`, which is not a github.com repository URL this hook recognizes. $OPERATOR"
        done <<<"$out"
        out=$(gitmodules_cfg "$top" "$src" --name-only --get-regexp '^submodule\.' 2>/dev/null)
        while IFS= read -r line; do
            [ -n "$line" ] || continue
            [[ $line =~ ^submodule\.(.+)\.[A-Za-z0-9-]+$ ]] || deny "git submodule $verb blocked: the $src copy of .gitmodules holds an entry this hook cannot read. $OPERATOR"
            name=${BASH_REMATCH[1]}
            [[ $name =~ ^[A-Za-z0-9._/@+=-]+$ ]] || deny "git submodule $verb blocked: the submodule name \`$name\` has characters outside the set this hook reads. $OPERATOR"
            case "/$name/" in */../* | */./* | *//*) deny "git submodule $verb blocked: the submodule name \`$name\` is not a plain relative name. $OPERATOR" ;; esac
            names="$names$name"$'\n'
        done <<<"$out"
    done
    # Every git directory under `modules` is read: the one each submodule
    # name maps to, and every directory there that holds a HEAD file. A
    # symbolic link or a name with a line break under `modules` would let git
    # read a directory other than the one read here.
    gd=$(gitq -C "$HOOK_CWD" rev-parse --absolute-git-dir 2>/dev/null)
    for root in "$gd/modules" "$REPO_COMMON/modules"; do
        [ "$root" != /modules ] || continue
        [ -e "$root" ] || [ -L "$root" ] || continue
        [ -d "$root" ] && [ ! -L "$root" ] || deny "git submodule $verb blocked: \`$root\` is not a plain directory. $OPERATOR"
        [ -z "$(find "$root" \( -type l -o -name $'*\n*' \) -print 2>/dev/null | head -n 1)" ] || deny "git submodule $verb blocked: \`$root\` holds a symbolic link or a name with a line break, so the git directories under it cannot be read reliably. $OPERATOR"
        find "$root" >/dev/null 2>&1 || deny "git submodule $verb blocked: \`$root\` holds a directory that cannot be listed, so the git directories under it cannot be read. $OPERATOR"
        while IFS= read -r name; do
            [ -n "$name" ] || continue
            [ -e "$root/$name" ] || continue
            vet_gitdir "git submodule $verb" "$root/$name"
        done <<<"$names"
        # Git takes a directory for a git directory when it holds `HEAD`, in
        # any letter case on a volume that folds it, and either an `objects`
        # entry or a `commondir` file. A `HEAD` without those is a ref or a
        # reflog, wherever it sits.
        while IFS= read -r cfg; do
            cfg=${cfg%/*}
            [ -e "$cfg/objects" ] || [ -e "$cfg/commondir" ] || continue
            vet_gitdir "git submodule $verb" "$cfg"
        done < <(find "$root" ! -type d -iname HEAD 2>/dev/null)
    done
    # Git follows whatever `<path>/.git` says, and that file sits in the
    # worktree where a sandboxed command can write it. Each submodule path in
    # the index must be reached without a symbolic link, and its `.git` must
    # be absent or a gitfile into one of the `modules` directories read above.
    while IFS= read -r line; do
        case $line in '160000 '*) ;; *) continue ;; esac
        path=${line#*$'\t'}
        [[ $path =~ ^[A-Za-z0-9._/@+=-]+$ ]] || deny "git submodule $verb blocked: the submodule path \`$path\` has characters outside the set this hook reads. $OPERATOR"
        case "/$path/" in */../* | */./* | *//*) deny "git submodule $verb blocked: the submodule path \`$path\` is not a plain relative path. $OPERATOR" ;; esac
        sp=$top/$path
        d=$sp rest=''
        while [ ! -d "$d" ] || [ -L "$d" ]; do
            [ ! -L "$d" ] || deny "git submodule $verb blocked: the submodule path \`$path\` passes through a symbolic link. $OPERATOR"
            rest=/${d##*/}$rest
            d=${d%/*}
            [ -n "$d" ] || d=/
        done
        [ "$(physical "$d")$rest" = "$ptop/$path" ] || deny "git submodule $verb blocked: the submodule path \`$path\` passes through a symbolic link. $OPERATOR"
        g=$sp/.git
        [ -e "$g" ] || [ -L "$g" ] || continue
        [ -f "$g" ] && [ ! -L "$g" ] || deny "git submodule $verb blocked: \`$path/.git\` is a directory or a symbolic link, so the submodule's git directory is not under the repository's \`modules\` directory where this hook reads it. $OPERATOR"
        # Git reads the whole file as the path, so it must be one line of
        # plain characters.
        first=$(cat "$g" 2>/dev/null)
        [[ $first =~ ^gitdir:\ [A-Za-z0-9._/@+=-]+$ ]] || deny "git submodule $verb blocked: \`$path/.git\` is not a gitfile this hook can read (one line, \`gitdir: <path>\`, plain characters). $OPERATOR"
        # The shell copy drops a NUL byte, where git stops reading. The
        # byte count of the file must match the text checked above.
        [ "$(LC_ALL=C tr -dc '\000' <"$g" 2>/dev/null | wc -c | tr -d ' \t')" = 0 ] || deny "git submodule $verb blocked: \`$path/.git\` is not a gitfile this hook can read (it holds a NUL byte). $OPERATOR"
        bytes=$(wc -c <"$g" 2>/dev/null | tr -d ' \t')
        [ "$bytes" = "${#first}" ] || [ "$bytes" = "$((${#first} + 1))" ] || deny "git submodule $verb blocked: \`$path/.git\` is not a gitfile this hook can read (one line, \`gitdir: <path>\`, plain characters). $OPERATOR"
        case $first in
            'gitdir: /'*) tp=${first#gitdir: } ;;
            *) tp=$sp/${first#gitdir: } ;;
        esac
        tp=$(physical "$tp") || deny "git submodule $verb blocked: \`$path/.git\` names a git directory that does not resolve. $OPERATOR"
        ok=0
        for root in "$gd/modules" "$REPO_COMMON/modules"; do
            [ "$root" != /modules ] && [ -d "$root" ] || continue
            rp=$(physical "$root") || continue
            case "$tp/" in "$rp"/?*/) ok=1 ;; esac
        done
        [ "$ok" = 1 ] || deny "git submodule $verb blocked: \`$path/.git\` names a git directory outside the repository's \`modules\` directory, whose config and hooks this hook does not read. $OPERATOR"
        vet_gitdir "git submodule $verb" "$tp"
    done < <(gitq -C "$top" ls-files -s 2>/dev/null)
    return 0
}

# --- Loose checks on git that stays in the sandbox. ---------------------------
RE_DANGER='^(core\.(sshcommand|hookspath|fsmonitor|gitproxy|askpass|alternaterefscommand)|credential(\.|$)|url\.|include\.|includeif\.|alias\.|commit\.gpgsign|tag\.gpgsign|tag\.forcesignannotated|rebase\.gpgsign|sendemail\.validate|merge\.verifysignatures|gpg\.|user\.signingkey|http\.|https\.|protocol\.|hook\.|ssh\.|safe\.|extensions\.|push\.|receive\.|promisor\.|transfer\.credentialsinurl|remote\.pushdefault|remote\..*\.(url|pushurl|push|receivepack|uploadpack|proxy|vcs)|branch\..*\.pushremote)'

danger_key() {
    local key lk
    key=$1
    # A key with an expansion in it is dangerous unless its literal frame is
    # one of the branch-tracking keys.
    case $key in *$'\037'*)
        lk=$(lower "${key//$'\037'/x}")
        [[ $lk =~ ^branch\.[^.]*\.(remote|merge|rebase|description)$ ]] && return 1
        return 0
        ;;
    esac
    lk=$(lower "$key")
    [[ $lk =~ $RE_DANGER ]] || [[ "$lk." =~ $RE_DANGER ]]
}

# danger_section <name> <new>: a section that holds a dangerous key, so that
# removing or renaming it overrides what the key set up. A `branch.` section
# counts only as the new name of a rename.
danger_section() {
    local lk
    case $1 in *$'\037'*) return 0 ;; esac
    lk=$(lower "$1")
    [[ $lk =~ ^(core|credential|url|include|includeif|alias|commit|tag|rebase|merge|gpg|user|http|https|protocol|hook|ssh|safe|extensions|push|receive|promisor|transfer|remote)(\.|$) ]] && return 0
    [ "$2" = 1 ] && [[ $lk =~ ^branch(\.|$) ]] && return 0
    return 1
}

# cfg_pos <word>: one positional of `git config`, counted into the caller's
# npos, key and key2.
cfg_pos() {
    npos=$((npos + 1))
    [ "$npos" -ne 1 ] || key=$1
    [ "$npos" -ne 2 ] || key2=$1
    if [ "$npos" -ge 2 ] && [[ $1 =~ $RE_CODE_MENTION ]]; then
        deny "git config blocked: the value holds a git or gh command, which git would run later as an editor, pager, alias or helper where this hook does not check it."
    fi
    return 0
}

check_git_config() {
    local a=$1 n=${#sw[@]} w write=0 readonly_=0 edit=0 key='' key2='' npos=0 skip=0 verb='' cfgfile=0 scope='' cfgpath='' ddash=0 sect=0 rename=0
    # `xargs` appends words this hook does not read: a key, a value, a file.
    [ "$XARGS_PAD" = 0 ] || loose_deny "git config blocked: \`xargs\` appends words this hook does not read, which can name a key, a value or a file."
    while [ "$a" -lt "$n" ]; do
        w=${sw[$a]}
        a=$((a + 1))
        if [ "$skip" = 1 ]; then
            skip=0
            continue
        fi
        if is_dyn "${sf[$((a - 1))]}" && [ "${w:0:1}" = $'\037' ] && [ "$npos" -ge 1 ]; then
            npos=$((npos + 1))
            [ "$npos" -ne 2 ] || key2=$w
            continue
        fi
        # Git stops reading flags at `--` and at the first key or value:
        # `git config core.hooksPath /x --get` writes the key.
        if [ "$ddash" = 1 ]; then
            cfg_pos "$w"
            continue
        fi
        case $w in
            --) ddash=1 ;;
            --type | -t | --default | --comment | --value | --url | --blob) skip=1 ;;
            -f | --file)
                [ "$cfgfile" = 0 ] || scope="a second $w"
                cfgpath=${sw[$a]:-}
                GIT_C[${#GIT_C[@]}]=$(dirname -- "${sw[$a]:-.}")
                GIT_CF[${#GIT_CF[@]}]=${sf[$a]:--}
                cfgfile=1
                skip=1
                ;;
            --file=*)
                [ "$cfgfile" = 0 ] || scope='a second --file'
                cfgpath=${w#--file=}
                GIT_C[${#GIT_C[@]}]=$(dirname -- "${w#--file=}")
                GIT_CF[${#GIT_CF[@]}]=${sf[$((a - 1))]}
                cfgfile=1
                ;;
            # A scope outside the repository, and a file flag in a spelling
            # whose path is not read here (`-f<path>`, `--fil <path>`).
            --fix*) ;;
            # A negated flag resets a scope or a file named before it:
            # `--file <tmp>/x --no-file` writes the repository's own config.
            --gl* | --sy* | -f?* | --no-*) scope=$w ;;
            --fi*)
                scope=$w
                case $w in
                    *=*) ;;
                    *) skip=1 ;;
                esac
                ;;
            --get | --get-all | --get-regexp | --get-urlmatch | -l | --list | --get-color | --get-colorbool) readonly_=1 ;;
            --add | --unset | --unset-all | --replace-all | --append) write=1 ;;
            --rename-section) write=1 sect=1 rename=1 ;;
            --remove-section) write=1 sect=1 ;;
            -e | --edit) edit=1 ;;
            # Git takes any unambiguous prefix of a long flag: `--uns`,
            # `--rem`, `--typ bool`.
            --t* | --d* | --c* | --v* | --ur* | --bl*)
                case $w in
                    *=*) ;;
                    *) skip=1 ;;
                esac
                ;;
            --ad* | --uns* | --rep* | --ap*) write=1 ;;
            --ren*) write=1 sect=1 rename=1 ;;
            --rem*) write=1 sect=1 ;;
            --ed*) edit=1 ;;
            # Short flags written together: `-zf <path>`, `-ze`, `-zt bool`.
            -[!-]?*)
                case $w in
                    *f) scope=$w skip=1 ;;
                    *f*) scope=$w ;;
                    *t) skip=1 ;;
                esac
                case $w in *e*) edit=1 ;; esac
                case $w in *l*) readonly_=1 ;; esac
                ;;
            -*) ;;
            *)
                if [ "$npos" -eq 0 ] && [ -z "$verb" ]; then
                    case $w in
                        get | list)
                            readonly_=1
                            verb=$w
                            continue
                            ;;
                        set | unset)
                            write=1
                            verb=$w
                            continue
                            ;;
                        rename-section | remove-section)
                            write=1 sect=1
                            [ "$w" != rename-section ] || rename=1
                            verb=$w
                            continue
                            ;;
                        edit)
                            edit=1
                            verb=$w
                            continue
                            ;;
                    esac
                fi
                cfg_pos "$w"
                ddash=1
                ;;
        esac
    done
    if [ "$edit" = 1 ]; then
        [ -z "$scope" ] && [ "$cfgfile" = 0 ] || deny "git config --edit blocked: it opens a config file outside the repository at hand, and the hook cannot see what the edit changes. $OPERATOR"
        loose_deny "git config --edit blocked: the hook cannot see what the edit changes."
    fi
    [ "$readonly_" = 0 ] || [ "$write" = 1 ] || return 0
    [ "$write" = 1 ] || [ "$npos" -ge 2 ] || return 0
    [ -n "$key" ] || return 0
    if [ "$sect" = 1 ]; then
        danger_section "$key" "$rename" || { [ -n "$key2" ] && danger_section "$key2" 1; } || return 0
    else
        danger_key "$key" || return 0
    fi
    [ -z "$scope" ] || deny "git config blocked: writing \`${key//$'\037'/\$...}\` with \`${scope//$'\037'/\$...}\` reaches config outside the repository at hand, or names a file in a spelling this hook does not read. Spell a file out as \`--file <path>\`. $OPERATOR"
    # A named file outside a repository is not scratch because of that: it
    # can be the operator's global config.
    if [ "$cfgfile" = 1 ]; then
        classify_target
        case $TARGET_DIR/ in
            /tmp/* | /private/tmp/* | /var/folders/* | /private/var/folders/*) ;;
            *) deny "git config blocked: writing \`${key//$'\037'/\$...}\` to a named config file outside a temp root changes how git authenticates, signs, routes a push or runs a program wherever that file is read. $OPERATOR" ;;
        esac
        [ ! -L "$TARGET_DIR/${cfgpath##*/}" ] || deny "git config blocked: the named config file is a symbolic link, so the write lands in a file this hook has not read. $OPERATOR"
    fi
    loose_deny "git config blocked: writing \`${key//$'\037'/\$...}\` changes how git authenticates, signs, routes a push or runs a program."
}

check_git_loose() {
    local sub=$1 a=$2 n=${#sw[@]} w i key skip=0 nv=0 nvs=0 ngs=0 valflags vstop vnext nflag cluster head rest lit pre ok hookmgr=$ENV_HOOKMGR
    # ENV_GDIR already holds every assignment that moves the repository,
    # this command's own prefix among them, before any check asks where the
    # command runs.
    [ "$ENV_GDIR" = 0 ] || GDIR=1
    i=0
    while [ "$i" -lt "${#AS_NAME[@]}" ]; do
        case ${AS_NAME[$i]} in
            GIT_CONFIG* | GIT_SSH* | GIT_ASKPASS | GIT_PROXY_COMMAND | GIT_EXEC_PATH | GIT_ALLOW_PROTOCOL | SSH_ASKPASS | SSH_AUTH_SOCK)
                loose_deny "git $sub blocked: the \`${AS_NAME[$i]}=\` prefix changes the config, key or program git uses."
                ;;
            HUSKY | HUSKY_SKIP_HOOKS | LEFTHOOK) hookmgr=${AS_NAME[$i]} ;;
        esac
        i=$((i + 1))
    done
    if [ -n "$hookmgr" ]; then
        case $sub in
            commit | merge | rebase | am | cherry-pick | revert | pull | push)
                loose_deny "git $sub blocked: \`$hookmgr\` is set for it, which turns off the hooks the repository's hook manager installs."
                ;;
        esac
    fi
    [ -z "$ENV_TAINT_GIT" ] || loose_deny "git $sub blocked: the call exports \`$ENV_TAINT_GIT\`, which changes the config, key or program git uses."
    i=0
    while [ "$i" -lt "${#GIT_CFG[@]}" ]; do
        key=${GIT_CFG[$i]%%=*}
        if danger_key "$key"; then
            loose_deny "git $sub blocked: \`-c ${key//$'\037'/\$...}=...\` changes how git authenticates, signs, routes a push or runs a program."
        fi
        i=$((i + 1))
    done
    case $sub in
        config) check_git_config "$a" ;;
        send-email)
            while [ "$a" -lt "$n" ]; do
                case ${sw[$a]} in
                    --no-va* | --nova*) loose_deny "git send-email blocked: \`--no-validate\` skips the repository's sendemail-validate hook." ;;
                esac
                a=$((a + 1))
            done
            ;;
        remote)
            while [ "$a" -lt "$n" ]; do
                w=${sw[$a]}
                a=$((a + 1))
                if is_dyn "${sf[$((a - 1))]}"; then
                    loose_deny "git remote blocked: the subcommand is an expansion (\`git remote \$...\`), which can be \`add\` or \`set-url\`. Spell the subcommand out."
                fi
                case $w in
                    -v | --verbose) continue ;;
                    add | set-url | rename | remove | rm | set-branches)
                        loose_deny "git remote $w blocked: it changes where this repository pushes and fetches."
                        ;;
                esac
                break
            done
            ;;
        commit | merge | rebase | am | cherry-pick | revert | pull | tag | commit-tree)
            # The flags of each verb whose value is the next word, and the
            # short flags that take the rest of a cluster as their value. A
            # flag listed here that takes no value would hide the word after
            # it (`git am -s --no-verify`), so each verb has its own list.
            # vstop: the short flags that take a value, attached or as the
            # next word; vnext: those whose value is the next word when the
            # flag ends a cluster (`-am <msg>`); nflag: `-n` is --no-verify.
            nflag=0
            case $sub in
                commit)
                    valflags=' -m -F -C -c -t --message --file --reuse-message --reedit-message --template --author --date --fixup --squash --trailer --cleanup --pathspec-from-file '
                    vstop='mFCctSu' vnext='mFCct' nflag=1
                    ;;
                merge)
                    valflags=' -m -F -s -X --strategy --strategy-option --into-name --cleanup --message --file '
                    vstop='mFsXS' vnext='mFsX'
                    ;;
                rebase)
                    valflags=' -s -X -x --strategy --strategy-option --onto --exec '
                    vstop='sXxCS' vnext='sXx'
                    ;;
                am)
                    valflags=' --directory --exclude --include --patch-format '
                    vstop='pCS' vnext='' nflag=1
                    ;;
                cherry-pick | revert)
                    valflags=' -m -X --mainline --strategy --strategy-option --cleanup '
                    vstop='mXS' vnext='mX'
                    ;;
                pull)
                    valflags=' -s -X --strategy --strategy-option --upload-pack -o --server-option --refmap --depth '
                    vstop='sXoSj' vnext='sXo'
                    ;;
                tag)
                    valflags=' -m -F -u --message --file --local-user --cleanup --sort --format '
                    vstop='mFun' vnext='mFu'
                    ;;
                *)
                    valflags=' -p -m -F '
                    vstop='pmFS' vnext='pmF'
                    ;;
            esac
            while [ "$a" -lt "$n" ]; do
                w=${sw[$a]}
                a=$((a + 1))
                if [ "$skip" = 1 ]; then
                    skip=0
                    continue
                fi
                case $w in *$'\037'*)
                    # A word with an expansion in it is a value this hook
                    # does not read (`"$file"`, `-m"$msg"`, `--date="$d"`),
                    # unless its literal text is a flag the expansion could
                    # complete: `--no-verify"$e"`, `--no-"$x"`, `-a"$x"`.
                    lit=${w//$'\037'/}
                    pre=${w%%$'\037'*}
                    ok=1
                    case $pre in
                        # The expansion comes first. A literal rest that
                        # spells a negated flag (`"$d"-no-verify`) or only
                        # dashes (`"$a-$b"`) is refused; `"$v"-rc1` is a
                        # name.
                        '') [[ ! $lit =~ $RE_NEGLIT ]] || ok=0 ;;
                        --*=*) ;;
                        -*)
                            ok=0
                            if [[ $pre =~ ^-[A-Za-z0-9]+$ ]]; then
                                cluster=${pre#-}
                                head=${cluster%%[$vstop]*}
                                [ "$head" = "$cluster" ] || ok=1
                                if [ "$nflag" = 1 ]; then case $head in *n*) nv=1 ;; esac; fi
                            fi
                            ;;
                    esac
                    [ "$ok" = 1 ] || loose_deny "git $sub blocked: the flag \`${w//$'\037'/\$...}\` is built from an expansion, which can spell \`--no-verify\` or \`--no-gpg-sign\`. Spell the flag out."
                    continue
                    ;;
                esac
                [ "$w" != -- ] || break
                case $valflags in *" $w "*)
                    skip=1
                    continue
                    ;;
                esac
                case $w in
                    --no-verbose) ;;
                    --no-verify-*) nvs=1 ;;
                    --no-v* | --no-po*) nv=1 ;;
                    --no-g* | --no-sign) ngs=1 ;;
                    # `git tag --no-si` is `--no-sign`; on the other verbs
                    # it is `--no-signoff`.
                    --no-si*) [ "$sub" != tag ] || ngs=1 ;;
                    --*) ;;
                    -*)
                        if [[ $w =~ ^-[A-Za-z0-9]+$ ]]; then
                            cluster=${w#-}
                            head=${cluster%%[$vstop]*}
                            if [ "$nflag" = 1 ]; then case $head in *n*) nv=1 ;; esac; fi
                            # `-am <msg>`: the value is the next word.
                            rest=${cluster#"$head"}
                            if [ "${#rest}" = 1 ] && [ -n "$vnext" ]; then
                                case $vnext in *"$rest"*) skip=1 ;; esac
                            fi
                        fi
                        ;;
                esac
            done
            [ "$nv" = 0 ] || loose_deny "git $sub blocked: \`--no-verify\` (\`-n\` on commit and am) or \`--no-post-rewrite\` skips the repository's hooks."
            [ "$nvs" = 0 ] || loose_deny "git $sub blocked: \`--no-verify-signatures\` turns off the signature check this repository's config asks for."
            [ "$ngs" = 0 ] || loose_deny "git $sub blocked: \`--no-gpg-sign\` drops the signature this environment is configured to make."
            ;;
    esac
    return 0
}


# scratch_local_push <from>: 0 when the push stays inside the sandbox, runs in
# a scratch repository, and names a configured remote whose push URLs are all
# local paths. Such a push reaches no GitHub branch, so the transport checks
# do not apply. Anything this cannot prove falls through to them.
scratch_local_push() {
    local a=$1 n=${#sw[@]} w remote='' urls url dest dcommon
    [ "$MAYOUT" = 0 ] || return 1
    [ "${#AS_NAME[@]}" -eq 0 ] && [ -z "$ENV_TAINT" ] && [ "${#GIT_CFG[@]}" -eq 0 ] || return 1
    classify_target
    [ "$TARGET" = scratch ] && [ -n "$TARGET_DIR" ] || return 1
    while [ "$a" -lt "$n" ]; do
        w=${sw[$a]}
        case ${sf[$a]} in *[DUXG]*) return 1 ;; esac
        case $w in
            -u | --set-upstream | -f | --force | --force-with-lease | --force-with-lease=* | -q | --quiet | -v | --verbose | --tags | --follow-tags | --all | --branches | --mirror | --prune | -d | --delete | --atomic | --porcelain | -n | --dry-run | --no-verify) ;;
            -*) return 1 ;;
            *)
                remote=$w
                break
                ;;
        esac
        a=$((a + 1))
    done
    [[ $remote =~ ^[A-Za-z0-9._-]+$ ]] || return 1
    urls=$(gitq -C "$TARGET_DIR" remote get-url --push --all "$remote" 2>/dev/null) || return 1
    [ -n "$urls" ] || return 1
    # The destination is scratch as well: a local path can be the project's
    # own repository, whose branches a forced push would rewrite.
    while IFS= read -r url; do
        case $url in
            /*) ;;
            *) return 1 ;;
        esac
        dest=$(physical "$url") || return 1
        case $dest/ in
            /tmp/* | /private/tmp/* | /var/folders/* | /private/var/folders/*) ;;
            *) return 1 ;;
        esac
        # The path is a repository itself. Where it is not, git tries
        # `<path>.git` beside it, which this hook has not read.
        dcommon=$(common_of "$dest") || return 1
        [ "$dcommon" = "$dest" ] || [ "$dcommon" = "$dest/.git" ] || return 1
        TARGET=real
        classify_dir "$dest"
        [ "$TARGET" = scratch ] || return 1
    done <<<"$urls"
    return 0
}

check_git() {
    local j=$1 n=${#sw[@]} w sub i out help_ok
    GIT_C=() GIT_CF=() GIT_CFG=() GDIR=0 GLOBAL_PLAIN=1
    while [ "$j" -lt "$n" ]; do
        w=${sw[$j]}
        is_dyn "${sf[$j]}" && break
        case $w in
            -C)
                GIT_C[${#GIT_C[@]}]=${sw[$((j + 1))]:-}
                GIT_CF[${#GIT_CF[@]}]=${sf[$((j + 1))]:--}
                GLOBAL_PLAIN=0
                j=$((j + 2))
                ;;
            -c | --config-env)
                GIT_CFG[${#GIT_CFG[@]}]=${sw[$((j + 1))]:-}
                GLOBAL_PLAIN=0
                j=$((j + 2))
                ;;
            --config-env=*)
                GIT_CFG[${#GIT_CFG[@]}]=${w#--config-env=}
                GLOBAL_PLAIN=0
                j=$((j + 1))
                ;;
            --git-dir | --work-tree | --namespace | --super-prefix | --attr-source)
                GDIR=1 GLOBAL_PLAIN=0
                j=$((j + 2))
                ;;
            --git-dir=* | --work-tree=* | --namespace=* | --super-prefix=* | --attr-source=* | --exec-path=* | --bare)
                GDIR=1 GLOBAL_PLAIN=0
                j=$((j + 1))
                ;;
            -p | --paginate | -P | --no-pager | --no-optional-locks | --no-advice) j=$((j + 1)) ;;
            --no-replace-objects | --literal-pathspecs | --glob-pathspecs | --noglob-pathspecs | --icase-pathspecs | --no-lazy-fetch)
                GLOBAL_PLAIN=0
                j=$((j + 1))
                ;;
            --version | -v | --help | -h | --html-path | --man-path | --info-path | --exec-path | --list-cmds=*) return 0 ;;
            -*) deny "git blocked: \`$w\` before the subcommand is not a git option this hook knows, so it cannot tell which command runs or against what. Put the subcommand first." ;;
            *) break ;;
        esac
    done
    i=0
    while [ "$i" -lt "${#GIT_CFG[@]}" ]; do
        if [[ ${GIT_CFG[$i]#*=} =~ $RE_CODE_MENTION ]]; then
            deny "git blocked: \`-c ${GIT_CFG[$i]%%=*}=...\` holds a git or gh command, which git could run as its editor, pager, alias or helper where this hook does not check it. Run that command by itself."
        fi
        i=$((i + 1))
    done
    [ "$j" -lt "$n" ] || return 0
    sub=${sw[$j]}
    if is_dyn "${sf[$j]}"; then
        deny "git blocked: the subcommand is an expansion (\`git \$...\`), so the hook cannot tell a push or a config write from a read. Spell the git subcommand literally."
    fi
    case $sub in
        credential | credential-*) deny "git $sub blocked: it reads or writes stored credentials. $OPERATOR" ;;
        send-pack | http-push) deny "git $sub blocked: it is push plumbing that skips the checks on \`git push\`. Use \`git push <remote> <branch>\`." ;;
    esac
    case $GIT_BUILTINS in
        *" $sub "*) ;;
        *) deny "git $sub blocked: \`$sub\` is not a git command this hook knows, so it is an alias or an external \`git-$sub\` program whose effect the hook cannot read. Spell out the underlying git command." ;;
    esac
    # Git verbs that run a command of the caller's choosing: a git or gh
    # command handed to one is read by no check here.
    case $sub in
        rebase)
            i=$((j + 1))
            while [ "$i" -lt "$n" ]; do
                w=${sw[$i]}
                case $w in
                    -x | --exec) w=${sw[$((i + 1))]:-} ;;
                    --exec=*) w=${w#--exec=} ;;
                    -x?*) w=${w#-x} ;;
                    *) w='' ;;
                esac
                if [[ $w =~ $RE_CODE_MENTION ]]; then
                    deny "git rebase blocked: \`--exec\` hands git or gh to a shell this hook does not read. Run that command as its own Bash call."
                fi
                i=$((i + 1))
            done
            ;;
        bisect | submodule | filter-branch | for-each-repo | difftool | mergetool)
            i=$((j + 1))
            while [ "$i" -lt "$n" ]; do
                w=${sw[$i]}
                if [[ $w =~ $RE_CODE_MENTION ]] || path_cmd "$i"; then
                    deny "git $sub blocked: it is handed a git or gh command to run, where this hook cannot check it. Run that command as its own Bash call."
                fi
                i=$((i + 1))
            done
            ;;
        subtree)
            has_word $((j + 1)) push && deny "git subtree push blocked: it pushes a branch this hook cannot check. Split the subtree to a local branch, then push it with \`git push <remote> <branch>\`."
            ;;
    esac
    case $sub in
        push)
            if scratch_local_push $((j + 1)); then
                check_git_loose "$sub" $((j + 1))
                return 0
            fi
            [ "$SOLE" = 1 ] || deny "git push blocked: run the push as its own Bash call with nothing else in it, as in \`git push -u origin <branch>\`. A push is accepted only in that form, the one this hook can check against the repository it runs in."
            transport_common "git push" $((j + 1))
            check_push $((j + 1))
            return 0
            ;;
        fetch | ls-remote)
            if [ "$MAYOUT" = 1 ]; then
                transport_common "git $sub" $((j + 1))
                check_fetch "$sub" $((j + 1))
                return 0
            fi
            ;;
    esac
    if [ "$MAYOUT" = 1 ]; then
        out=''
        w=${sw[$((j + 1))]:-}
        is_dyn "${sf[$((j + 1))]:--}" && w=''
        case $sub in
            pull | clone) out=$sub ;;
            remote) case $w in update | prune) out="remote $w" ;; esac ;;
            worktree) case $w in add | remove | move | prune) out="worktree $w" ;; esac ;;
            config) case $w in set | unset) out="config $w" ;; esac ;;
            submodule) case $w in update | init | sync) out="submodule $w" ;; esac ;;
            branch)
                i=$((j + 1))
                while [ "$i" -lt "$n" ]; do
                    case ${sw[$i]} in
                        -u | -u?* | --set-upstream-to | --set-upstream-to=* | --unset-upstream) out=branch ;;
                    esac
                    i=$((i + 1))
                done
                ;;
        esac
        if [ -n "$out" ]; then
            # A lone help flag prints usage and touches nothing. `--help`
            # right after the verb is not one: git turns it into `git help
            # <verb>`, which runs the `man.<tool>.cmd` the config names.
            i=0 help_ok=1
            while [ "$i" -lt "${#rw[@]}" ]; do
                case ${rf[$i]} in
                    *P*) fd_dup "${rw[$i]}" || help_ok=0 ;;
                    *) help_ok=0 ;;
                esac
                i=$((i + 1))
            done
            if [ "$help_ok" = 1 ] && [ "${#AS_NAME[@]}" -eq 0 ] && [ "$GLOBAL_PLAIN" = 1 ] && [ -z "$ENV_TAINT" ] && ! is_dyn "${sf[$((n - 1))]}"; then
                case "$((n - j)) $out" in
                    '2 pull' | '2 clone')
                        case ${sw[$((n - 1))]} in -h) return 0 ;; esac
                        ;;
                    '3 '*\ *)
                        case ${sw[$((n - 1))]} in -h | --help) return 0 ;; esac
                        ;;
                esac
            fi
            out_common "git $out" $((j + 1))
            case $out in
                pull) check_pull $((j + 1)) ;;
                clone) check_clone $((j + 1)) ;;
                branch) check_branch_out $((j + 1)) ;;
                remote\ *) check_remote_out "$w" $((j + 2)) ;;
                worktree\ *) check_worktree_out "$w" $((j + 2)) ;;
                config\ *) check_config_out "$w" $((j + 2)) ;;
                submodule\ *) check_submodule_out "$w" $((j + 2)) ;;
            esac
            return 0
        fi
    fi
    check_git_loose "$sub" $((j + 1))
}

# --- gh. ------------------------------------------------------------------------

# require_static <what> <from> <value-flags>: an unquoted expansion is refused;
# a quoted one is accepted only as the value of a listed flag.
require_static() {
    local what=$1 i=$2 vf=$3 w f prev
    while [ "$i" -lt "${#sw[@]}" ]; do
        w=${sw[$i]}
        f=${sf[$i]}
        case $f in
            *[UX]*) deny "$what blocked: an unquoted expansion can add flags this hook cannot read. Spell the flags literally and quote any variable value." ;;
            *D*)
                prev=${sw[$((i - 1))]}
                if is_dyn "${sf[$((i - 1))]}"; then prev=''; fi
                case $vf in
                    *" $prev "*) ;;
                    *)
                        case $vf in
                            *" ${w%%=*} "*) ;;
                            *) deny "$what blocked: a variable sits where a flag could be. Spell the flags literally; a quoted variable is accepted only as a flag's value." ;;
                        esac
                        ;;
                esac
                ;;
        esac
        i=$((i + 1))
    done
}

has_word() {
    local i=$1 pat=$2
    while [ "$i" -lt "${#sw[@]}" ]; do
        if ! is_dyn "${sf[$i]}"; then
            # shellcheck disable=SC2254
            case ${sw[$i]} in $pat) return 0 ;; esac
        fi
        i=$((i + 1))
    done
    return 1
}

# REST paths a write may not touch at all: the pull-request merge, and the
# access controls of a repository, an organization or the account.
RE_REST_BLOCK='^(repos/[^/]+/[^/]+/(pulls/[^/]+/merge|transfer|branches/.+|rulesets(/.*)?|collaborators(/.*)?|invitations(/.*)?|keys(/.*)?|actions/permissions(/.*)?|environments(/.*)?|tags/protection(/.*)?)|orgs/[^/]+/(rulesets|members|memberships|outside_collaborators|teams|invitations|actions/permissions)(/.*)?|teams/.*|enterprises/.*|scim/.*|user/(keys|gpg_keys|ssh_signing_keys|installations)(/.*)?|(authorizations|applications|app|installation)(/.*)?)$'
# A write under `orgs/<org>` is refused unless its path is on this short list
# of ordinary administration: the organization's own settings, roles,
# security managers and token requests are access controls.
RE_REST_ORG='^orgs/[^/]+(/(.*))?$'
RE_REST_ORG_OK='^(repos|(actions|dependabot|codespaces)/(secrets|variables)(/.*)?|issue-types(/.*)?|properties/values)$'
api_org_blocked() {
    [[ $1 =~ $RE_REST_ORG ]] || return 1
    [[ ${BASH_REMATCH[2]} =~ $RE_REST_ORG_OK ]] && return 1
    return 0
}
# REST paths that write a branch. Each is allowed when the branch it names is
# a literal one that is not a default branch.
RE_REST_REFS='^repos/([^/]+)/([^/]+)/git/refs(/(.*))?$'
RE_REST_BRANCH='^repos/([^/]+)/([^/]+)/(contents/.+|merge-upstream)$'
RE_REST_MERGES='^repos/([^/]+)/([^/]+)/merges$'
RE_REST_REPO='^repos/[^/]+/[^/]+$'
RE_REPO_FIELD='^(default_branch|visibility|private|allow_forking|security_and_analysis)([^a-z_]|$)'
RE_SLUG='^[a-z0-9._-]+$'
# The words a variable in a write endpoint is tried as, and the segments
# that mark `repos/$R/<segment>` as OWNER/REPO held in one variable.
REST_CANDS='x merge merges merge-upstream transfer git refs contents branches protection rulesets collaborators invitations keys members teams pulls/1/merge git/refs/heads/main branches/main/protection contents/x actions/permissions environments/x tags/protection'
REST_RESOURCES=' actions assignees autolinks branches check-runs check-suites code-scanning collaborators comments commits compare contents deployments dispatches environments forks git hooks invitations issues keys labels merge-upstream merges milestones notifications pages pulls releases rulesets statuses subscription tags topics transfer '
RE_GQL_BLOCK='(^|[^a-z0-9_])(mergepullrequest|enablepullrequestautomerge|mergebranch|createcommitonbranch|updaterefs?|createref|deleteref|enqueuepullrequest|(create|update|delete)branchprotectionrule|(create|update|delete)repositoryruleset|updaterepository|updateteamsrepository|addenterpriseadmin|updateenterprise[a-z]*|updateorganization[a-z]*)([^a-z0-9_]|$)'

check_gh_api() {
    local i=$1 n=${#sw[@]} w f method='' endpoint='' endf='' have_end=0 field=0 input=0 kv kvf e lq found=0
    local shown gql pat base alt seg cands c p tail k prev
    local fields=() fieldf=()
    # An unquoted expansion may split into several words and so add a method,
    # a header or a field. It is accepted only as a field's value, where the
    # request is a write already and is checked as one.
    k=$i
    while [ "$k" -lt "$n" ]; do
        case ${sf[$k]} in
            *[UX]*)
                prev=''
                [ "$k" -gt "$i" ] && ! is_dyn "${sf[$((k - 1))]}" && prev=${sw[$((k - 1))]}
                case $prev in
                    -f | -F | --field | --raw-field) [[ ${sw[$k]} =~ ^[A-Za-z_][A-Za-z0-9_.-]*= ]] || prev='' ;;
                    *) prev='' ;;
                esac
                [ -n "$prev" ] || deny "gh api blocked: an unquoted expansion can add a method, header or field this hook cannot read. Quote it."
                ;;
        esac
        k=$((k + 1))
    done
    while [ "$i" -lt "$n" ]; do
        w=${sw[$i]}
        f=${sf[$i]}
        case $f in *[UX]*) [ "${w:0:1}" != $'\037' ] || deny "gh api blocked: an unquoted expansion can add a method, header or field this hook cannot read. Quote it." ;; esac
        if [ "${w:0:1}" = $'\037' ]; then
            if [ "$have_end" = 1 ]; then
                deny "gh api blocked: a variable sits where a flag could be. Spell the flags literally."
            fi
            endpoint=$w endf=$f have_end=1
            i=$((i + 1))
            continue
        fi
        case $w in
            -X | --method)
                method=${sw[$((i + 1))]:-}
                is_dyn "${sf[$((i + 1))]:--}" && deny "gh api blocked: the HTTP method is a variable. Spell it literally."
                i=$((i + 2))
                continue
                ;;
            --method=*) method=${w#--method=} ;;
            -X?*) method=${w#-X} ;;
            -f | -F | --field | --raw-field)
                field=1
                fields[${#fields[@]}]=${sw[$((i + 1))]:-}
                fieldf[${#fieldf[@]}]=${sf[$((i + 1))]:--}
                i=$((i + 2))
                continue
                ;;
            --field=* | --raw-field=*)
                field=1
                fields[${#fields[@]}]=${w#*=}
                fieldf[${#fieldf[@]}]=$f
                ;;
            -f?* | -F?*)
                field=1
                fields[${#fields[@]}]=${w#-?}
                fieldf[${#fieldf[@]}]=$f
                ;;
            --input)
                input=1
                i=$((i + 2))
                continue
                ;;
            --input=*) input=1 ;;
            -H | --header)
                lq=$(lower "${sw[$((i + 1))]:-}")
                case $lq in *method-override*) deny "gh api blocked: a method-override header hides the real HTTP method." ;; esac
                i=$((i + 2))
                continue
                ;;
            -H?* | --header=*)
                lq=$(lower "$w")
                case $lq in *method-override*) deny "gh api blocked: a method-override header hides the real HTTP method." ;; esac
                ;;
            --hostname | --hostname=*) deny "gh api blocked: \`--hostname\` sends the request, and the token, to another host. $OPERATOR" ;;
            -q | --jq | -t | --template | --cache | -p | --preview)
                i=$((i + 2))
                continue
                ;;
            --jq=* | --template=* | --cache=* | --preview=* | -q?* | -t?* | -p?*) ;;
            -i | --include | --paginate | --silent | --slurp | --verbose | --help) ;;
            -*) deny "gh api blocked: \`$w\` is not a gh api flag this hook knows, so it cannot tell what the request does." ;;
            *)
                if [ "$have_end" = 0 ]; then
                    endpoint=$w endf=$f have_end=1
                fi
                ;;
        esac
        i=$((i + 1))
    done
    [ "$have_end" = 1 ] || return 0
    method=$(printf '%s' "$method" | LC_ALL=C tr 'a-z' 'A-Z')
    if [ -z "$method" ]; then
        method=GET
        [ "$field" = 0 ] && [ "$input" = 0 ] || method=POST
    fi
    e=$endpoint
    case $e in
        https://api.github.com/*) e=${e#https://api.github.com/} ;;
        *://*) deny "gh api blocked: the endpoint names a host other than api.github.com. $OPERATOR" ;;
    esac
    # The request path is what is left without the fragment, the query string
    # and repeated or trailing slashes.
    e=${e%%\#*}
    e=${e%%\?*}
    while :; do
        case $e in
            *//*) e=${e//\/\//\/} ;;
            *) break ;;
        esac
    done
    e=${e#/}
    e=${e%/}
    e=$(lower "$e")
    shown=${e//$'\037'/\$...}
    case $e in *%* | . | .. | ./* | ../* | */./* | */../* | */. | */..) deny "gh api blocked: the endpoint carries \`%\` or a \`.\` or \`..\` path segment, which can spell a different path than the one this hook reads." ;; esac
    # GitHub serves a repository and an organization by numeric id too.
    case $e in
        repositories/*)
            e=${e#repositories/}
            e="repos/~id/$e"
            ;;
        organizations/*) e="orgs/${e#organizations/}" ;;
    esac

    # GraphQL. gql is 1 for the literal endpoint and 2 for an endpoint whose
    # variables could spell it.
    gql=0
    case $e in
        graphql) gql=1 ;;
        *$'\037'*)
            pat=${e//$'\037'/*}
            # shellcheck disable=SC2254
            case graphql in $pat) [ "$method" = GET ] || gql=2 ;; esac
            ;;
    esac
    if [ "$gql" != 0 ] && [ "$input" = 1 ]; then
        deny "gh api graphql blocked: the document comes from \`--input\`, which this hook does not read. Pass it as \`-f query='...'\`."
    fi
    i=0
    while [ "$i" -lt "${#fields[@]}" ]; do
        kv=${fields[$i]}
        kvf=${fieldf[$i]}
        i=$((i + 1))
        case $kv in
            query=*) ;;
            $'\037'*)
                [ "$gql" = 0 ] || deny "gh api graphql blocked: a field is a variable, so the hook cannot find the document. Pass it as \`-f query='...'\` with literal text."
                continue
                ;;
            *) continue ;;
        esac
        found=1
        if [ "$gql" != 0 ]; then
            is_dyn "$kvf" && deny "gh api graphql blocked: the document carries a shell expansion, so the hook cannot read its mutations. Single-quote the document and pass values as GraphQL variables (\`-f name=value\`)."
            case $kv in query=@*) deny "gh api graphql blocked: the document is read from a file, which this hook does not read. Pass it as \`-f query='...'\`." ;; esac
        fi
        lq=$(lower "$kv")
        case $lq in
            *mutation*)
                if [[ $lq =~ $RE_GQL_BLOCK ]]; then
                    deny "gh api graphql blocked: the \`${BASH_REMATCH[2]}\` mutation merges a pull request, writes a branch ref, or changes repository access controls. $OPERATOR"
                fi
                ;;
        esac
    done
    if [ "$gql" = 1 ]; then
        [ "$found" = 1 ] || deny "gh api graphql blocked: no literal \`query=\` field, so the hook cannot read the document."
        return 0
    fi

    [ "$method" != GET ] || return 0
    if [ "${endpoint:0:1}" = $'\037' ]; then
        deny "gh api blocked: a $method request to an endpoint that is entirely a variable cannot be checked. Start the endpoint with its literal path, as in \"repos/\$owner/\$repo/issues/\$n/comments\"."
    fi
    case $endf in *G*) deny "gh api blocked: the endpoint of this $method request carries an unquoted glob or brace list, which the shell may turn into another path. Quote it." ;; esac
    i=0
    while [ "$i" -lt "${#fields[@]}" ]; do
        lq=$(lower "${fields[$i]}")
        if [[ $lq =~ $RE_BOT_MERGE ]]; then
            deny "gh api blocked: a field carries a bot command that merges the pull request. Merging is the operator's action. $OPERATOR"
        fi
        i=$((i + 1))
    done

    case $e in
        *$'\037'*)
            # `repos/$A/$B` reads two ways: OWNER and REPO, or OWNER/REPO and
            # a path. Both are tried.
            base=$e
            alt=''
            case $base in
                repos/$'\037'/$'\037')
                    base=repos/x/x
                    alt=repos/x/x/$'\037'
                    ;;
                repos/$'\037'/$'\037'/*) base=repos/x/x${base#repos/?/?} ;;
                repos/$'\037') base=repos/x/x ;;
                repos/$'\037'/*)
                    seg=${base#repos/?/}
                    seg=${seg%%/*}
                    case $REST_RESOURCES in
                        *" $seg "*) base=repos/x/x${base#repos/?} ;;
                        *) base=repos/x${base#repos/?} ;;
                    esac
                    ;;
            esac
            cands=$REST_CANDS
            [ "$method" != PUT ] || cands="$cands 1/merge"
            for c in $cands; do
                for p in "${base//$'\037'/$c}" "${alt//$'\037'/$c}"; do
                    [ -n "$p" ] || continue
                    if [[ $p =~ $RE_REST_BLOCK ]] || [[ $p =~ $RE_REST_REFS ]] || [[ $p =~ $RE_REST_BRANCH ]] || [[ $p =~ $RE_REST_MERGES ]] || { [ "$c" = x ] && api_org_blocked "$p"; }; then
                        deny "gh api blocked: a variable in the endpoint of this $method request ($shown) could spell a path that merges a pull request, writes a branch, or changes protection, keys or access. Spell the endpoint literally."
                    fi
                    if [[ $p =~ $RE_REST_REPO ]]; then
                        api_repo_fields
                    fi
                done
            done
            return 0
            ;;
    esac
    if [[ $e =~ $RE_REST_BLOCK ]]; then
        deny "gh api blocked: $method $shown merges a pull request, or changes branch protection, rulesets, keys or access. $OPERATOR"
    fi
    if api_org_blocked "$e"; then
        deny "gh api blocked: $method $shown writes an organization's settings, roles, membership or access. $OPERATOR"
    fi
    if [[ $e =~ $RE_REST_REFS ]]; then
        tail=${BASH_REMATCH[4]}
        api_slug "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        case $tail in
            '')
                api_named_branch ref "creating a ref"
                case $NB in
                    refs/tags/*) return 0 ;;
                    refs/heads/*) NB=${NB#refs/heads/} ;;
                    *) deny "gh api blocked: \`ref=$NB\` is outside refs/heads and refs/tags. $OPERATOR" ;;
                esac
                ;;
            tags/*) return 0 ;;
            heads/?*) NB=${tail#heads/} ;;
            *) deny "gh api blocked: $method $shown writes a ref outside refs/heads and refs/tags. $OPERATOR" ;;
        esac
        api_not_default "$method $shown"
        return 0
    fi
    if [[ $e =~ $RE_REST_BRANCH ]]; then
        seg=${BASH_REMATCH[3]%%/*}
        api_slug "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        api_named_branch branch "a write through \`$seg\`"
        api_not_default "$method $shown"
        return 0
    fi
    if [[ $e =~ $RE_REST_MERGES ]]; then
        api_slug "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        api_named_branch base "a branch merge"
        api_not_default "$method $shown"
        return 0
    fi
    if [[ $e =~ $RE_REST_REPO ]]; then
        api_repo_fields
    fi
    return 0
}

# The helpers below read check_gh_api's locals.

# api_slug <owner> <repo>: sets REPOS for the default-branch lookup, or denies.
api_slug() {
    if ! [[ $1 =~ $RE_SLUG ]] || ! [[ $2 =~ $RE_SLUG ]]; then
        deny "gh api blocked: $method $shown writes a branch, and the hook reads the repository's default branch to check it. Name the repository literally as \`repos/<owner>/<repo>\`."
    fi
    REPOS=("$1/$2")
}

# api_named_branch <field> <what>: sets NB to the literal value of the field
# that names the branch the request writes, or denies.
api_named_branch() {
    local key=$1 what=$2 k=0 kv
    NB=''
    [ "$input" = 0 ] || deny "gh api blocked: $what takes its branch from \`--input\`, which this hook does not read. Pass it as \`-f $key=<branch>\`."
    while [ "$k" -lt "${#fields[@]}" ]; do
        kv=${fields[$k]}
        case $kv in
            $'\037'*) deny "gh api blocked: a field of this $method request is a variable, so the hook cannot tell which branch it writes. Spell \`-f $key=<branch>\` literally." ;;
            "$key="*)
                is_dyn "${fieldf[$k]}" && deny "gh api blocked: \`$key=\` is a variable, so the hook cannot tell which branch this $method request writes. Spell the branch literally."
                # gh keeps one of two values for a field, and which one
                # depends on the flag each was passed with.
                [ -z "$NB" ] || [ "$NB" = "${kv#*=}" ] || deny "gh api blocked: \`$key=\` is given twice with different values, so the hook cannot tell which branch this $method request writes. Pass it once."
                NB=${kv#*=}
                ;;
        esac
        k=$((k + 1))
    done
    [ -n "$NB" ] || deny "gh api blocked: $what without a literal \`-f $key=<branch>\` lands on the default branch. $OPERATOR"
    [[ $NB =~ ^[A-Za-z0-9._/-]+$ ]] || deny "gh api blocked: \`$key=$NB\` is not a branch name this hook can read."
}

# api_not_default <what>: denies when NB is a default branch of REPOS.
api_not_default() {
    [[ $NB =~ ^[A-Za-z0-9._/-]+$ ]] || deny "gh api blocked: $1 names a branch this hook cannot read. Spell it literally."
    if is_default "$NB"; then
        deny "gh api blocked: $1 writes \`$NB\`, a default branch (main, master, or the repository's default on GitHub). $OPERATOR"
    fi
}

# api_repo_fields: a write to the repository itself may not change its default
# branch, who can see or fork it, or its push protection.
api_repo_fields() {
    local k=0 kv
    [ "$method" != DELETE ] || return 0
    [ "$input" = 0 ] || deny "gh api blocked: $method $shown edits repository settings from \`--input\`, which this hook does not read. Pass the settings as \`-f name=value\`."
    while [ "$k" -lt "${#fields[@]}" ]; do
        kv=$(lower "${fields[$k]}")
        case $kv in $'\037'*) deny "gh api blocked: a field of $method $shown is a variable, so the hook cannot tell which repository setting it changes. Spell the field name literally." ;; esac
        if [[ $kv =~ $RE_REPO_FIELD ]]; then
            deny "gh api blocked: $method $shown sets \`${kv%%[=\[]*}\`, which changes the default branch, who can see or fork the repository, or its push protection. $OPERATOR"
        fi
        k=$((k + 1))
    done
}

RE_BOT_MERGE='@dependabot[[:space:]]+(squash[[:space:]]+and[[:space:]]+)?merge|bors[[:space:]]+(r\+|r=|merge)|@mergify(io)?[[:space:]]+(queue|merge)|(^|[[:space:]])/merge([[:space:]]|$)'

check_gh() {
    local s=$1 n=${#sw[@]} c1 c2 c3 i w a name val lq dest np rp dp
    [ "$s" -lt "$n" ] || return 0
    c1=${sw[$s]}
    if is_dyn "${sf[$s]}"; then
        deny "gh blocked: the command is an expansion (\`gh \$...\`), so the hook cannot tell a merge from a read. Spell the gh command literally."
    fi
    case $c1 in
        --help | -h | --version | help | version) return 0 ;;
        -*) deny "gh blocked: \`$c1\` before the command is not a flag this hook knows." ;;
    esac
    case $GH_COMMANDS in
        *" $c1 "*) ;;
        *) deny "gh $c1 blocked: \`$c1\` is not a built-in gh command, so it is an alias or an extension whose effect the hook cannot read. Spell out the built-in command." ;;
    esac
    i=0
    while [ "$i" -lt "${#AS_NAME[@]}" ]; do
        name=${AS_NAME[$i]}
        val=${AS_VAL[$i]}
        case $name in
            NO_COLOR | CLICOLOR | CLICOLOR_FORCE | GH_FORCE_TTY | GH_PROMPT_DISABLED | GH_NO_UPDATE_NOTIFIER | GH_NO_EXTENSION_UPDATE_NOTIFIER | GH_SPINNER_DISABLED | TERM | COLUMNS | LINES | LC_ALL | LANG | TZ) ;;
            GH_PAGER | PAGER)
                case $val in '' | cat) ;; *) deny "gh blocked: \`$name=\` names a program gh would run. Only \`$name=cat\` or an empty value is accepted." ;; esac
                ;;
            GH_REPO)
                is_dyn "${AS_FL[$i]}" && deny "gh blocked: \`GH_REPO=\` is a variable. Use \`--repo\` with a literal value."
                ;;
            *) deny "gh blocked: the \`$name=\` prefix can change the token, host or config gh uses. Run gh without it. $OPERATOR" ;;
        esac
        i=$((i + 1))
    done
    [ -z "$ENV_TAINT_GH" ] || deny "gh blocked: the call sets \`$ENV_TAINT_GH\` first, which can change the token, host or config gh uses. $OPERATOR"
    a=$((s + 1))
    c2=''
    if [ "$c1" = api ]; then
        check_gh_api "$a"
        return 0
    fi
    if [ "$a" -lt "$n" ]; then
        c2=${sw[$a]}
        # A command group takes its subcommand as the next word. A flag there
        # (`gh pr -R o/r merge 5`), an expansion or a brace list would put the
        # subcommand where no check below looks for it.
        case " $GH_LEAVES " in
            *" $c1 "*) ;;
            *)
                if is_dyn "${sf[$a]}"; then
                    deny "gh $c1 blocked: the subcommand is an expansion, so the hook cannot tell which \`gh $c1\` command runs. Spell it literally."
                fi
                case ${sf[$a]} in *G*) deny "gh $c1 blocked: the subcommand is a glob or brace list, so the hook cannot tell which \`gh $c1\` command runs. Spell it literally." ;; esac
                case $c2 in
                    --help) return 0 ;;
                    -*) deny "gh $c1 blocked: \`$c2\` sits where the subcommand goes, so the hook cannot tell which \`gh $c1\` command runs. Put the subcommand directly after \`gh $c1\` and the flags after it." ;;
                esac
                ;;
        esac
    fi
    c3=${sw[$((a + 1))]:-}
    # gh's own short names for a subcommand run the same code as the long one.
    case $c2 in
        new) c2=create ;;
        ls) c2=list ;;
        co) [ "$c1" != pr ] || c2=checkout ;;
    esac
    case $c3 in
        new) c3=create ;;
        ls) c3=list ;;
    esac
    case $c2 in
        --help) return 0 ;;
        -*) ;;
        *)
            if [ "$c3" = --help ] && ! is_dyn "${sf[$((a + 1))]:--}"; then
                return 0
            fi
            ;;
    esac
    case $c1 in
        co)
            c1=pr
            c2=checkout
            a=$s
            ;;
    esac
    # A command that publishes or deletes on GitHub is judged by the permission
    # classifier only when the call leaves the sandbox, which a call holding
    # anything else does not.
    case "$c1 $c2" in
        'gist create' | 'gist edit' | 'repo create' | 'repo fork' | 'repo delete' | 'release create' | 'release upload' | 'release delete')
            if [ "$SOLE" != 1 ] || [ "$s" != 1 ] || [ "${sw[0]}" != gh ] || is_dyn "${sf[0]}"; then
                deny "gh $c1 $c2 blocked: run it as its own Bash call that starts with \`gh\` and holds nothing else (no wrapper, prefix, pipe, \`&&\`, substitution or subshell). Only a call of that form is known to leave the sandbox, where the permission classifier judges a public or irreversible change."
            fi
            ;;
    esac
    case "$c1 $c2" in
        'pr merge')
            i=$((a + 1))
            w=0
            while [ "$i" -lt "$n" ]; do
                is_dyn "${sf[$i]}" && w=1
                case ${sw[$i]} in
                    --disable-auto | -R | --repo | --repo=*) ;;
                    -*) w=1 ;;
                esac
                i=$((i + 1))
            done
            if [ "$w" = 1 ] || ! has_word $((a + 1)) '--disable-auto'; then
                deny "gh pr merge blocked: merging a pull request is the operator's action, \`--auto\` and \`--admin\` included. Only \`gh pr merge <pr> --disable-auto\` is accepted. $OPERATOR"
            fi
            ;;
        'pr create')
            if ! has_word $((a + 1)) '--head' && ! has_word $((a + 1)) '--head=*' && ! has_word $((a + 1)) '-H' && ! has_word $((a + 1)) '-H?*'; then
                deny "gh pr create blocked: without \`--head\` gh may push the current branch itself, to a remote this hook has not checked. Push first with \`git push -u <remote> <branch>\` as its own Bash call, then pass \`--head <branch>\`."
            fi
            ;;
        'pr checkout')
            has_word $((a + 1)) '--recurse-submodules' && deny "gh pr checkout blocked: \`--recurse-submodules\` runs git inside each submodule with config this hook has not read."
            [ "$MAYOUT" = 0 ] || repo_trust "gh pr checkout"
            ;;
        'pr comment' | 'pr review' | 'issue comment')
            i=$((a + 1))
            while [ "$i" -lt "$n" ]; do
                lq=$(lower "${sw[$i]}")
                if [[ $lq =~ $RE_BOT_MERGE ]]; then
                    deny "gh $c1 $c2 blocked: the text carries a bot command that merges the pull request. Merging is the operator's action. $OPERATOR"
                fi
                i=$((i + 1))
            done
            ;;
        'repo sync')
            require_static "gh repo sync" $((a + 1)) ' -b --branch -s --source '
            i=$((a + 1))
            dest='' w=''
            while [ "$i" -lt "$n" ]; do
                case ${sw[$i]} in
                    -b | --branch)
                        w=${sw[$((i + 1))]:-}
                        is_dyn "${sf[$((i + 1))]:--}" && w=$'\037'
                        i=$((i + 1))
                        ;;
                    --branch=*) w=${sw[$i]#--branch=} ;;
                    -s | --source) i=$((i + 1)) ;;
                    --source=* | --force) ;;
                    -*) deny "gh repo sync blocked: \`${sw[$i]}\` is not a flag this hook knows." ;;
                    *) [ -n "$dest" ] || dest=${sw[$i]} ;;
                esac
                i=$((i + 1))
            done
            if [ -n "$dest" ]; then
                dest=${dest#github.com/}
                [[ $dest =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || deny "gh repo sync blocked: \`$dest\` is not an OWNER/REPO this hook can check."
                [ -n "$w" ] && [[ $w =~ ^[A-Za-z0-9._/-]+$ ]] || deny "gh repo sync blocked: syncing a repository on GitHub rewrites its default branch unless \`--branch\` names another one literally. $OPERATOR"
                REPOS=("$dest")
                if is_default "$w"; then
                    deny "gh repo sync blocked: \`$w\` is a default branch of $dest, and the sync writes to it on GitHub. $OPERATOR"
                fi
            elif [ "$MAYOUT" = 1 ]; then
                repo_trust "gh repo sync"
            fi
            ;;
        'repo create')
            require_static "gh repo create" $((a + 1)) ' -d --description -h --homepage -g --gitignore -l --license -t --team -p --template -s --source -r --remote '
            i=$((a + 1))
            while [ "$i" -lt "$n" ]; do
                case ${sw[$i]} in
                    --push=false) ;;
                    --push=*) deny "gh repo create blocked: \`--push\` pushes the local commits to the new repository's default branch. Create the repository without it, then push a named branch. $OPERATOR" ;;
                esac
                i=$((i + 1))
            done
            has_word $((a + 1)) '--push' && deny "gh repo create blocked: \`--push\` pushes the local commits to the new repository's default branch. Create the repository without it, then push a named branch. $OPERATOR"
            ;;
        'repo edit')
            require_static "gh repo edit" $((a + 1)) ' -d --description -h --homepage --add-topic --remove-topic -R --repo '
            i=$((a + 1))
            while [ "$i" -lt "$n" ]; do
                w=${sw[$i]}
                i=$((i + 1))
                is_dyn "${sf[$((i - 1))]}" && continue
                case $w in
                    -d | --description | -h | --homepage | --add-topic | --remove-topic | -R | --repo) i=$((i + 1)) ;;
                    --default-branch | --default-branch=* | --visibility | --visibility=* | --accept-visibility-change-consequences | --accept-visibility-change-consequences=* | --allow-forking | --allow-forking=* | --enable-secret-scanning* | --enable-advanced-security*)
                        deny "gh repo edit blocked: \`${w%%=*}\` changes the default branch, who can see or fork the repository, or its push protection. $OPERATOR"
                        ;;
                esac
            done
            ;;
        'repo fork')
            require_static "gh repo fork" $((a + 1)) ' --fork-name --org --remote-name '
            if has_word $((a + 1)) '--remote' || has_word $((a + 1)) '--remote=*' || has_word $((a + 1)) '--remote-name*'; then
                deny "gh repo fork blocked: \`--remote\` rewrites this repository's remotes. Fork without it. $OPERATOR"
            fi
            ;;
        'repo set-default')
            require_static "gh repo set-default" $((a + 1)) ' '
            if ! has_word $((a + 1)) '--view' && ! has_word $((a + 1)) '-v'; then
                deny "gh repo set-default blocked: it changes which repository every later gh command in this checkout targets. Pass \`--repo\` on the command instead. $OPERATOR"
            fi
            ;;
        'repo deploy-key')
            [ "$c3" = list ] || deny "gh repo deploy-key blocked: adding or deleting a deploy key changes who can push. Only \`list\` is accepted. $OPERATOR"
            ;;
        'auth ' | 'ssh-key ' | 'gpg-key ' | 'alias ' | 'extension ' | 'extensions ' | 'ext ' | 'config ')
            # The bare group prints its help.
            return 0
            ;;
        'auth status')
            require_static "gh auth status" $((a + 1)) ' -h --hostname --jq --json --template '
            i=$((a + 1))
            while [ "$i" -lt "$n" ]; do
                w=${sw[$i]}
                case $w in
                    --show-token*) deny "gh auth status blocked: \`--show-token\` prints the token. $OPERATOR" ;;
                    --*) ;;
                    -*t*) [ "${sw[$((i - 1))]}" = -h ] || deny "gh auth status blocked: \`-t\` prints the token. $OPERATOR" ;;
                esac
                i=$((i + 1))
            done
            ;;
        auth\ *)
            deny "gh auth ${c2:-<command>} blocked: signing in or out, switching accounts, changing scopes and printing the token change or expose the credential the operator set up. Only \`gh auth status\` is accepted. $OPERATOR"
            ;;
        ssh-key\ * | gpg-key\ *)
            [ "$c2" = list ] || deny "gh $c1 ${c2:-<command>} blocked: adding or deleting an account key changes who can sign in and sign commits. Only \`list\` is accepted. $OPERATOR"
            ;;
        alias\ *)
            [ "$c2" = list ] || deny "gh alias ${c2:-<command>} blocked: an alias gives a command a name this hook cannot read through. Only \`list\` is accepted. $OPERATOR"
            ;;
        extension\ * | extensions\ * | ext\ *)
            case $c2 in
                list | search) ;;
                *) deny "gh extension ${c2:-<command>} blocked: an extension is a program gh runs with the operator's token. Only \`list\` and \`search\` are accepted. $OPERATOR" ;;
            esac
            ;;
        config\ *)
            case $c2 in
                get | list | clear-cache) ;;
                *) deny "gh config ${c2:-<command>} blocked: it changes the host, protocol or program gh uses. $OPERATOR" ;;
            esac
            ;;
    esac
    case "$c1 $c2" in
        'repo clone' | 'repo fork')
            i=$((a + 1))
            w=0
            while [ "$i" -lt "$n" ]; do
                if [ "$w" = 1 ]; then
                    is_dyn "${sf[$i]}" && deny "gh $c1 $c2 blocked: a variable after \`--\` is passed to git clone as a flag this hook cannot read."
                    case ${sw[$i]} in
                        --depth | -b | --branch | --origin | -o) i=$((i + 1)) ;;
                        --depth=* | --branch=* | --origin=* | --single-branch | --no-single-branch | --no-tags | --bare | --filter=* | -q | --quiet | --no-checkout | -n | --sparse | --progress) ;;
                        *) deny "gh $c1 $c2 blocked: \`${sw[$i]}\` after \`--\` is passed to git clone and is not on this hook's allowlist of clone flags. $OPERATOR" ;;
                    esac
                elif [ "${sw[$i]}" = -- ] && ! is_dyn "${sf[$i]}"; then
                    w=1
                fi
                i=$((i + 1))
            done
            # gh runs outside the sandbox, so the directory it clones into
            # answers to the same rule as `git clone`.
            if [ "$c2" = clone ] && [ "$MAYOUT" = 1 ]; then
                i=$((a + 1)) np=0 rp='' dp=''
                while [ "$i" -lt "$n" ]; do
                    if [ "${sw[$i]}" = -- ] && ! is_dyn "${sf[$i]}"; then
                        break
                    fi
                    case ${sw[$i]} in
                        -u | --upstream-remote-name) i=$((i + 1)) ;;
                        -*) ;;
                        *)
                            np=$((np + 1))
                            if [ "$np" -eq 1 ]; then
                                rp=${sw[$i]}
                                is_dyn "${sf[$i]}" && rp=x
                            elif [ "$np" -eq 2 ]; then
                                is_dyn "${sf[$i]}" && deny "gh repo clone blocked: the directory must be a plain literal so the destination can be read."
                                dp=${sw[$i]}
                            fi
                            ;;
                    esac
                    i=$((i + 1))
                done
                if [ -n "$dp" ]; then
                    dest_ok "gh repo clone" "$dp"
                elif [ "$np" -ge 1 ]; then
                    rp=${rp%/}
                    rp=${rp##*/}
                    rp=${rp##*:}
                    rp=${rp%.git}
                    [[ $rp =~ ^[A-Za-z0-9._-]+$ ]] || rp=x
                    dest_ok "gh repo clone" "$rp"
                fi
            fi
            ;;
    esac
    return 0
}

# --- Array values that spell a command. ----------------------------------------
# `cmd=(gh pr merge 5)` stores a command that `"${cmd[@]}"` runs behind any
# word. A value whose first two words are git or gh and one of its own
# subcommands (or a flag) is checked as that command; a list of names
# (`tools=(git gh jq)`) is not one.
RE_ARRAY='^[A-Za-z_][A-Za-z0-9_]*\+?=\((.*)\)$'
s=0
while [ "$s" -lt "$NSEGS" ]; do
    load_segment "$s"
    s=$((s + 1))
    ARR=()
    i=0
    while [ "$i" -lt "${#sw[@]}" ]; do
        if ! is_dyn "${sf[$i]}" && [[ ${sw[$i]} =~ $RE_ARRAY ]]; then
            ARR[${#ARR[@]}]=${BASH_REMATCH[1]}
        fi
        i=$((i + 1))
    done
    # `set -- gh pr merge 5` stores a command the same way, for `"$@"`.
    if [ "${sw[0]:-}" = set ] && ! is_dyn "${sf[0]:--}"; then
        i=1
        while [ "$i" -lt "${#sw[@]}" ]; do
            case ${sw[$i]} in
                --)
                    i=$((i + 1))
                    break
                    ;;
                [-+]*) i=$((i + 1)) ;;
                *) break ;;
            esac
        done
        t=''
        while [ "$i" -lt "${#sw[@]}" ]; do
            t="$t ${sw[$i]}"
            i=$((i + 1))
        done
        [ -z "$t" ] || ARR[${#ARR[@]}]=${t# }
    fi
    j=0
    while [ "$j" -lt "${#ARR[@]}" ]; do
        read -r -a aw <<<"${ARR[$j]}"
        j=$((j + 1))
        [ "${#aw[@]}" -ge 2 ] || continue
        lc "${aw[0]##*/}"
        case $LC_OUT in
            gh) list=$GH_COMMANDS ;;
            git) list=$GIT_EMB ;;
            *) continue ;;
        esac
        case ${aw[1]} in
            -*) ;;
            *) case $list in *" ${aw[1]} "*) ;; *) continue ;; esac ;;
        esac
        sw=("${aw[@]}")
        sf=()
        i=0
        while [ "$i" -lt "${#sw[@]}" ]; do
            sf[$i]=''
            i=$((i + 1))
        done
        AS_NAME=() AS_VAL=() AS_FL=() RUNNER='' CMD=$LC_OUT CMD_IDX=0 WRAPPED=1
        case $LC_OUT in
            gh) check_gh 1 ;;
            git) check_git 1 ;;
        esac
    done
done

# text_runner <name> <from>: the words from <from> are handed to a program
# that runs text (a shell, `eval`, `find -exec`, `watch`, ...). Denies a git
# or gh command among them, and a shell that reads its commands on standard
# input.
# text_has_cmd <text>: the text holds git or gh with one of its own
# subcommands or a flag after it. `apt-get install -y git` does not.
text_has_cmd() {
    local t
    # Two readings, and either one counts. First: `\gh` runs gh, and the
    # text can span lines (`read` stops at the first).
    t=${1//\\/ }
    t=${t//$'\n'/ }
    ! text_words_cmd "$t" || return 0
    # Second: in `$'...'` a line break is written `\n`, and the lexer's mark
    # for an expansion or an escape is a word of its own, so
    # `-e<mark>gh pr merge 5` reads as `gh pr merge 5`.
    t=${1//\\[ntr]/ }
    t=${t//\\/ }
    t=${t//$'\n'/ }
    t=${t//$'\037'/ $'\037' }
    text_words_cmd "$t"
}

# text_words_cmd <text>: the word test of text_has_cmd on one reading. A flag
# can carry the text after `=` (`--command="gh pr merge 5"`).
text_words_cmd() {
    local tw k=0 nx
    read -r -a tw <<<"${1//[;&|()\`\'\"]/ }"
    while [ "$k" -lt "${#tw[@]}" ]; do
        nx=${tw[$k]}
        case $nx in -*=*) nx=${nx#*=} ;; esac
        lc "${nx##*/}"
        nx=${tw[$((k + 1))]:-}
        # A flag, an expansion this call made, or one the inner shell makes
        # (`gh $sub merge 5` in single quotes) after the name.
        case $LC_OUT in
            gh)
                case $nx in -* | '$'* | *$'\037'*) return 0 ;; esac
                case $GH_COMMANDS in *" $nx "*) return 0 ;; esac
                ;;
            git)
                case $nx in -* | '$'* | *$'\037'*) return 0 ;; esac
                case $GIT_EMB in *" $nx "*) return 0 ;; esac
                ;;
        esac
        k=$((k + 1))
    done
    return 1
}

text_runner() {
    local name=$1 i=$2 operand=0 w
    while [ "$i" -lt "${#sw[@]}" ]; do
        # In `$'...'` a line break is written `\n`: `bash -c $'set -e\ngh ...'`.
        w=${sw[$i]//\\[ntr]/ }
        if [[ $w =~ $RE_CODE_MENTION ]] || path_cmd "$i"; then
            deny "blocked: git or gh is handed to \`$name\` as text to run, where this hook cannot check it. Call git or gh directly."
        fi
        w=${sw[$i]}
        # A value this call assigned from a git or gh command, run as
        # code: `cmd='gh pr merge 5'; eval "$cmd"`.
        if is_dyn "${sf[$i]}" && [ "$VAR_TAINT" = 1 ]; then
            deny "blocked: this call stores a git or gh command in a variable and hands a variable to \`$name\` to run, so the hook cannot read what runs. Call git or gh by name."
        fi
        case $w in
            -s | - | /dev/stdin | /dev/fd/0) operand=-1 ;;
            # Prints and exits; nothing is read on standard input.
            --version | --help) [ "$operand" != 0 ] || operand=1 ;;
            -o | +o | -O | +O | --rcfile | --init-file) i=$((i + 1)) ;;
            -* | +*) ;;
            *) [ "$operand" != 0 ] || operand=1 ;;
        esac
        i=$((i + 1))
    done
    # A shell with no script operand runs what it reads on standard input: a
    # pipe, a here-string or a heredoc, none of which the checks above read.
    # The call names git or gh somewhere, or this hook would have left at its
    # first test.
    case $name in
        sh | bash | zsh | dash | ksh | fish | source | .)
            if [ "$operand" != 1 ]; then
                deny "blocked: \`$name\` reads its commands from standard input in a call that names git or gh, so the hook cannot read what runs. Call git or gh directly."
            fi
            ;;
    esac
    return 0
}

# dyn_then_sub <word> <words after it>: one of git's or gh's subcommands
# follows an expansion, inside the word (`"$g pr merge 5"`) or in the words
# after it (`"$G" pr merge 5`), with nothing but flags between.
dyn_then_sub() {
    local tw k=0 j t nx
    t=${1//$'\037'/ $'\037' }
    t=${t//$'\n'/ }
    read -r -a tw <<<"${t//[;&|()\`\'\"\\]/ } $2"
    while [ "$k" -lt "${#tw[@]}" ]; do
        if [ "${tw[$k]}" = $'\037' ]; then
            # Flags may stand between: `$g --no-pager push origin main`.
            j=$((k + 1))
            while [ "$j" -lt "${#tw[@]}" ]; do
                case ${tw[$j]} in -*) j=$((j + 1)) ;; *) break ;; esac
            done
            nx=${tw[$j]:-}
            [ -z "$nx" ] || case "$GIT_EMB$GH_COMMANDS" in *" $nx "*) return 0 ;; esac
        fi
        k=$((k + 1))
    done
    return 1
}

# behind_text <from>: the command is one this hook does not read through
# (`nix develop -c bash -c '...'`, `uv run sh -c '...'`, `devbox run '...'`).
# Its arguments are often prose or package names that mention git, so only
# this is refused: text with git or gh and one of its subcommands or a flag
# in it, after a `-c` style flag or behind a runner; and a shell with no
# script operand in a call that holds a heredoc or a here-string.
behind_text() {
    local i=$1 dashc=0 runner=0 w shell='' operand=0
    case $RUNNERS in *" $CMD "*) runner=1 ;; esac
    while [ "$i" -lt "${#sw[@]}" ]; do
        w=${sw[$i]}
        # Text with an expansion in it is read too: `sh -c "gh pr merge $n"`.
        case $w in *[[:space:]]* | *\\[ntr]*)
            if { [ "$dashc" = 1 ] || [ "$runner" = 1 ]; } && text_has_cmd "$w"; then
                deny "blocked: git or gh is handed to \`$CMD\` as text to run, where this hook cannot check it. Call git or gh directly."
            fi
            # The text joined to its flag: `su -c"gh pr merge 5" user`.
            case $w in -c*)
                if text_has_cmd "${w#-c}"; then
                    deny "blocked: git or gh is handed to \`$CMD\` as text to run, where this hook cannot check it. Call git or gh directly."
                fi
                ;;
            esac
            ;;
        esac
        if is_dyn "${sf[$i]}"; then
            # A value this call assigned from a git or gh command, run as
            # code: `cmd='gh pr merge 5'; nix develop -c bash -c "$cmd"`.
            # A name the call only looked up (`which gh && nix develop -c
            # cargo test "$T"`) counts in a shell's text position alone.
            # It counts too where one of git's or gh's subcommands follows the
            # expansion: `doppler run -- $(which gh) pr merge 5`,
            # `for g in gh; do su -c "$g pr merge 5" u; done`.
            if [ "$dashc" = 1 ] || [ "$runner" = 1 ]; then
                if [ "$VAR_TAINT_CMD" = 1 ] || { [ "$VAR_TAINT" = 1 ] && { { [ -n "$shell" ] && [ "$dashc" = 1 ]; } || dyn_then_sub "$w" "${sw[*]:$((i + 1))}"; }; }; then
                    deny "blocked: this call stores a git or gh command in a variable and hands a variable to \`$CMD\` to run, so the hook cannot read what runs. Call git or gh by name."
                fi
            fi
            [ -z "$shell" ] || operand=1
            i=$((i + 1))
            continue
        fi
        # The flag that takes text to run: `-c`, a short cluster ending in
        # it (`-lc`), or any cluster with it behind a shell (`sh -ce`).
        # `go test -race` is none of these.
        case $w in
            --*) ;;
            -c) dashc=1 ;;
            -*c*)
                if [ -n "$shell" ] || [[ $w =~ ^-[A-Za-z]+c$ ]]; then dashc=1; fi
                ;;
        esac
        if [ -n "$shell" ]; then
            case $w in
                -* | +*) ;;
                *) operand=1 ;;
            esac
        else
            lc "${w##*/}"
            case $LC_OUT in sh | bash | zsh | dash | ksh | fish) shell=$LC_OUT ;; esac
        fi
        i=$((i + 1))
    done
    if [ -n "$shell" ] && [ "$operand" = 0 ]; then
        case $COMMAND in
            *'<<'*) deny "blocked: \`$shell\` behind \`$CMD\` reads its commands from standard input in a call that names git or gh, so the hook cannot read what runs. Call git or gh directly." ;;
        esac
    fi
    return 0
}

# --- Pass 2: judge each command. --------------------------------------------------
s=0
while [ "$s" -lt "$NSEGS" ]; do
    load_segment "$s"
    strip_prefix
    s=$((s + 1))
    if [ "$ENV_SPLIT" = 1 ]; then
        i=0
        while [ "$i" -lt "${#sw[@]}" ]; do
            if [[ ${sw[$i]} =~ $RE_CODE_MENTION ]] || { is_dyn "${sf[$i]}" && [ "$VAR_TAINT" = 1 ]; }; then
                deny "blocked: git or gh is handed to \`env -S\` as text to run, where this hook cannot check it. Call git or gh directly."
            fi
            i=$((i + 1))
        done
    fi
    if [ "$CMD_DYN" != 0 ]; then
        if [ "$CMD_DYN" = 2 ]; then
            deny "blocked: the command word is an expansion that spells git or gh, so the hook cannot read which program runs. Call git or gh by name."
        fi
        if [ "$VAR_TAINT" = 1 ]; then
            deny "blocked: this call stores a git or gh command in a variable, an alias or a \${...} default and then runs a command through an expansion, so the hook cannot read what runs. Call git or gh by name."
        fi
        # The expansion can be a shell: `"$SHELL" -c 'gh pr merge 5'`.
        i=$((CMD_IDX + 1))
        dashc=0
        while [ "$i" -lt "${#sw[@]}" ]; do
            if [ "$dashc" = 1 ] && text_has_cmd "${sw[$i]}"; then
                deny "blocked: git or gh is handed as text to a command word the shell computes, which can be a shell this hook does not read. Call git or gh directly."
            fi
            if ! is_dyn "${sf[$i]}"; then
                case ${sw[$i]} in
                    --*) ;;
                    -*c*) dashc=1 ;;
                esac
            fi
            i=$((i + 1))
        done
        continue
    fi
    case $CMD in
        git | gh)
            # A brace list expands to words this hook reads as one:
            # `git commit {--no-verify,-m} x`.
            i=$((CMD_IDX + 1))
            while [ "$i" -lt "${#sw[@]}" ]; do
                case ${sf[$i]} in
                    *B*) deny "$CMD blocked: the brace list \`${sw[$i]//$'\037'/\$...}\` expands to several words, which can be flags this hook does not read. Write the words out." ;;
                    *Z*) deny "$CMD blocked: a bare \`${sw[$i]}\` stands among its words, which zsh reads as the end of the command and bash as an argument, so the hook cannot tell what runs. Quote it as an argument, or end the command with \`;\` before it." ;;
                esac
                i=$((i + 1))
            done
            # A program-valued setting that carries a git or gh command:
            # `GIT_EDITOR='gh pr merge 5 #' git commit --amend`.
            i=0
            while [ "$i" -lt "${#AS_NAME[@]}" ]; do
                if [[ ${AS_VAL[$i]} =~ $RE_CODE_MENTION ]]; then
                    deny "$CMD blocked: \`${AS_NAME[$i]}=\` in front of it holds a git or gh command, which $CMD could run as its editor, pager or helper where this hook does not check it. Run that command by itself."
                fi
                i=$((i + 1))
            done
            [ -z "$CODE_ENV" ] || deny "$CMD blocked: the call exports \`$CODE_ENV\` holding a git or gh command, which $CMD could run as its editor, pager or helper where this hook does not check it. Run that command by itself."
            ;;
    esac
    case $CMD in
        gh) check_gh $((CMD_IDX + 1)) ;;
        git) check_git $((CMD_IDX + 1)) ;;
        eval | source | . | sh | bash | zsh | dash | ksh | fish | watch | find | parallel | script | flock | alias | trap)
            text_runner "$CMD" $((CMD_IDX + 1))
            ;;
        *)
            # A shell behind a command this hook does not read through
            # (`nix develop -c bash -c '...'`, `direnv exec . sh -c '...'`)
            # runs its text the same way.
            case $TEXT_CMDS in
                *" $CMD "*) ;;
                *) [ -z "$CMD" ] || behind_text $((CMD_IDX + 1)) ;;
            esac
            ;;
    esac
    # A second name for the program: `ln -s /opt/homebrew/bin/gh x; ./x ...`.
    case $CMD in
        ln | cp | install | hash)
            i=$((CMD_IDX + 1))
            # `hash` names a program only with `-p`; without it, it is a lookup.
            if [ "$CMD" = hash ] && ! has_word "$i" '-*p*'; then i=${#sw[@]}; fi
            while [ "$i" -lt $((${#sw[@]} - 1)) ]; do
                w=${sw[$i]##*/}
                # A directory of that name (`~/.config/gh`) is not the program.
                case ${sw[$i]} in
                    '~/'*) dest=$HOME/${sw[$i]#'~/'} ;;
                    /*) dest=${sw[$i]} ;;
                    *) dest=${HOOK_CWD:-.}/${sw[$i]} ;;
                esac
                if ! is_dyn "${sf[$i]}" && [ -d "$dest" ]; then w=''; fi
                case $w in
                    [Gg][Ii][Tt] | [Gg][Hh]) deny "blocked: \`$CMD\` gives git or gh a second name, which this hook would not recognize when it runs. Call git or gh by name." ;;
                esac
                i=$((i + 1))
            done
            ;;
    esac
    # An excepted command is refused above with its own reason; what is left
    # is an ordinary command behind a runner that builds its environment.
    case $CMD in
        git | gh)
            case $ENV_RUNNERS in
                *" $RUNNER "*) deny "$CMD blocked: \`$RUNNER\` runs it with an environment of its own making, which can swap the token or config the operator set up. Run $CMD directly. $OPERATOR" ;;
            esac
            ;;
    esac
done

exit 0
