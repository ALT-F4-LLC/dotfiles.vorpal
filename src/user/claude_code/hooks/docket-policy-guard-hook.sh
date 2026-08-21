#!/bin/bash

# policy-guard (operator-approved 2026-08-17, DKT-V31 follow-up) — PreToolUse:
# Workflow. DENIES a Workflow launch whose args.policyText does not carry
# ~/.docket/config/policy.toml byte-for-byte (modulo the trailing newline that
# $(cat …) strips). The PostToolUse wave-audit advisory proved insufficient
# alone: on 2026-08-17 three governance panels and two waves ran on a
# ~76%-condensed policy while the advisory scrolled past unread. This is the
# containment half — it refuses BEFORE any seat or executor spawns; the
# wave-audit advisory remains the after-the-fact narrator.
#
# Second check (operator-approved 2026-08-20, DOT-298): the run pinned
# policy.toml at activation, and a mid-run `just activate` can drift disk away
# from that pin. The content check ties the launch to DISK; nothing tied disk
# to the PIN — a 33-agent wave once routed on a policy its run never pinned,
# found only by hand a day later. So before trusting disk, resolve the
# launching cwd's ACTIVE runs and ask the engine's own pin comparator
# (`docket run verify-pins`) whether policy.toml still matches. This runs
# FIRST: under drift, a conductor correctly relaunching the PINNED bytes would
# fail the disk content check, and the drift is the message worth seeing.
# Only the policy.toml pin is enforced here — other drifted refs already make
# every engine verb that reads them refuse; policy.toml is the one artifact
# that reaches a wave without passing through an engine verb.
# The deny is scoped to the run the launch SERVES (DOT-445): wave rows name
# their run outright; a tribunal's voteId resolves through its linked issues
# to the runs holding steps for them. Drift on a run this launch does not
# serve prints a stderr advisory and allows — an unrelated drifted zombie
# must not embargo every panel in the repo. A launch that cannot be
# POSITIVELY resolved to serve only other runs is still denied: on this one
# comparison ambiguity fails closed, because "cannot tell which run this
# serves" cannot rule the drifted run out.
#
# Fail-OPEN everywhere except a REAL mismatch: no jq, no policy file, a
# launch carrying no policyText (other workflows), no docket binary, no
# active run, a run with no policy.toml pin, no shasum, and malformed engine
# output all allow. The policyText presence gate is measured in Unicode
# codepoints via jq — never wc -m, which counts bytes under a non-UTF-8
# locale (policy.toml holds multi-byte chars) and would misread every clean
# launch, the exact false-alarm defect wave-audit just shed. The content
# check itself hashes raw bytes, where codepoint-vs-byte is moot: jq emits
# the decoded string as UTF-8 — the same bytes the file holds — so both
# sides feed shasum an identical stream whenever the text is clean.
# The same-length-substitution limit formerly accepted here was CLOSED
# (operator-approved 2026-08-21, DOT-474): the disk comparison is now
# SHA-256 content equality — args.policyText must hash-match the file's
# bytes as-is, or the file minus the trailing newline that $(cat …) strips.
# Evidence forcing the change: a conductor twice dropped the IDENTICAL
# 44-char sentence while the other 28,020 chars stayed byte-perfect; length
# caught that only because it was a pure deletion — an equal-length
# substitution, transposition, or balanced drop-and-duplicate would have
# sailed through onto the file that routes and judges every launch.

set -uo pipefail

HOOK_INPUT=$(cat 2>/dev/null || true)
[ -n "$HOOK_INPUT" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
POLICY="$HOME/.docket/config/policy.toml"
[ -f "$POLICY" ] || exit 0

GOT=$(printf '%s' "$HOOK_INPUT" | jq -r '
  .tool_input.args
  | if type == "string" then (try fromjson catch {}) else (. // {}) end
  | .policyText // "" | length' 2>/dev/null)
{ [ -n "$GOT" ] && [ "$GOT" -gt 0 ]; } 2>/dev/null || exit 0

# ---- Pin backstop (DOT-298; deny scoped to the served run, DOT-445) ----
if command -v docket >/dev/null 2>&1; then
  HOOK_CWD=$(printf '%s' "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null)
  if [ -n "$HOOK_CWD" ] && [ -d "$HOOK_CWD" ]; then
    cd "$HOOK_CWD" 2>/dev/null || true
  fi
  ACTIVE=$(docket run status --active --json 2>/dev/null \
    | jq -r '.data.runs // [] | .[].run // empty' 2>/dev/null)
  # Which run(s) does this launch serve? Wave rows each carry .run; tribunal
  # args carry only voteId, resolved lazily inside the drift branch — it
  # costs docket calls and drift is the rare path.
  LAUNCH_ARGS=$(printf '%s' "$HOOK_INPUT" | jq -c '
    .tool_input.args
    | if type == "string" then (try fromjson catch {}) else (. // {}) end' 2>/dev/null)
  ROW_RUNS=$(printf '%s' "$LAUNCH_ARGS" | jq -r '
    [(.rows? // [])[]? | .run? // empty | select(type == "string")]
    | unique | .[]' 2>/dev/null)
  VOTE_ID=$(printf '%s' "$LAUNCH_ARGS" \
    | jq -r '.voteId? // empty | select(type == "string")' 2>/dev/null)
  LINKED=""
  for RUN in $ACTIVE; do
    VERDICT=$(docket run verify-pins "$RUN" --json 2>&1)
    DRIFT=$(printf '%s' "$VERDICT" \
      | jq -r 'select(.ok == false) | .error // empty' 2>/dev/null \
      | tr ';' '\n' | grep -F 'policy.toml changed:' | head -1)
    [ -n "$DRIFT" ] || continue
    # Drift is POSITIVELY established on $RUN. Allow only a launch POSITIVELY
    # resolved to serve other runs; every unresolved shape (no rows/voteId,
    # a vote show or step list that errors or comes back empty) keeps the
    # deny — unlike the file's precondition fail-opens, this one comparison
    # fails closed, per the header.
    SERVES=maybe
    if [ -n "$ROW_RUNS" ]; then
      # Wave launch: its rows name their run(s) outright.
      if printf '%s\n' "$ROW_RUNS" | grep -qxF "$RUN"; then
        SERVES=yes
      else
        SERVES=no
      fi
    elif [ -n "$VOTE_ID" ]; then
      # Tribunal launch: voteId -> linked_issues, intersected with the issues
      # the drifted run holds steps for. A vote linked to an issue the
      # drifted run carries serves that run — an activation vote shared
      # between a drifted zombie and its re-plan (the DKT-V118 shape) stays
      # denied; that ambiguity is the guard working. KNOWN LIMIT, accepted:
      # step list sees only EXPANDED steps, so an issue bound to the drifted
      # run in a not-yet-expanded later phase escapes the intersection.
      [ -n "$LINKED" ] || LINKED=$(docket vote show "$VOTE_ID" --json 2>/dev/null \
        | jq -r '.data.linked_issues // [] | .[] | select(type == "string")' 2>/dev/null)
      RUN_ISSUES=$(docket step list --run "$RUN" --json 2>/dev/null \
        | jq -r '[.data.steps // [] | .[].issue // empty] | unique | .[]' 2>/dev/null)
      if [ -n "$LINKED" ] && [ -n "$RUN_ISSUES" ]; then
        SERVES=no
        for ISSUE in $LINKED; do
          if printf '%s\n' "$RUN_ISSUES" | grep -qxF "$ISSUE"; then
            SERVES=yes
            break
          fi
        done
      fi
    fi
    DISPO="\`docket run abandon $RUN\` (ends it) or \`docket run repin $RUN\` (re-pins its remaining steps to current disk)"
    if [ "$SERVES" = "no" ]; then
      echo "policy-guard: advisory — $RUN pinned policy.toml at activation and disk no longer matches it (${DRIFT# }); this launch serves a different run and is allowed. Surface the drift to the operator: \`docket run verify-pins $RUN\` lists every drifted pin, and the dispositions are $DISPO." >&2
      continue
    fi
    echo "policy-guard: LAUNCH DENIED — $RUN pinned policy.toml at activation and disk no longer matches it (${DRIFT# }). A mid-run \`just activate\` is the usual cause. Launching now would route and judge on a policy the run never pinned. Stop this dispatch and surface the drift to the operator: \`docket run verify-pins $RUN\` lists every drifted pin, and the dispositions are $DISPO. Do not relaunch on the disk policy." >&2
    exit 2
  done
fi

# ---- Content check (DOT-474): SHA-256 over bytes, not length ----
command -v shasum >/dev/null 2>&1 || exit 0
[ -s "$POLICY" ] || exit 0
WANT_HASH=$(shasum -a 256 < "$POLICY" 2>/dev/null | awk '{print $1}') \
  || WANT_HASH=""
[ -n "$WANT_HASH" ] || exit 0

# Hash the decoded policyText straight off the jq pipe — same decode-args
# pattern as GOT above, never through a shell variable, whose $() capture
# strips trailing newlines and cannot hold every byte. jq -j emits the bare
# string (hash of the text as sent); jq -r appends one newline (hash of the
# text plus the trailing newline $(cat …) strips) — the same two-way accept
# the length check had as GOT == WANT / WANT - 1. pipefail is set above, so
# a failed decode trips the || and clears the hash: fail open, per the
# header — a hash computed from broken tooling is not a REAL mismatch.
GOT_HASH=$(printf '%s' "$HOOK_INPUT" | jq -j '
  .tool_input.args
  | if type == "string" then (try fromjson catch {}) else (. // {}) end
  | .policyText // ""' 2>/dev/null | shasum -a 256 2>/dev/null \
  | awk '{print $1}') || GOT_HASH=""
GOT_NL_HASH=$(printf '%s' "$HOOK_INPUT" | jq -r '
  .tool_input.args
  | if type == "string" then (try fromjson catch {}) else (. // {}) end
  | .policyText // ""' 2>/dev/null | shasum -a 256 2>/dev/null \
  | awk '{print $1}') || GOT_NL_HASH=""
{ [ -n "$GOT_HASH" ] && [ -n "$GOT_NL_HASH" ]; } || exit 0

if [ "$GOT_HASH" != "$WANT_HASH" ] && [ "$GOT_NL_HASH" != "$WANT_HASH" ]; then
  echo "policy-guard: LAUNCH DENIED — args.policyText does not match $POLICY byte-for-byte (modulo the trailing newline). Length alone no longer clears a launch: a same-size substitution or transposition hashes differently. A wave or panel launched on altered text routes and judges on the wrong tables. Re-run \`~/.claude/scripts/policy-escaped-chunks\` and rebuild policyText by copying its chunk lines verbatim — never by re-emitting the file from memory." >&2
  exit 2
fi
exit 0
