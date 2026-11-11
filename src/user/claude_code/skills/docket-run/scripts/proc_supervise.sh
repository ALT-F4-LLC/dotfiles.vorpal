#!/usr/bin/env bash
#
# proc_supervise: snapshot | inventory | kill
#
# Lists the processes that Claude Code sessions own on this machine, decides
# who owns each one, and plans an action for it. Only this session's own
# shells are ever signalled:
#
#   own-shell     a Bash-tool shell tree of the CURRENT session. The conductor
#                 and its agents (Agent and Workflow seats) all run in one
#                 session process, so their shells share it. Action `stop`.
#                 With a `ps` table the tree's root shell must source
#                 ~/.claude/shell-snapshots/ (the Bash tool's marker), so a
#                 status-line or MCP `sh -c` is own-service. With an `lsof`
#                 table (no argv) any shell child of the session counts.
#   own-detached  carries the current session's id but no longer descends from
#                 it (`nohup ... &`, setsid). Action `stop`. The id comes from
#                 the `ps -E` environment or, where the environment is hidden
#                 (Darwin hides it for a process in the Bash sandbox), from
#                 the ARGV MARKER: a `docket-session=<uuid>` token that is the
#                 final argument of a shell `-c` process on the chain from
#                 the process up to its orphan root. The launch convention is
#                   nohup sh -c '<cmd>; exit $?' "docket-session=$CLAUDE_CODE_SESSION_ID" >log 2>&1 &
#                 (setsid on Linux); the trailing `exit` keeps the wrapper
#                 alive, so its children inherit the marker by ancestry. The
#                 marker counts only when every marker and every environment
#                 id on the chain name the current session; evidence
#                 `argv-marker`. It is read from the `ps` argv only, so the
#                 lsof table never shows it, and a double fork, an `exec` in
#                 the command, or a wrapper that dies first loses it. A
#                 conflicting marker never makes a stop: beside the current
#                 id in the environment it gives unknown. A detached process
#                 with neither id nor marker, or with another session's
#                 marker, is foreign: not listed, counted in `foreign=`, and
#                 refused `not-listed`.
#
# Every other class is reported and never signalled:
#
#   own-service       a non-shell child tree of the current session (MCP or
#                     LSP server, hook runner).
#   sibling           descends from another live session.
#   sibling-detached  carries a live sibling session's id, detached from it.
#   unregistered      carries a session id that is not in the registry, while
#                     some process carrying that id still has a live parent
#                     other than init: an unregistered live session
#                     (`claude -p`).
#   dead-owner        its owning session passes the death test below. It is
#                     REPORTED, not reaped: the audit behind this script found
#                     no process that outlived its session, so reaping is an
#                     unevidenced capability (references/proc-supervise.md).
#   unknown           carries a session id, but ownership cannot be proven
#                     (registry unusable, a session process or an ancestor of
#                     one, reparented to a subreaper, or orphaned with death
#                     unproven).
#
# A nested session (`claude -p` started from an own shell, or detached) ends
# the ancestry walk. Its trees are classed by their own session id; a process
# under it that carries the current id (inherited) is unknown. Limit: a nested
# session whose title is neither `claude` nor a version (`node cli.js -p`) and
# that has no child with a differing id is not recognised, and its tree reads
# as own-shell. Where no process shows its session id in the environment,
# no child differs, so only the title protects.
#
# Processes with no Claude ancestry, no session id and no argv marker naming
# the current session are counted as foreign and never listed.
#
# DEATH TEST. A session counts as dead (dead-owner) when all four hold:
#   1. the registry works: ~/.claude/sessions/<pid>.json lists the current
#      session as live (its pid is in the table with the recorded start time);
#   2. no registry entry for the session id is live;
#   3. a registry entry for the id shows its session process gone (pid absent
#      from the table, or held by a process that is not a Claude session), and
#      none shows a Claude process at its pid with another start time;
#   4. every process carrying CLAUDE_CODE_SESSION_ID=<id> has been reparented
#      to init (pid 1), so no process parents its trees.
# An orphan whose id has no registry entry, or whose entry's pid holds a
# Claude process, is unknown (death-unproven): an unregistered `claude -p`
# or a mismatched registry entry of a live session looks the same.
# LIMIT: the test is not a proof. A crashed session's stale entry plus a live
# unregistered `claude -p --resume <id>` whose child carries that id and is
# orphaned reads dead-owner; and a Claude process whose executable path holds
# a space is not recognised by title. Hence dead-owner is report-only.
#
# DETERMINISM. Classification and the planned actions are a pure function of
# the snapshot (process table), the sessions table and the current session id.
# `inventory --snapshot F --sessions-tsv S --session ID` prints the same bytes
# on every run, whatever the row order of F. Rows are sorted by class, then pid.
#
# KILL. `kill --pid N...` signals the named own-shell or own-detached pids AND
# their descendants, parents first: stopping a root shell alone would leave its
# `go test` children running and reparented to init, and stopping a loop
# shell's child first lets the loop start its next iteration (S1). A child the
# loop forks between the snapshot and the parent's signal is not in the plan;
# re-run the inventory after a stop. A named pid of any other
# class is refused with its class on a `refuse` row. There is no blanket stop.
# The audit's worst self-inflicted case was a conductor that stopped nine live
# executor shells it took for leftovers. So the conductor names each pid, and
# the `step=` and cwd columns show which lane a shell belongs to.
# `kill --dry-run` prints the same plan and signals nothing.
#
# A real kill (no --dry-run):
#   - reads only the live table (`ps`) and the real registry. --snapshot,
#     --sessions-dir, --sessions-tsv and --session are refused, and the
#     session is the payload's session_id;
#   - needs --payload, a Claude Code hook payload. A payload that carries
#     `agent_id` (a subagent) is refused, because agents only inventory. This
#     check is a tripwire, not an authority check: any caller can write a
#     file. The authority is the docket-proc-guard hook, which runs this kill
#     for a docket conductor's main conversation and denies it to everyone
#     else;
#   - re-reads each target's start time before signalling it, and skips a pid
#     whose start time changed (reused).
# Inside the Bash sandbox no signal reaches a process outside the call. That
# is why the live kill runs from the hook, which runs outside the sandbox.
#
# PLATFORMS. Darwin is supported. The Linux branch is written but its /proc
# reader has never run, and only the classifier is tested on a Linux-shaped
# table. The table comes from
# `TZ=UTC ps -axww -o pid=,ppid=,pgid=,lstart=,command=` (UTC, because the
# registry records procStart in UTC). Session ids come from `ps -E`
# (Darwin) or /proc/<pid>/environ (Linux); cwds from `lsof -d cwd` (Darwin) or
# /proc/<pid>/cwd (Linux). Where `ps` is refused (the Darwin Bash sandbox),
# the table falls back to `lsof`, which carries no argv, start time or
# environment. Ownership then comes from ancestry alone: nothing is ever
# dead-owner, a hook runner reads as a shell, and kill is refused. Linux
# limit: an orphan reparented to a subreaper (systemd --user) rather than
# pid 1 is never dead-owner.
#
# Usage:
#   proc_supervise.sh snapshot
#   proc_supervise.sh inventory [--snapshot F] [--sessions-dir D | --sessions-tsv F] [--session ID]
#   proc_supervise.sh kill --dry-run --pid N [--pid N ...] [--signal SIG] [inventory options]
#   proc_supervise.sh kill --payload FILE --pid N [--pid N ...] [--signal SIG]
# Options:
#   --snapshot FILE      read the table from FILE instead of the live machine
#   --sessions-dir DIR   registry directory (default ~/.claude/sessions)
#   --sessions-tsv FILE  registry as TSV `pid<TAB>sessionId<TAB>procStart`
#   --session ID         current session (default $CLAUDE_CODE_SESSION_ID)
#   --pid N              a pid to stop, with its descendants (repeatable)
#   --signal SIG         TERM, INT, HUP or KILL (default TERM; no audited case
#                        needed more than TERM, the rest are escalations)
#   --payload FILE       the hook payload (real kill only)
#
# Snapshot format, one process per line, tab-separated:
#   pid ppid pgid lstart sid cwd command
# where lstart, sid and cwd are `-` when unknown. Header lines are
# `#self<TAB>pid`, naming the caller, whose ancestry and descendants are never
# listed, and `#source<TAB>ps|lsof`.
#
# Output: one row per listed process,
#   class<TAB>action<TAB>pid<TAB>ppid<TAB>owner<TAB>evidence<TAB>cwd<TAB>command
# then `summary` rows. kill appends `refuse`, then `would-signal` (dry run) or
# `signal`/`skip` rows.
#
# Exit: 0 done; 2 usage; 3 refused (kill gate); 4 no process table.
set -u
# C locale for every tool: BSD sed aborts the whole stream on one illegal
# byte in a process environment, and lstart names must match the registry.
export LC_ALL=C

SCRIPT=${BASH_SOURCE[0]}
mode=${1:-}
[ $# -gt 0 ] && shift

snapshot=
sessions_dir=${HOME}/.claude/sessions
sessions_tsv=
session=${CLAUDE_CODE_SESSION_ID:-}
override=
payload=
dry_run=
pids=" "
signal=TERM

usage() { sed -n '/^# Usage:/,/^# Exit:/p' "$SCRIPT" | sed 's/^# \{0,1\}//' >&2; exit 2; }
die() { printf 'proc_supervise: %s\n' "$1" >&2; exit "${2:-2}"; }

while [ $# -gt 0 ]; do
    case "$1" in
        --snapshot) snapshot=${2:-}; override="$override --snapshot"; shift 2 ;;
        --sessions-dir) sessions_dir=${2:-}; override="$override --sessions-dir"; shift 2 ;;
        --sessions-tsv) sessions_tsv=${2:-}; override="$override --sessions-tsv"; shift 2 ;;
        --session) session=${2:-}; override="$override --session"; shift 2 ;;
        --payload) payload=${2:-}; shift 2 ;;
        --dry-run) dry_run=1; shift ;;
        --pid)
            case "${2:-}" in ''|*[!0-9]*) die "--pid takes a number" ;; esac
            pids="${pids}$2 "; shift 2 ;;
        --signal)
            case "${2:-}" in TERM|INT|HUP|KILL) signal=$2 ;; *) die "--signal takes TERM, INT, HUP or KILL" ;; esac
            shift 2 ;;
        -h|--help) usage ;;
        *) die "unknown argument: $1" ;;
    esac
done

case "$mode" in
    snapshot|inventory|kill) ;;
    *) usage ;;
esac
command -v jq >/dev/null 2>&1 || die "jq is required" 4

# ---- the kill gate, before anything is read ---------------------------------

if [ "$mode" = kill ]; then
    [ "$pids" != " " ] || die "kill needs --pid: there is no blanket stop" 2
    if [ -z "$dry_run" ]; then
        [ -z "$override" ] || die "refused:$override: a real kill reads only the live table and registry" 3
        [ -n "$payload" ] || die "refused: kill signals only from the docket-proc-guard hook (--payload); use --dry-run to preview" 3
        [ -r "$payload" ] || die "refused: cannot read payload $payload" 3
        agent=$(jq -r '.agent_id // empty' "$payload" 2>/dev/null) || die "refused: payload is not JSON" 3
        [ -z "$agent" ] || die "refused: caller is subagent $agent; agents only inventory" 3
        session=$(jq -r '.session_id // empty' "$payload")
        [ -n "$session" ] || die "refused: payload names no session_id" 3
    fi
fi

# ---- live snapshot -----------------------------------------------------------

live_snapshot() {
    local os table envs cwds
    os=$(uname -s)
    printf '#self\t%s\n' "$$"
    if table=$(TZ=UTC ps -axww -o pid=,ppid=,pgid=,lstart=,command= 2>/dev/null) && [ -n "$table" ]; then
        printf '#source\tps\n'
        if [ "$os" = Darwin ]; then
            # `ps -E` appends the environment after the arguments, so the
            # last match on a line is the environment's.
            envs=$(ps -axww -E -o pid=,command= 2>/dev/null \
                | sed -n 's/^ *\([0-9][0-9]*\) .*CLAUDE_CODE_SESSION_ID=\([0-9a-fA-F-]\{36\}\).*/\1 \2/p')
            cwds=$(lsof -n -d cwd -F pn 2>/dev/null | awk '/^p/ { p = substr($0, 2) } /^n/ && p != "" { print p " " substr($0, 2); p = "" }')
        else
            envs=$(for f in /proc/[0-9]*/environ; do
                p=${f#/proc/}; p=${p%/environ}
                s=$({ tr '\0' '\n' < "$f"; } 2>/dev/null | sed -n 's/^CLAUDE_CODE_SESSION_ID=\([0-9a-fA-F-]\{36\}\)$/\1/p' | tail -n 1)
                [ -n "$s" ] && printf '%s %s\n' "$p" "$s"
            done)
            cwds=$(for d in /proc/[0-9]*; do
                c=$(readlink "$d/cwd" 2>/dev/null) && printf '%s %s\n' "${d#/proc/}" "$c"
            done)
        fi
        { printf '%s\n' "$envs" | sed 's/^/E /'
          printf '%s\n' "$cwds" | sed 's/^/C /'
          printf '%s\n' "$table" | sed 's/^/P /'; } | awk '
            $1 == "E" { sid[$2] = $3; next }
            $1 == "C" { c = $0; sub(/^C [0-9]+ /, "", c); gsub(/\t/, " ", c); cwd[$2] = c; next }
            $1 == "P" && NF >= 10 {
                cmd = $10; for (i = 11; i <= NF; i++) cmd = cmd " " $i
                gsub(/\t/, " ", cmd)
                printf "%s\t%s\t%s\t%s %s %s %s %s\t%s\t%s\t%s\n", $2, $3, $4, $5, $6, $7, $8, $9,
                    (($2 in sid) ? sid[$2] : "-"), (($2 in cwd) ? cwd[$2] : "-"), cmd
            }'
        return 0
    fi
    if [ "$os" = Darwin ] && command -v lsof >/dev/null 2>&1; then
        printf '#source\tlsof\n'
        lsof -n -R -g +c 0 -d cwd -F pRgcn 2>/dev/null | awk '
            function emit() { if (pid != "") printf "%s\t%s\t%s\t-\t-\t%s\t%s\n", pid, ppid, pgid, cwd, cmd }
            /^p/ { emit(); pid = substr($0, 2); ppid = "0"; pgid = "0"; cmd = "?"; cwd = "-"; next }
            /^R/ { ppid = substr($0, 2); next }
            /^g/ { pgid = substr($0, 2); next }
            /^c/ { cmd = substr($0, 2); gsub(/\t/, " ", cmd); next }
            /^n/ { cwd = substr($0, 2); gsub(/\t/, " ", cwd); next }
            END { emit() }'
        return 0
    fi
    return 1
}

sessions_table() {
    if [ -n "$sessions_tsv" ]; then
        cat "$sessions_tsv"
        return
    fi
    [ -d "$sessions_dir" ] || return 0
    local f
    for f in "$sessions_dir"/*.json; do
        [ -f "$f" ] || continue
        jq -r 'select((.pid | type) == "number" and (.sessionId | type) == "string")
               | [(.pid | tostring), .sessionId, (.procStart // "-")] | @tsv' "$f" 2>/dev/null
    done
}

# ---- classification ----------------------------------------------------------

classify() { # <snapshot file> <sessions file>
    awk -F '\t' -v cur="$session" '
    FNR == 1 { file++ }
    file == 1 { if (NF >= 2) { reg_pid[++nreg] = $1; reg_sid[nreg] = $2; reg_start[nreg] = (NF >= 3 ? $3 : "-") } next }
    /^#self\t/ { self = $2; next }
    /^#source\t/ { source = $2; next }
    /^#/ || NF < 7 { next }
    {
        p = $1; n++; order[n] = p
        ppid[p] = $2; lst[p] = $4; sid[p] = $5; cwd[p] = $6; cmd[p] = $7
        for (i = 8; i <= NF; i++) cmd[p] = cmd[p] " " $i
        gsub(/  +/, " ", lst[p])
    }
    function shellish(c,   w) {
        w = c; sub(/ .*/, "", w); sub(/.*\//, "", w); sub(/^-/, "", w)
        return (w == "zsh" || w == "bash" || w == "sh" || w == "dash" || w == "fish")
    }
    # The argv marker on the chain from p to its orphan root: the session id,
    # "" when there is none, or "conflict" when two markers disagree or an
    # environment id on the chain differs from the marker. Called only for a
    # process with no live-session or nested-session ancestor.
    function marker(p,   q, g, n, a, t, m, e) {
        m = ""; e = ""; q = p; g = 0
        while (q != "" && q != "0" && q != "1" && (q in ppid) && g++ < 4096) {
            if (sid[q] != "-" && sid[q] != "") e = e " " sid[q]
            n = split(cmd[q], a, " ")
            if (shellish(cmd[q]) && n >= 3 && a[2] == "-c") {
                t = a[n]
                if (length(t) == 51 && t ~ /^docket-session=[0-9a-fA-F-]+$/) {
                    t = substr(t, 16)
                    if (m == "") m = t; else if (m != t) return "conflict"
                }
            }
            q = ppid[q]
        }
        if (m != "") { n = split(e, a, " "); for (g = 1; g <= n; g++) if (a[g] != m) return "conflict" }
        return m
    }
    END {
        # A registry entry is live when its pid is in the table with the
        # recorded start time. In lsof mode the start time is unknown, so pid
        # reuse cannot be ruled out; that only ever makes a dead session look
        # live, the safe direction.
        for (i = 1; i <= nreg; i++) {
            rp = reg_pid[i]; gsub(/  +/, " ", reg_start[i])
            if ((rp in ppid) && (lst[rp] == reg_start[i] || lst[rp] == "-")) {
                live_pid[rp] = reg_sid[i]; live_sid[reg_sid[i]] = rp
            } else {
                stale_sid[reg_sid[i]] = 1
                # The recorded session process is gone: its pid is absent, or
                # now held by a process that is not a Claude session.
                w = (rp in cmd) ? cmd[rp] : ""; sub(/ .*/, "", w); sub(/.*\//, "", w)
                if (!(rp in ppid) || !(w == "claude" || w ~ /^[0-9]+\.[0-9]+\.[0-9]+$/)) gone_sid[reg_sid[i]] = 1
                else maybe_sid[reg_sid[i]] = 1
            }
        }
        registry_ok = (cur != "" && (cur in live_sid))
        # The caller and its ancestors are never listed.
        q = self; guard = 0
        while (q != "" && q != "0" && (q in ppid) && guard++ < 4096) { selfchain[q] = 1; q = ppid[q] }
        # Per session id: does any carrier hang off a live parent other than init?
        for (k = 1; k <= n; k++) {
            p = order[k]; s = sid[p]
            if (s == "-" || s == "") continue
            top = p; guard = 0
            while ((ppid[top] in sid) && sid[ppid[top]] == s && guard++ < 4096) top = ppid[top]
            par = ppid[top]
            if (par != "1" && par != "0" && (par in ppid)) attached[s] = 1
        }
        # Session processes, registered or not, and every ancestor of one are
        # never acted on. A session process is either a Claude process (its
        # title is `claude` or its version, e.g. 2.1.322) or an EXPORTER, the
        # parent of a carrier whose id differs from the parent own (only a
        # session process exports a new id).
        for (k = 1; k <= n; k++) {
            p = order[k]; w = cmd[p]; sub(/ .*/, "", w); sub(/.*\//, "", w)
            if (w == "claude" || w ~ /^[0-9]+\.[0-9]+\.[0-9]+$/) sessproc[p] = 1
            s = sid[p]; par = ppid[p]
            if (s != "-" && s != "" && par != "1" && par != "0" && (par in ppid) && sid[par] != s) sessproc[par] = 1
        }
        for (p in live_pid) sessproc[p] = 1
        for (p in sessproc) {
            q = p; guard = 0
            while (q != "" && q != "0" && q != "1" && (q in ppid) && guard++ < 4096) { protect[q] = 1; q = ppid[q] }
        }
        for (k = 1; k <= n; k++) {
            p = order[k]
            if (p == "1" || p == "0" || (p in live_pid) || (p in selfchain)) continue
            # Ancestry: the nearest live session process above p. The caller
            # descendants (its own pipeline) are skipped.
            owner = ""; root = p; q = ppid[p]; guard = 0; mine = 0; nested = ""
            while (q != "" && q != "0" && q != "1" && (q in ppid) && guard++ < 4096) {
                if (q == self) { mine = 1; break }
                if (q in live_pid) { owner = live_pid[q]; break }
                if (q in sessproc) { nested = q; break }
                root = q; q = ppid[q]
            }
            if (mine) continue
            s = sid[p]
            if (owner != "") {
                if (owner == cur) {
                    # A hook runner (`sh -c "bash ~/.claude/hooks/..."`) is a
                    # shell too, but not a Bash-tool shell.
                    if (shellish(cmd[root]) && index(cmd[root], "/.claude/hooks/") == 0 \
                        && (source != "ps" || index(cmd[root], "/.claude/shell-snapshots/") > 0)) { cls = "own-shell"; act = "stop" }
                    else { cls = "own-service"; act = "report" }
                } else { cls = "sibling"; act = "report" }
                ev = "ancestor=" live_sid[owner] (root != p ? ",root=" root : "")
            } else if (nested != "" && s == cur) {
                # Under a nested session process the outer id may only be
                # inherited: never a stop target of this session.
                cls = "unknown"; act = "report"; owner = s; ev = "env,under-session-process=" nested
            } else if (s == "-" || s == "") {
                # No id in the environment: only an argv marker naming the
                # current session attributes it. A marker naming another
                # session, or no marker, leaves it foreign.
                if (nested != "" || cur == "" || marker(p) != cur) { foreign++; continue }
                owner = cur
                if (!registry_ok) { cls = "unknown"; act = "report"; ev = "argv-marker,registry-unusable" }
                else { cls = "own-detached"; act = "stop"; ev = "argv-marker,registry-live" }
            } else if (!registry_ok) {
                cls = "unknown"; act = "report"; owner = s; ev = "registry-unusable"
            } else if (s in live_sid) {
                cls = (s == cur ? "own-detached" : "sibling-detached"); act = (s == cur ? "stop" : "report")
                owner = s; ev = "env,registry-live"
                mk = (nested == "" ? marker(p) : "")
                if (mk != "" && mk != s) { cls = "unknown"; act = "report"; ev = "env,argv-marker-conflict" }
            } else if (s in attached) {
                cls = "unregistered"; act = "report"; owner = s; ev = "env,live-parent"
            } else if (ppid[root] == "1" && (s in gone_sid) && !(s in maybe_sid)) {
                cls = "dead-owner"; act = "report"; owner = s
                ev = "env,registry-gone,orphaned"
            } else if (ppid[root] == "1") {
                # Orphaned, but no registry entry shows its session process
                # gone: an unregistered or mismatched live session looks the same.
                cls = "unknown"; act = "report"; owner = s
                ev = "env," (s in stale_sid ? "registry-stale" : "registry-absent") ",orphaned,death-unproven"
            } else {
                cls = "unknown"; act = "report"; owner = s; ev = "env,subreaper=" ppid[root]
            }
            if ((p in protect) && (act != "report" || cls == "dead-owner")) { cls = "unknown"; act = "report"; ev = ev ",session-process" }
            # A docket step id in the argv or cwd ties the process to a lane
            # step; the conductor checks that step before naming the pid.
            st = ""
            if (match(cmd[p], /STEP-[0-9]+/)) st = substr(cmd[p], RSTART, RLENGTH)
            else if (match(cwd[p], /STEP-[0-9]+/)) st = substr(cwd[p], RSTART, RLENGTH)
            if (st != "") ev = ev ",step=" st
            cnt[cls]++
            printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", cls, act, p, ppid[p], owner, ev, cwd[p], cmd[p]
        }
        printf "summary\tsource=%s\tsession=%s\tregistry=%s\tforeign=%d\n", (source == "" ? "-" : source), (cur == "" ? "-" : cur), (registry_ok ? "ok" : "unusable"), foreign
        nc = split("own-shell own-detached own-service sibling sibling-detached unregistered unknown dead-owner", classes, " ")
        for (i = 1; i <= nc; i++) printf "summary\tcount\t%s\t%d\n", classes[i], cnt[classes[i]]
    }' "$2" "$1" > "$work/rows"
    grep -v '^summary	' "$work/rows" | sort -t "$(printf '\t')" -k1,1 -k3,3n
    grep '^summary	' "$work/rows"
}

# ---- main --------------------------------------------------------------------

work=$(mktemp -d "${TMPDIR:-/tmp}/proc_supervise.XXXXXX") || die "mktemp failed" 4
trap 'rm -rf "$work"' EXIT

if [ -n "$snapshot" ]; then
    [ -r "$snapshot" ] || die "cannot read snapshot $snapshot" 4
    cp "$snapshot" "$work/snap"
else
    live_snapshot > "$work/snap" || die "no process table: ps and lsof both unavailable" 4
fi
if [ "$mode" = snapshot ]; then
    cat "$work/snap"
    exit 0
fi
if [ "$mode" = kill ] && [ -z "$dry_run" ]; then
    grep -q '^#source	ps$' "$work/snap" \
        || die "refused: no start times in this table (lsof fallback), so a reused pid cannot be ruled out" 3
fi
sessions_table | LC_ALL=C sort > "$work/sess"
LC_ALL=C classify "$work/snap" "$work/sess" > "$work/plan"
cat "$work/plan"
[ "$mode" = inventory ] && exit 0

# kill: each named pid that is a `stop` row, with its listed descendants,
# parents first; a named pid that is anything else is refused.
LC_ALL=C awk -F '\t' -v pids="$pids" '
    $1 == "summary" { next }
    { cls[$3] = $1; act[$3] = $2; par[$3] = $4 }
    END {
        n = split(pids, want, " ")
        for (i = 1; i <= n; i++) {
            p = want[i]
            if (!(p in cls)) { printf "R\trefuse\t%s\t-\tnot-listed\n", p; continue }
            if (act[p] != "stop") { printf "R\trefuse\t%s\t%s\tnot-a-target\n", p, cls[p]; continue }
            named[p] = 1
        }
        for (q in cls) {
            if (act[q] != "stop") continue
            d = 0; r = q; hit = 0; guard = 0
            while ((r in cls) && guard++ < 4096) { if (r in named) hit = 1; d++; r = par[r] }
            if (hit) printf "T\t%d\t%s\t%s\n", d, q, cls[q]
        }
    }' "$work/plan" > "$work/sel"
grep '^R	' "$work/sel" | cut -f2- | sort -t "$(printf '\t')" -k2,2n
grep '^T	' "$work/sel" | cut -f2- | sort -t "$(printf '\t')" -k1,1n -k2,2n | cut -f2- > "$work/targets"
count=$(wc -l < "$work/targets" | tr -d ' ')
if [ -n "$dry_run" ]; then
    printf 'dry-run\t%s target(s)\tsignal=%s\n' "$count" "$signal"
    awk -F '\t' -v sig="$signal" '{ printf "would-signal\t%s\t%s\t%s\n", sig, $1, $2 }' "$work/targets"
    exit 0
fi
while IFS="$(printf '\t')" read -r pid cls; do
    want=$(awk -F '\t' -v p="$pid" '$1 == p { print $4; exit }' "$work/snap" | sed 's/  */ /g')
    now=$(TZ=UTC ps -o lstart= -p "$pid" 2>/dev/null | sed 's/^ *//; s/ *$//; s/  */ /g')
    if [ -z "$now" ]; then
        printf 'skip\t%s\t%s\tgone\n' "$pid" "$cls"
    elif [ "$now" != "$want" ]; then
        printf 'skip\t%s\t%s\tstart-time-changed\n' "$pid" "$cls"
    elif kill "-$signal" "$pid" 2>/dev/null; then
        printf 'signal\t%s\t%s\t%s\n' "$signal" "$pid" "$cls"
    else
        printf 'skip\t%s\t%s\tsignal-refused\n' "$pid" "$cls"
    fi
done < "$work/targets"
exit 0
