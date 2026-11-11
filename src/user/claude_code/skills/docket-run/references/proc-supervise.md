# Process supervision: proc_supervise.sh and docket-proc-guard

Consumer: the docket-run skill, whose **Shells** paragraph under **Seat** and
**An operator stop while a wave is in flight** point here. The script's header
carries the full contract (classes, death test, kill gate, platforms);
this file holds when the conductor uses it and the evidence it was built from.

## Contents

- [What it is for](#what-it-is-for) (13 lines)
- [Use](#use) (50 lines)
- [Attributing a detached process](#attributing-a-detached-process) (38 lines)
- [Audited scenarios](#audited-scenarios) (18 lines)
- [Capabilities with no audited scenario](#capabilities-with-no-audited-scenario) (21 lines)
- [Limits](#limits) (56 lines)

## What it is for

The conductor, its `Agent` helpers and its Workflow seats all run in one
Claude Code session process, so every Bash shell any of them starts descends
from that process. `TaskStop` reaches only the caller's own tasks. It cannot
stop an Agent helper's background shells or a `nohup` child, and inside the
Bash sandbox `ps`, `pgrep` and every signal to another process are refused.
`proc_supervise.sh` gives the conductor one inventory of the session's
processes, with a class for each one: own shell, sibling session's process,
unknown owner. Through the `docket-proc-guard` hook the conductor runs the
inventory and the kill outside the sandbox, the kill for named pids of this
session only. A sibling session's process, a process of unknown ownership
and a session process are never signalled. They are reported.

## Use

Inventory, from any seat (agents included):

```bash
bash ~/.claude/skills/docket-run/scripts/proc_supervise.sh inventory
```

Each row is `class action pid ppid owner evidence cwd command`. From the
conductor's main conversation the `docket-proc-guard` hook runs this exact
command outside the sandbox and returns the full `ps` table, with argv and
environment, sibling sessions' argv included. Anywhere
else (a subagent, a non-conductor, any other spelling) it runs in the
sandbox, where the table comes from `lsof`. That table lists every process
of the user with cwd and command name, but no argv or environment. A
detached process (S5, S7) is in it but cannot be attributed and is counted
foreign: the argv marker is read only from the hook's `ps` table. So a seat
that launches one with `nohup` or `&` follows the launch convention in
**Attributing a detached process** and records its pid. A
`step=STEP-N` in the evidence column, from argv or cwd, ties a shell to a
lane step; in the sandbox it comes from the cwd alone. The `summary count`
rows count processes by class, which is the answer to "why are there N
shells running?".

Before naming a pid to stop, the conductor checks who it belongs to. Age, or
"started before a compaction", is never ownership. A shell with a
`step=STEP-N` or a lane worktree cwd belongs to that step's executor: run
`docket step show STEP-N`, and leave the shell alone while the step is
claimed and its lane is live. Preview, then stop:

```bash
bash ~/.claude/skills/docket-run/scripts/proc_supervise.sh kill --dry-run --pid <root pid> [--pid ...]
bash ~/.claude/skills/docket-run/scripts/proc_supervise.sh kill --pid <root pid> [--pid ...]
```

A named pid takes its whole tree, parents first, so a loop shell cannot
start its next iteration. Both commands must be exactly that shape: no
chain, pipe, redirect, quote or extra flag. The `docket-proc-guard` hook runs
them outside the sandbox and returns the output as a `PreToolUse:Bash hook
error`: the plan for the dry run, the `signal`/`skip`/`refuse` rows for the
kill. That error is the result, not a failure, and is not reissued. The hook
runs them only for a session whose scratchpad holds a non-empty
`conductor.d/RUN-<n>.token`, so stop leftover shells before the run end
removes the token. That is a filesystem test, not an engine check. A
subagent's or any other session's kill is denied. PreToolUse
hooks run side by side and before the permission layer, so another hook or
the permission mode binds only the sandboxed call, not what this hook ran.
`--signal KILL` is for a tree that ignored `TERM` (see **Capabilities with
no audited scenario**). Re-run the inventory to confirm: a child a loop
forked after the snapshot is not in the plan.

## Attributing a detached process

On Darwin the Bash sandbox hides a process's environment from `ps -E` but
not its argv, so the chosen source is an argv marker launch convention: a
`docket-session=<uuid>` token that is the final argument of a shell `-c`
wrapper, where the wrapper is the detached process or one of its ancestors
up to its orphan root. A seat that detaches a job launches it as
`nohup sh -c '<cmd>; exit $?' "docket-session=$CLAUDE_CODE_SESSION_ID" >log 2>&1 &`,
with `setsid` in place of `nohup` on Linux. The trailing `exit $?` keeps the
wrapper alive, so its children carry the marker through ancestry, and the
convention spells the variable, never a literal id. The token is not
`CLAUDE_CODE_SESSION_ID=<uuid>`, because the Darwin `ps -E` reader matches
that string anywhere on the line and would read the launching shell as a
session process. Six candidates were rejected. `env
CLAUDE_CODE_SESSION_ID=$ID nohup <cmd>`: `env` and `nohup` exec their
command, so the marker is gone from the surviving argv. The pgid of a live
own-shell root: while that shell lives, ancestry already classes the tree
own-shell; after it dies, the pgid names a dead, reusable pid, and `setsid`
changes the pgid anyway. A launcher pid file: the sandboxed launcher cannot
read its child's start time, so the file cannot rule out pid reuse, and the
real kill would have to trust a caller-written file. A marker as a trailing
argument of the command itself: any command that rejects an extra argument
fails. The stdout fd or cwd under the session scratchpad: cwd alone is not
ownership, and an fd source needs a new snapshot column and an unverified
`lsof` read. `exec -a` renaming argv[0]: a shebang script loses it.

A detached process with no environment id is own-detached (`stop`,
evidence `argv-marker,registry-live`) only when the walk from it to its
orphan root meets no nested session process and every marker and
environment id on that chain names the current session. With the registry
unusable it is `unknown`, as is a marked wrapper that is an ancestor of a
session process. A marker naming another session, markers that
disagree, a differing environment id on the chain, a marker on a non-shell
process, or no marker leaves it foreign: counted in `foreign=` and refused
`not-listed`. A process whose environment carries the current id beside
another session's marker is `unknown`, so a conflict never makes a stop.
Ancestry outranks the marker: a tree under a live session process is
classed by that session.

## Audited scenarios

Every row is an intervention found in `~/.claude`; the `~/.docket` audit
found none (its store held no rows that record one). Each row maps
to cases in `tests/docket-run-proc-supervise.test.sh` (the S-number leads the
case label). H is `~/.claude/history.jsonl`; P is
`~/.claude/projects/-Users-erikreinert-Development-repository-github-com-ALT-F4-LLC-`.

| S | What happened | Evidence | What the script does |
|---|---|---|---|
| S1 | An Agent helper's four background suite loops loaded the machine ("The shells running right now are putting large load on the system making the fans run loud"); the conductor's `TaskStop` could not reach them and the helper's `pkill` was refused by the sandbox; the operator was told to `! pkill` | P`dotfiles-vorpal-git-main/aab7ddfc-f892-48bf-9134-f49ff7c4d431.jsonl:2000`, `:2017`, `:2042`; its `subagents/agent-ac3783fe8002a604a.jsonl:171` | classes the helper's shells own-shell; `kill --pid <root>` stops the tree from the hook |
| S2 | "I see a lot of shells right now running": `tail -f \| grep -m1` followers of finished test runs, load 25 to 56 | P`docket-git-feature-engine-improvements/1b58c2fd-3b00-4ff3-8a6e-9f1a7eeb3965.jsonl:18014` | lists the followers as own-shell with argv; stop by pid. Staleness is the conductor's call |
| S3 | The conductor stopped nine live executor shells as "left over from before the context reset"; their tests died with exit 137 | same transcript, `:23468` to `:23705` | no blanket stop (`kill` needs `--pid`); `step=` and cwd columns attribute each shell; the conductor checks the step first |
| S4 | A Bash call blocked on inherited stdin (`python3 -`) was auto-backgrounded and hung until "I see a shell process running" | P`docket-git-feature-docket-daemon/959a6484-7575-44dc-8a38-b3025f8ffdbe.jsonl:869`, `:964`, `:996` | lists it as own-shell; stop by pid. Hang detection is the conductor's call |
| S5 | "Why are there 14 shells running?": one conductor watcher, the rest executor and detached engine gate runs | P`docket-git-feature-docket-daemon/bd10139a-b6e3-4d11-b496-e8508cdd6cd2.jsonl:1137` | `summary count` rows by class; in the hook's `ps` table a detached run is own-detached when its environment carries this session's id or, on Darwin where the sandbox hides the environment, when it was launched under the argv marker convention (**Attributing a detached process**); a run with neither, or with another session's marker, is not listed (a run the engine detaches itself carries no marker), is counted in `foreign=`, and `kill --pid` refuses it `not-listed` |
| S6 | A watcher loop never fired; "The task was hung." and a hard halt | H`:6662` to `:6664` (transcript purged) | lists the loop as own-shell; stop by pid |
| S7 | A watcher started with `nohup &` escaped task tracking; `pkill -f watcher2.sh` was refused by the sandbox | P`docket-git-feature-engine-improvements/b29ca600-bd41-47bf-bdc9-c0cd9062c20a.jsonl:724` | classes it own-detached in the hook's `ps` table when it was launched as `nohup sh -c '<cmd>; exit $?' "docket-session=$CLAUDE_CODE_SESSION_ID"` (the argv marker; on Darwin the sandbox hides its environment id); on Darwin a bare `nohup watcher2.sh &` shows neither id nor marker, so it is not listed, is counted in `foreign=`, and `kill --pid` refuses it `not-listed`, and the conductor hands the recorded pid to the operator |
| S8 | "There are 37 shells open right now. This needs to be cleaned up." and seven more cleanup asks | H`:1472`, `:1543`, `:1663`, `:1669`, `:1726`, `:1759`, `:1982`, `:1990` (transcripts purged) | inventory across sessions; only this session's named pids move, a sibling's are refused |

## Capabilities with no audited scenario

These are reported here and are not built as actions, except the one
escalation noted:

- **Signals other than `TERM`.** No audited case needed more than `TERM`.
  `--signal INT|HUP|KILL` is built as an escalation for a tree that ignores
  `TERM`, and is unevidenced.
- **Reaping a dead session's orphans.** No audited case shows a process
  outliving its session. No PPID-1 reparent was ever observed, and the live
  machine showed no Claude-related orphan. The script classifies
  `dead-owner` under a four-part test (a registry entry must show the session
  process gone; an orphan without that is `unknown`) and reports it, but never
  signals it. The operator decides from the report.
- **Detecting a hung or stale shell** (S2, S4, S6): output-file mtime, a
  stdin reader, a watcher logging only errors. The inventory shows argv and
  cwd, and the conductor judges.
- **Load-average triggers** (S1, S2): the cases cite load but no automatic
  response.
- **Memory pressure and stray listeners**: one mention each (pageouts,
  daemon-socket timeouts), with no intervention.

## Limits

- Darwin is the supported platform. The Linux classifier is tested on a
  Linux-shaped table only; the `/proc` reader has never run, and the Linux
  registry's `procStart` format is unknown (a mismatch reads the registry
  unusable, so nothing is a target).
- In the Darwin Bash sandbox the table falls back to `lsof` (no argv,
  start time or environment). Ownership then comes from
  ancestry alone, any shell child of the session counts as own-shell, and
  `kill` is refused there; the hook runs it with `ps` outside the sandbox.
  With `ps`, own-shell needs the Bash tool's shell-snapshot marker in the
  root shell's argv.
- One real Darwin `ps` table, taken by the operator outside the sandbox,
  confirmed the shell-snapshot marker in Bash-tool shells and the
  registry's `procStart` as UTC `lstart` (the script reads `ps` with
  `TZ=UTC`). In that table no session descendant showed
  `CLAUDE_CODE_SESSION_ID` in `ps -E`. A later probe found the cause:
  `ps -E` shows no environment for a process in the Bash sandbox, though
  the variable is set there and the argv is visible. The `!` shell has
  the variable too, so it was not the cause. The operator's three
  diagnostics, run through `!`: `printenv CLAUDE_CODE_SESSION_ID` printed
  the session id; `ps -axww -E -o pid=,command= | grep -c
  CLAUDE_CODE_SESSION_ID` printed `4` (an upper bound: `grep` also matches
  argv, its own included, and no pids were captured); the snapshot's
  column-5 session-id count printed `1`. These rule out the `!` shell and
  the snapshot pipeline. The sandbox finding rests on the earlier per-pid
  probe: a sandboxed `sleep` showed no session id, and only an
  unsandboxed process (a `!` command) did. A run without `LC_ALL=C`
  matched the same, so `sed` was not at fault. Every Bash-tool shell is
  sandboxed, so on Darwin own-detached (S5, S7) comes from the argv marker
  alone (**Attributing a detached process**). Its limits all fail safe to
  foreign: a double fork, an `exec` inside the command string, or a wrapper
  that dies before its child loses the marker; the sandboxed `lsof` table
  has no argv, so only the hook's `ps` table attributes the job; and a job
  launched without the convention is still not listed, is counted in
  `foreign=`, and `kill --pid` refuses it `not-listed`, so the conductor
  hands its recorded pid to the operator. The marker is as forgeable as the
  environment variable by any same-user process, so the conductor still
  names each pid. The marker path is fixture-tested only: no live hook `ps`
  table for a job launched by the convention has been inspected.
- A nested session whose title is neither `claude` nor a version (`node
  cli.js -p`) and that has no child with its own id is not recognised; its
  tree reads as own-shell. With no session id in the environment (as in
  the real table) no child shows its own id, so only the title protects.
- Whether the harness truncates a long hook reason is unknown; the
  `summary` rows print last.
- A Linux orphan under a subreaper (`systemd --user`) is never dead-owner.
- The death test is not a proof. A crashed session's stale entry plus a
  live unregistered `claude -p --resume <id>` whose orphaned child carries
  that id reads dead-owner, and a Claude process whose executable path holds
  a space is not recognised by title. Check a dead-owner row before stopping
  it by hand.
- The kill re-reads each pid's start time and skips one that changed, so a
  reused pid is never signalled.
- The hook's paths are fixture-tested. They go live only after the
  operator runs `just activate`.
