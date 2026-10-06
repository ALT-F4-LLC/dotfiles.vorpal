# Pins vs disk

Consumer: the docket-run skill, whose **Pins vs disk** paragraph points
here. Read this file in full before presenting a pin-drift stop, and
before checking pins on a seat whose binary predates `run verify-pins`.

**Pins vs disk.** A run's pins are a third set of bytes that can disagree
with both source and install: the engine froze them at activation, and
every `just activate` since has moved the install out from under them. On
an already-active run, before the first dispatch, ask the engine about
the pins:

```bash
docket run verify-pins $RUN --json
```

That verb is read-only, safe on any run in any status, and answers for
every pin the run holds, unlike `step render` or payload validation,
which check only the refs they read. Read the exit code:

- **0**: every pin is sound. Proceed.
- **4**: drift. JSON carries `"code":"CONFLICT"` and an `error` naming
  each changed file with both hashes.
- **2**: a pinned ref no longer resolves at all.

Any non-zero exit is a stop-and-report: the engine resolves every row's
routing from the pinned bytes, so a drifted ref is refused wherever it is
read, and there is no route past drift. Do not substitute `docket step
render` for this check: it can exit 0 while a pin mismatch is present.

**Dispositions at a pin-drift stop-and-report, all four executable, none
run unprompted:**

- **Show the diffs.** Give the operator the drifted refs (`docket run
  verify-pins $RUN` names each with both hashes) and, where useful, the
  byte diff (the pinned bytes usually survive in the previous vorpal
  store generation).
- **Repin**: `docket run repin RUN-N --reason R`, when the operator
  judges the drift adoptable, typically their own additive corpus edit.
  It adopts current bytes as the run's pins for steps not yet claimed.
  The verb refuses without `--reason`, while any step is claimed, while a dispatch is open, on a done,
  abandoned, or fully-terminal run, and when a ref no longer resolves at
  all (restore the file instead). Completed steps' provenance is never
  rewritten; a `run-repinned` event carries old sha, new sha, and reason
  per changed ref. Repinning is all-or-nothing and a no-op with no drift.
- **Pause the run** (SKILL.md's **Pause mode**) and hand the decision back with a resume prompt.
- **Abandon and re-docket-plan**, re-pinning from scratch on current disk.

Repin moves the recorded agreement every future packet verifies against;
offer it as a disposition with the operator's reason, never on your own
judgment to unstick a dispatch.

**"Proceed anyway / accept the risk" is not one of them; never offer it.**
The hook refuses the relaunch outright. Re-activating is not a back door
either: it expands newly-unblocked phases only and inherits the original
pin set, by design, so in-flight work can rely on it.

**Fallback only, for a seat whose binary predates `run verify-pins`.**
Walk the pins by hand (`.data.pins`; `.data.steps` is a status/count
bucket, not step rows):

```bash
docket run status $RUN --json | jq -r '.data.pins // [] | map(select(.kind == "file"))
  | "file pins: \(length)",
    (.[] | "\(.ref) \(.sha256)")' \
  | { read -r count_line; echo "$count_line"; while read -r ref sha256; do
        path=~/.docket/config/"$ref"                  # name@version refs live in the DB, not on disk
        got_line=$(shasum -a 256 "$path" 2>/dev/null); got=${got_line%% *}
        [ -n "$got" ] && [ "$got" = "$sha256" ] || echo "PIN MISMATCH $ref disk ${got:-MISSING} pinned $sha256"
      done; }
```

This walk resolves refs under `~/.docket/config` only. A pin frozen from
the repository's `.docket/config/` reports `MISSING` here although it may
be sound; check it against that root by hand before calling it drift.

Count the rows before believing the verdict: `.pins[]` alone selects
nothing from `{data, ok}`, so zero file pins means your path is wrong, not
a clean run.
