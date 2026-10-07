# Installing the corpus while a docket run is mid-flight drifts its pinned
# definitions (DOT-600; pin-closure engine issue DOT-596), so this checks
# `docket guard stop --all-projects` first and refuses on a denial. The check
# is skipped entirely when docket is not on PATH (bootstrap chicken-and-egg).
# Refuses while a docket run is active anywhere, or while this project's run has
# an integrated commit awaiting review; override: `just activate force=1`
activate force="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -z '{{force}}' ] && command -v docket >/dev/null 2>&1; then
        guard_status=0
        guard_reason="$(docket guard stop --all-projects 2>&1)" || guard_status=$?
        if [ "$guard_status" -ne 0 ]; then
            {
                echo "refusing to activate: a docket run is active somewhere on this machine,"
                echo "and installing the corpus now would drift its pinned definitions (DOT-600)."
                if [ -n "$guard_reason" ]; then
                    echo "guard: $guard_reason"
                fi
                echo "pause the run(s) first, or override with: just activate force=1"
            } >&2
            exit 1
        fi
    fi
    # `guard stop` admits a paused or waiting-human run, but a write step that
    # run already integrated into this checkout may still be under review, and
    # installing now would make its unreviewed hooks live everywhere. Refuse
    # while any step on such an issue is unfinished (not done, skipped or
    # superseded). A read that fails or comes back partial refuses too: it
    # cannot show that nothing awaits review.
    if [ -z '{{force}}' ] && command -v docket >/dev/null 2>&1; then
        refuse_unreviewed() {
            {
                echo "refusing to activate: $1"
                echo "finish the review first, or override with: just activate force=1"
            } >&2
            exit 1
        }
        command -v jq >/dev/null 2>&1 \
            || refuse_unreviewed "jq is missing, so integrated commits awaiting review cannot be checked."
        unreadable="cannot read docket state to check integrated commits awaiting review"
        # The same fail-closed rules docket-run-guard-hook.sh applies to this
        # envelope, restated here rather than shared: the hook ships in the
        # installed corpus, and this recipe runs from the checkout. One id per
        # line, so no id is ever word-split.
        runs=$(docket run status --limit 0 --json | jq -er '
            select(.ok == true) | .data
            | select((.runs | type) == "array" and .total == (.runs | length))
            | select(all(.runs[];
                (.run | type) == "string" and (.run | test("^RUN-[0-9]+$"))))
            | select(([.runs[].run] | unique | length) == (.runs | length))
            | [.runs[].run] | join("\n")') \
            || refuse_unreviewed "$unreadable (run status)."
        while read -r run <&3; do
            [ -n "$run" ] || continue
            # Done steps on issues that still have an unfinished step, each as
            # "<step> <first unfinished step on its issue>", both ids checked.
            candidates=$(docket step list --run "$run" --json | jq -er '
                select(.ok == true) | .data
                | select((.steps | type) == "array" and .total == (.steps | length))
                | .steps
                | [.[] | select(.status | IN("done", "skipped", "superseded") | not)] as $open
                | [.[] | select(.status == "done") as $s
                    | ($open | map(select(.issue == $s.issue)) | first) as $o
                    | select($o != null) | [$s.step, $o.step]]
                | select(all(.[]; .[0] | type == "string" and test("^STEP-[0-9]+$")))
                | select(all(.[]; .[1] | type == "string" and test("^STEP-[0-9]+$")))
                | map(join(" ")) | join("\n")') \
                || refuse_unreviewed "$unreadable (step list $run)."
            while read -r step open_step; do
                [ -n "$step" ] || continue
                sha=$(docket step show "$step" --json=v2 | jq -er '
                    select(.ok == true) | .data | .metadata.integrated_sha // ""') \
                    || refuse_unreviewed "$unreadable (step show $step)."
                if [ -n "$sha" ]; then
                    refuse_unreviewed "$run's $step integrated $sha into main, and $open_step on its issue is unfinished, so that commit has not finished review."
                fi
            done <<< "$candidates"
        done 3<<< "$runs"
    fi
    "$(vorpal build --path 'user')/bin/vorpal-activate"
    # Installing the corpus moves no registry. Report every project's drift
    # now, so it is seen at the moment it appears; /docket-reconcile fixes it.
    if command -v docket >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        echo "==> docket registry drift (report only; /docket-reconcile applies it)"
        python3 src/user/claude_code/skills/docket-reconcile/scripts/reconcile_plan.py --all-projects --summary \
            || echo "warning: registry drift report failed; run /docket-reconcile" >&2
    fi

build:
    cargo build --locked --offline --all-targets

# The shell suites under tests/ are the guards for hooks, skills and workflow
# wiring; running them here keeps this gate asserting what CI asserts, instead
# of catching a relaxed guard only on the pull request.
tests:
    #!/usr/bin/env bash
    set -euo pipefail
    # `docket step record` runs this recipe again as its `tests` gate, on the
    # commit the executor ran it on minutes before. Under a wave of writers
    # that second run cost about three minutes a step and was the one that hit
    # the gate's five-minute timeout. So a full pass on a clean tree stamps the
    # tree's hash in this checkout's git directory, and the `tests` gate
    # (DOCKET_GATE=tests) on that same clean tree reuses a stamp younger than
    # TESTS_REUSE_MAX_AGE seconds instead of running the suites again.
    # Executor, judge and CI runs never reuse, nor does another gate that runs
    # this recipe, such as an issue's acceptance commands; TESTS_NO_REUSE=1
    # forces a run.
    tree=
    stamps=
    if git rev-parse --git-dir >/dev/null 2>&1 && [ -z "$(git status --porcelain)" ]; then
        tree=$(git rev-parse 'HEAD^{tree}')
        stamps="$(git rev-parse --git-dir)/tests-pass"
    fi
    if [ -n "$tree" ] && [ "${DOCKET_GATE:-}" = tests ] && [ -z "${TESTS_NO_REUSE:-}" ] && [ -f "$stamps/$tree" ]; then
        stamped_at=
        stamped_commit=
        read -r stamped_at stamped_commit < "$stamps/$tree" || true
        case "$stamped_at" in ''|*[!0-9]*) stamped_at=0 ;; esac
        age=$(( $(date +%s) - stamped_at ))
        if [ "$age" -ge 0 ] && [ "$age" -le "${TESTS_REUSE_MAX_AGE:-7200}" ]; then
            echo "tests: REUSED the full pass of tree $tree (commit ${stamped_commit:-unknown}) from ${age}s ago; no suite ran. TESTS_NO_REUSE=1 forces a run."
            exit 0
        fi
    fi
    # Every suite runs even after one fails, so a single run names every
    # failure rather than only the first; the list is printed at the end.
    failed=()
    cargo test --locked --offline || failed+=("cargo test")
    # The suites commit into throwaway repos; keep those commits off the
    # operator's signing agent. Scoped to this recipe's process only. Appended
    # after the caller's env git config entries, which stay visible; the last
    # entry wins, so commit.gpgsign=false still applies.
    n=${GIT_CONFIG_COUNT:-0}
    export GIT_CONFIG_KEY_$n=commit.gpgsign GIT_CONFIG_VALUE_$n=false GIT_CONFIG_COUNT=$((n+1))
    # The suites run concurrently, at most TESTS_JOBS at a time (default: the
    # CPU count, capped at 8), so one run stays inside the tests gate's
    # timeout while several writers share the machine. Each suite's output
    # goes to its own log and is replayed in order, so the lines of two
    # suites never interleave. Every job is waited on by its own pid.
    max=${TESTS_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}
    [ "$max" -gt 8 ] && max=8
    logs=$(mktemp -d "${TMPDIR:-/tmp}/just-tests.XXXXXX")
    trap 'rm -rf "$logs"' EXIT
    pids=()
    names=()
    for suite in tests/*.test.sh; do
        while [ "$(jobs -rp | wc -l)" -ge "$max" ]; do
            sleep 0.1
        done
        bash "$suite" >"$logs/${#pids[@]}.log" 2>&1 </dev/null &
        pids+=("$!")
        names+=("$suite")
    done
    for i in "${!pids[@]}"; do
        echo "==> ${names[$i]}"
        wait "${pids[$i]}" || failed+=("${names[$i]}")
        cat "$logs/$i.log"
    done
    if [ "${#failed[@]}" -gt 0 ]; then
        printf 'FAILED: %s\n' "${failed[@]}" >&2
        exit 1
    fi
    # Stamp only the tree that was tested: a suite that left the tree dirty or
    # moved HEAD voids the stamp. One stamp per checkout bounds the directory.
    if [ -n "$tree" ] && [ -z "$(git status --porcelain)" ] && [ "$(git rev-parse 'HEAD^{tree}')" = "$tree" ]; then
        rm -rf "$stamps"
        mkdir -p "$stamps"
        printf '%s %s\n' "$(date +%s)" "$(git rev-parse HEAD)" > "$stamps/$tree"
    fi

# The project-supplied gate security-change binds on its write steps. Here the
# QA suite is the whole test suite: the gate scripts' own suites run under it.
qa-test:
    just tests

# The suites that pin exact skill sentences: a ruling, a trailer name, a
# halting verb, a mutant rule. A prose pass runs this after every landing so
# a reworded ruling fails here, in the pass that reworded it, not on the pull
# request. Every suite here also runs under `tests`. One recipe line rather
# than a shebang body: a shebang recipe needs a temp directory just cannot
# always create in a sandboxed session, and a gate that errors before it
# judges reads as green to the pass that runs it.
prose-gates:
    for suite in tests/*-skill.test.sh tests/*-attribution.test.sh tests/mutant-rule-crossref.test.sh; do echo "==> $suite"; bash "$suite" || exit 1; done

self-hygiene:
    cargo fmt --all -- --check
    cargo clippy --locked --offline --all-targets -- -D warnings

secret-scan:
    .docket/bin/secret-scan

# One gate per light track: the working-tree footprint must match the label the
# track binds on (docs only; one small edit; two files in one directory).
diff-scope-docs:
    .docket/bin/diff-scope docs-only

diff-scope-trivial:
    .docket/bin/diff-scope trivial

diff-scope-small:
    .docket/bin/diff-scope small

vuln-scan:
    .docket/bin/vuln-scan

sdet-abuse:
    .docket/bin/sdet-abuse

doc-validate:
    .docket/bin/doc-validate

# Shipped by the docket corpus and installed by `just activate`, so this is the
# one recipe reaching outside .docket/bin. Silenced with `@` because the engine
# hands the action a JSON bundle on stdin and parses exactly one JSON document
# back on stdout.
doc-record:
    @"$HOME/.docket/bin/doc-record"

citation-check:
    .docket/bin/citation-check

crossref-check:
    .docket/bin/crossref-check

tdd-preflight:
    .docket/bin/tdd-preflight

reserved-name-check:
    .docket/bin/reserved-name-check

ac-commands:
    .docket/bin/ac-commands

frozen-drift-check:
    .docket/bin/frozen-drift-check
