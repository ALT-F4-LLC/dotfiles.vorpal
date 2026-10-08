# docket-guard-probe.sh -- the DEBUG-trap leaf probe shared by the docket
# guard hooks (docket-sibling-guard-hook.sh, docket-trust-guard-hook.sh and
# docket-commit-guard-hook.sh). Each hook reads this file beside itself and
# runs its text as `bash -c` with the command to check on stdin and stderr
# merged into stdout:
#
#     PROBE_RAW=$(printf '%s' "$COMMAND" | bash -c "$PROBE_PROGRAM" 2>&1)
#
# A hook that cannot read this file refuses the command, as it does for
# docket-guard-prepass.awk: without the probe there is no leaf list to check.
# docket-sibling-guard-hook.sh's header (THE PROBE HARDENING) states the
# design and what each part closes; this file holds the one copy of the code.
#
# The probe asks bash which simple commands it would dispatch: a DEBUG trap
# under `extdebug` and `set -T` vetoes every leaf, so nothing the command
# names runs. Leaves are printed as \035<text>\036 frames on fd 8, a copy of
# the probe's stdout saved before the walk: bash 5 runs a coproc's leaves in
# a child whose stdout is the coproc pipe, and they would be lost there.
# bash's stderr is merged into the same capture and recovered from between
# the frames. The probe refuses with four exit codes: 113 the cap, 114 a
# redirection on a structural builtin, 115 a branch on an unread value, 116
# probe state in a structural leaf. Each reaches the hook through the marker
# printed before the exit (`_guard_probe: leaf cap`, `_guard_probe: structural
# redirect`, `_guard_probe: branch on an unread value`, `_guard_probe: probe
# state in a structural leaf`), since an exit inside a pipeline stage (`ls |
# { ...; }; echo done`) ends only that stage and never reaches the probe exit
# status. The cap alone still ends every shell: its count is the token pipe
# on fd 7, shared by every subshell and stage, so a shell around a capped
# stage finds the pipe empty at its own next firing and exits 113 too. The
# marker is written on fd 8, opened before `set -r`, not on fd 2: a loop that
# closes stderr (`done 2>&-`) would swallow it there, and restricted mode lets
# a close through since it opens no file. A hook reads it back with bash's own
# stderr, from between the frames; 113 and 114 can also be read from the exit
# status, as a fallback for a top-level refusal whose marker was lost. The
# caller cannot pick any of them: `exit` and `return` are vetoed, and a vetoed
# leaf reports success. A redefinition of the handler fails on `readonly -f`
# with bash's "readonly function" error, and a compound redirect fails under
# `set -r` with "restricted: cannot redirect output"; both reach the capture
# as bash's own stderr.
#
# Every name the probe keeps in the analyzed command's shell starts with
# `_leaf_`, so a hook-side check can refuse a command that names one.

shopt -s extdebug
set -T
COMMAND=$(cat)
_leaf_n=0   # not `n`: the analyzed command shares this shell, and `for n in …` collided with the counter
# A leaf that is only variable assignments RUNS (see THE PROBE HARDENING), but
# only in these value shapes: bare words, $name, ${name}, and $(( ))
# over names and operators. No quotes, no $( ), no backticks, no
# subscripts, so nothing an assignment can evaluate runs a command.
readonly _leaf_name="[A-Za-z_][A-Za-z0-9_]*"
readonly _leaf_word="[A-Za-z0-9_./:@%+,-]|\\\$${_leaf_name}|\\\$\\{${_leaf_name}\\}|\\\$\\(\\(([^][()\$\`]|\\\$${_leaf_name})*\\)\\)"
readonly _leaf_assign_re="^${_leaf_name}\\+?=(${_leaf_word})*([[:space:]]+${_leaf_name}\\+?=(${_leaf_word})*)*\$"
# A read leaf RUNS (see THE PROBE HARDENING) only in this shape: an optional
# IFS= of bare characters, -r, and plain names. A site is the subshell
# level and the leaf text. _leaf_reads holds |-separated sites, each
# after a state letter: P vetoed once, B vetoed once and then a break
# ran, Q vetoed again after that break. A P or Q site runs on its next
# firing; a B site is vetoed once more. _leaf_read_ok drops to 0 for
# good once a read meets input other than a pipe at EOF. A P or Q site
# runs only when a leaf other than a read fired since the last read
# (_leaf_walked): a same-text read just before the loop (`read d; while
# read d; do ...`) walked no body, so the loop read is vetoed again.
readonly _leaf_read_re="^(IFS=[A-Za-z0-9_./:@%+,-]*[[:space:]]+)?read([[:space:]]+-r)?([[:space:]]+${_leaf_name})*\$"
_leaf_reads="|"
_leaf_read_ok=1
_leaf_other=0
_guard_probe() {
    _leaf_n=$((_leaf_n + 1))
    # One token per firing from the pipe every shell of the probe shares
    # (fd 7, filled with 2000 bytes before the walk and closed for
    # writing), so the cap counts across subshells and pipeline stages
    # and an empty pipe ends each shell at its next firing.
    if ! read -r -n 1 -u 7 _leaf_tok; then
        printf "%s\n" "_guard_probe: leaf cap" >&8
        exit 113
    fi
    _leaf_walked=$_leaf_other
    _leaf_other=1
    # The first firing is this probe own eval line, not a leaf of the
    # command; recording it would put an interpreter word in every walk.
    if [ "$_leaf_n" -eq 1 ] && [ "$BASH_COMMAND" = "eval -- \"\$COMMAND\"" ]; then
        return 0
    fi
    local _leaf_head="${BASH_COMMAND%%[ $'\t\n']*}"
    _leaf_head="${_leaf_head##*/}"
    # Structural leaves run for real. While a vetoed read stands in for
    # input it never read (_leaf_reads holds a site), one that expands a
    # value, or a continue, could steer the loop past the body it never
    # walked, so the walk is refused. Every refusal is a marker on
    # fd 8: an exit inside a pipeline stage never reaches the probe
    # exit status. An arithmetic `for ((...))` head or `((...))` command
    # reads bare names as variables, so it is refused the same way.
    if [ "$_leaf_reads" != "|" ]; then
        case "$BASH_COMMAND" in
            "(("*)
                printf "%s\n" "_guard_probe: branch on an unread value" >&8
                exit 115 ;;
        esac
    fi
    case "$_leaf_head" in
        for | select | case | eval)
            case "$BASH_COMMAND" in
                *[\<\>]*)
                    printf "%s\n" "_guard_probe: structural redirect" >&8
                    exit 114 ;;
            esac
            case "$BASH_COMMAND" in
                *_leaf_*)
                    printf "%s\n" "_guard_probe: probe state in a structural leaf" >&8
                    exit 116 ;;
            esac
            if [ "$_leaf_reads" != "|" ]; then
                case "$BASH_COMMAND" in
                    *[\$\`]*)
                        printf "%s\n" "_guard_probe: branch on an unread value" >&8
                        exit 115 ;;
                esac
            fi
            printf "\035%s\036" "$BASH_COMMAND" >&8
            return 0 ;;
        while | until | if | elif | else | fi | then | do | done | \
        esac | function | time | "{" | "}" | "[" | "[[" | : | \
        true | false | break | continue)
            case "$BASH_COMMAND" in
                *[\<\>]*)
                    printf "%s\n" "_guard_probe: structural redirect" >&8
                    exit 114 ;;
            esac
            # This leaf runs with its expansions, so arithmetic in it
            # (`: $((_leaf_n=0))`) would write the probe state.
            case "$BASH_COMMAND" in
                *_leaf_*)
                    printf "%s\n" "_guard_probe: probe state in a structural leaf" >&8
                    exit 116 ;;
            esac
            # An arithmetic `[[` comparison reads a bare name as a
            # variable (`[[ n -ne 0 ]]`), so it expands a value with no $.
            if [ "$_leaf_reads" != "|" ]; then
                case "$_leaf_head:$BASH_COMMAND" in
                    continue:* | *[\$\`]* | \
                    "[[:"*" -eq "* | "[[:"*" -ne "* | "[[:"*" -lt "* | \
                    "[[:"*" -le "* | "[[:"*" -gt "* | "[[:"*" -ge "*)
                        printf "%s\n" "_guard_probe: branch on an unread value" >&8
                        exit 115 ;;
                esac
            fi
            # A break may leave a read loop whose site never runs, so a
            # later read with the same text would run at once: every P
            # site becomes B and walks its body once more. A break in an
            # inner loop does the same to the read loop around it, whose
            # Q site then ends it on the next firing.
            [ "$_leaf_head" = break ] && _leaf_reads="${_leaf_reads//|P/|B}"
            return 0 ;;
    esac
    if [[ "$BASH_COMMAND" =~ $_leaf_read_re ]] && [[ "$BASH_COMMAND" != *_leaf_* ]]; then
        printf "\035%s\036" "$BASH_COMMAND" >&8
        _leaf_other=0
        local _leaf_site="${BASH_SUBSHELL}:${BASH_COMMAND}"
        # A vetoed read gives each name the value x, so a for-list over
        # it has a pass that reaches the guard above instead of none. A
        # read that runs assigns its own values over these. BASH* names
        # are left alone: BASH_SUBSHELL is part of the site key. Every
        # local here is a _leaf_* name, which no admitted read names, so
        # each assignment reaches the command variable.
        local _leaf_rest="${BASH_COMMAND#IFS=*[[:space:]]}" _leaf_named=0
        _leaf_rest="${_leaf_rest#read}"
        while [[ "$_leaf_rest" =~ ^[[:space:]]+([-A-Za-z0-9_]+)(.*)$ ]]; do
            _leaf_rest="${BASH_REMATCH[2]}"
            case "${BASH_REMATCH[1]}" in
                -r) ;;
                BASH*) _leaf_named=1 ;;
                *) printf -v "${BASH_REMATCH[1]}" %s x 2>&9
                   _leaf_named=1 ;;
            esac
        done
        [ "$_leaf_named" -eq 1 ] || REPLY=x
        case "$_leaf_reads" in
            *"|B$_leaf_site|"*)
                _leaf_reads="${_leaf_reads/"|B$_leaf_site|"/|Q$_leaf_site|}"
                return 1 ;;
            *"|P$_leaf_site|"* | *"|Q$_leaf_site|"*)
                [ "$_leaf_walked" -eq 1 ] || return 1
                _leaf_reads="${_leaf_reads/"|P$_leaf_site|"/|}"
                _leaf_reads="${_leaf_reads/"|Q$_leaf_site|"/|}"
                local _leaf_byte
                if [ "$_leaf_read_ok" -eq 1 ] && [ -p /dev/stdin ]; then
                    IFS= read -r -t 1 -n 1 _leaf_byte
                    [ "$?" -eq 1 ] && return 0
                fi
                _leaf_read_ok=0
                return 1 ;;
        esac
        _leaf_reads="${_leaf_reads}P${_leaf_site}|"
        return 1
    fi
    if [[ "$BASH_COMMAND" =~ $_leaf_assign_re ]]; then
        case "$BASH_COMMAND" in
            *_leaf_*) ;;   # the counter and these patterns: never the command's to set
            *)
                printf "\035%s\036" "$BASH_COMMAND" >&8
                return 0 ;;
        esac
    fi
    printf "\035%s\036" "$BASH_COMMAND" >&8
    if declare -F "$_leaf_head" >&9 2>&9; then
        return 0
    fi
    return 1
}
readonly -f _guard_probe
# The cap tokens: 2000 bytes in a pipe whose writer exits once they are
# written, so an empty pipe reads as end of file, never as a wait.
_leaf_fill=$(printf "%2000s" "")
exec 7< <(printf "%s" "${_leaf_fill// /x}") 8>&1 9>/dev/null
set -r
trap _guard_probe DEBUG
eval -- "$COMMAND"
