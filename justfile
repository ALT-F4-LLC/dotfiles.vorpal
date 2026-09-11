# Installing the corpus while a docket run is mid-flight drifts its pinned
# definitions (DOT-600; pin-closure engine issue DOT-596), so this checks
# `docket guard stop --all-projects` first and refuses on a denial. The check
# is skipped entirely when docket is not on PATH (bootstrap chicken-and-egg).
# Refuses while a docket run is active anywhere; override: `just activate force=1`
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
    "$(vorpal build --path 'user')/bin/vorpal-activate"

build:
    cargo build --locked --offline --all-targets

# The shell suites under tests/ are the guards for hooks, skills and workflow
# wiring; running them here keeps this gate asserting what CI asserts, instead
# of catching a relaxed guard only on the pull request.
tests:
    #!/usr/bin/env bash
    set -euo pipefail
    cargo test --locked --offline
    for suite in tests/*.test.sh; do
        echo "==> $suite"
        bash "$suite"
    done

self-hygiene:
    cargo fmt --all -- --check
    cargo clippy --locked --offline --all-targets -- -D warnings

secret-scan:
    .docket/bin/secret-scan

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
