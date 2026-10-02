#!/bin/bash

# Every docket workflow with a changelog must open that changelog at its
# current version: the first `## <version>` heading of changelogs/<name>.md
# equals `[pipeline] version` in workflows/<name>.toml. A version bump without
# a changelog entry, or a changelog entry without a bump, fails here instead
# of surviving until someone reads both files.
#
# Only workflow/changelog PAIRS are compared. A changelog with no workflow of
# the same name (policy.md tracks policy.toml) is not checked, and neither is
# a workflow with no changelog.
#
# WORKFLOWS_DIR and CHANGELOGS_DIR override the inputs, so a mutation probe can
# point the suite at deliberately-broken COPIES under $TMPDIR without touching
# the checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG="${SCRIPT_DIR}/../src/user/docket/config"
WORKFLOWS="${WORKFLOWS_DIR:-${CONFIG}/workflows}"
CHANGELOGS="${CHANGELOGS_DIR:-${CONFIG}/changelogs}"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/workflow-changelog-version.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

# The `version` value inside the `[pipeline]` table only; a `version` key in
# any other table is ignored.
pipeline_version() { # <workflow.toml>
    awk '
        /^[[:space:]]*\[/ {
            table = $0
            sub(/^[[:space:]]*/, "", table)
            sub(/[[:space:]]*(#.*)?$/, "", table)
            next
        }
        table == "[pipeline]" && /^[[:space:]]*version[[:space:]]*=/ {
            v = $0
            sub(/^[^=]*=[[:space:]]*/, "", v)
            sub(/[[:space:]]*(#.*)?$/, "", v)
            gsub(/"/, "", v)
            print v
            exit
        }
    ' "$1"
}

# The first word after `## ` on the changelog's first level-2 heading.
changelog_version() { # <changelog.md>
    awk '/^## / { print $2; exit }' "$1"
}

# Compare every workflow/changelog pair, printing a FAIL line naming each
# workflow that disagrees. Returns 0 when every pair matches, 1 on a mismatch,
# and 2 when an input makes the comparison impossible.
compare_versions() { # <workflows-dir> <changelogs-dir>
    local workflows="$1" changelogs="$2" status=0 toml name changelog want got
    local pairs=0

    if [ ! -d "$workflows" ]; then
        echo "FAIL: no workflows directory at ${workflows}"
        return 2
    fi
    if [ ! -d "$changelogs" ]; then
        echo "FAIL: no changelogs directory at ${changelogs}"
        return 2
    fi

    shopt -s nullglob
    for toml in "$workflows"/*.toml; do
        name=$(basename "$toml" .toml)
        changelog="${changelogs}/${name}.md"
        [ -f "$changelog" ] || continue
        pairs=$((pairs + 1))

        want=$(pipeline_version "$toml")
        got=$(changelog_version "$changelog")
        if [ -z "$want" ]; then
            echo "FAIL ${name}: no [pipeline] version in ${name}.toml"
            status=1
        elif [ -z "$got" ]; then
            echo "FAIL ${name}: no ## heading in ${name}.md"
            status=1
        elif [ "$want" != "$got" ]; then
            echo "FAIL ${name}: [pipeline] version ${want}, changelog opens at ## ${got}"
            status=1
        fi
    done
    shopt -u nullglob

    if [ "$pairs" -eq 0 ]; then
        echo "FAIL: no workflow under ${workflows} has a changelog under ${changelogs}"
        return 2
    fi
    return "$status"
}

fail=0

# ---- The real tree ----------------------------------------------------
if out=$(compare_versions "$WORKFLOWS" "$CHANGELOGS"); then
    echo "ok   every workflow's [pipeline] version opens its changelog"
else
    printf '%s\n' "$out"
    fail=1
fi

# ---- The suite's own honesty check ------------------------------------
# The real tree only exercises the passing path. These fixtures pin that a
# mismatch is reported, by name, and that a matching pair is not.
FIX="${WORK}/fixtures"

# <dir> <name> <toml-version> <changelog-heading-version> [<later-table-version>]
make_pair() {
    local dir="$1" name="$2" version="$3" heading="$4" later="${5:-}"
    mkdir -p "${dir}/workflows" "${dir}/changelogs"
    {
        printf '[pipeline]\nname = "%s"\nversion = %s\n' "$name" "$version"
        if [ -n "$later" ]; then
            printf '\n[[step]]\nversion = %s\n' "$later"
        fi
    } > "${dir}/workflows/${name}.toml"
    printf '# %s changelog\n\n## %s\n\nEntry.\n\n## 1\n\nOlder entry.\n' \
        "$name" "$heading" > "${dir}/changelogs/${name}.md"
}

make_pair "${FIX}/matched" alpha 3 3
make_pair "${FIX}/mismatched" alpha 3 3
make_pair "${FIX}/mismatched" beta 4 3
make_pair "${FIX}/other-table" alpha 3 3 99
make_pair "${FIX}/orphan-changelog" alpha 3 3
printf '# policy changelog\n\n## 7\n' > "${FIX}/orphan-changelog/changelogs/policy.md"
make_pair "${FIX}/no-version" alpha 3 3
printf '[pipeline]\nname = "alpha"\n' > "${FIX}/no-version/workflows/alpha.toml"
make_pair "${FIX}/no-heading" alpha 3 3
printf '# alpha changelog\n\nEntry.\n' > "${FIX}/no-heading/changelogs/alpha.md"
make_pair "${FIX}/neither" alpha 3 3
printf '[pipeline]\nname = "alpha"\n' > "${FIX}/neither/workflows/alpha.toml"
printf '# alpha changelog\n\nEntry.\n' > "${FIX}/neither/changelogs/alpha.md"
make_pair "${FIX}/no-changelogs" alpha 3 3
rm -r "${FIX}/no-changelogs/changelogs"
make_pair "${FIX}/unpaired" alpha 3 3
mv "${FIX}/unpaired/changelogs/alpha.md" "${FIX}/unpaired/changelogs/policy.md"

# Assert both the status and the exact output: a comparison that always
# matches fails the mismatch case, and one that always fails fails the rest.
expect_versions() { # <label> <status> <fixture-dir> [<expected line>...]
    local label="$1" want_status="$2" dir="$3"
    shift 3
    local out got want_out=''
    if [ "$#" -gt 0 ]; then
        want_out=$(printf '%s\n' "$@")
    fi
    out=$(compare_versions "${dir}/workflows" "${dir}/changelogs")
    got=$?
    if [ "$got" = "$want_status" ] && [ "$out" = "$want_out" ]; then
        echo "ok   self-check ${label}"
        return 0
    fi
    echo "FAIL self-check ${label}: expected status ${want_status}, got ${got}"
    echo "     expected output:"
    printf '%s\n' "$want_out" | sed 's/^/       /'
    echo "     actual output:"
    printf '%s\n' "$out" | sed 's/^/       /'
    return 1
}

expect_versions "matching pair" 0 "${FIX}/matched" || fail=1
expect_versions "version bumped past its changelog" 1 "${FIX}/mismatched" \
    "FAIL beta: [pipeline] version 4, changelog opens at ## 3" || fail=1
expect_versions "version key in a later table" 0 "${FIX}/other-table" || fail=1
expect_versions "changelog with no workflow" 0 "${FIX}/orphan-changelog" || fail=1
expect_versions "missing workflows directory" 2 "${FIX}/absent" \
    "FAIL: no workflows directory at ${FIX}/absent/workflows" || fail=1
expect_versions "workflow with no version" 1 "${FIX}/no-version" \
    "FAIL alpha: no [pipeline] version in alpha.toml" || fail=1
expect_versions "changelog with no heading" 1 "${FIX}/no-heading" \
    "FAIL alpha: no ## heading in alpha.md" || fail=1
expect_versions "no version and no heading" 1 "${FIX}/neither" \
    "FAIL alpha: no [pipeline] version in alpha.toml" || fail=1
expect_versions "missing changelogs directory" 2 "${FIX}/no-changelogs" \
    "FAIL: no changelogs directory at ${FIX}/no-changelogs/changelogs" || fail=1
expect_versions "no workflow/changelog pair" 2 "${FIX}/unpaired" \
    "FAIL: no workflow under ${FIX}/unpaired/workflows has a changelog under ${FIX}/unpaired/changelogs" || fail=1

if [ "$fail" -ne 0 ]; then
    echo "workflow-changelog-version: FAIL — see the FAIL lines above." >&2
    exit 1
fi

echo "workflow-changelog-version: PASS"
