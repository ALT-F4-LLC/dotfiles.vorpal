#!/bin/bash

# Behavior suite for the run-ready files-and-scope lint
# (skills/docket-groom/scripts/scope-lint.sh).
#
# WHY THIS EXISTS. Seven implement steps in one engine run parked because the
# fix needed a sibling `_test.go` or a doc file its acceptance criteria named,
# while the issue's `files` and `scope` left it out. docket-groom and
# docket-plan run this lint before calling an issue run-ready. Each rule has a
# failure that reads as success: a lint that checks only `files` passes an
# AC path no scope glob admits; one that lets `*` cross `/` passes a path a
# narrow glob excludes; one that ignores new files passes the doc file an AC
# asks the change to create; and one that never looks beside a scoped Go file
# passes the missing `_test.go`. The clean and prose cases keep the lint from
# refusing a ready issue.
#
# HOW. Builds a fixture repository under $TMPDIR, then feeds the lint a
# `docket issue show --json` envelope built with jq. Needs git, jq and awk;
# no network, no engine.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LINT="${SCOPE_LINT:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-groom/scripts/scope-lint.sh}"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1"; }
fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }

[ -f "$LINT" ] || fatal "scope-lint.sh not found at ${LINT}"
[ -x "$LINT" ] && pass "scope-lint.sh is executable" || fail "scope-lint.sh is not executable"
command -v git >/dev/null 2>&1 || fatal "git is required"
command -v jq >/dev/null 2>&1 || fatal "jq is required"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/docket-groom-scope-lint.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT
REPO="${WORK}/repo"
mkdir -p "${REPO}/src/pkg" "${REPO}/docs"
printf 'package pkg\n' > "${REPO}/src/pkg/x.go"
printf 'package pkg\n' > "${REPO}/src/pkg/x_test.go"
printf 'package pkg\n' > "${REPO}/src/pkg/y.go"
printf '# Guide\n' > "${REPO}/docs/guide.md"
git -C "$REPO" init -q
git -C "$REPO" -c user.email=t@t -c user.name=t -c commit.gpgsign=false add -A
git -C "$REPO" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m fixture
BASE=$(git -C "$REPO" rev-parse HEAD)

# lint <criteria> <files, one per line> <scope globs, one per line>: runs the
# lint on an issue whose body is a prose paragraph naming docs/prose-only.md
# followed by the criteria under an `## Acceptance criteria` heading. Exit
# status in $RC, stdout and stderr in $OUT.
lint() {
    local body
    body=$(printf 'Context lives in docs/prose-only.md.\n\n## Acceptance criteria\n\n%s\n' "$1")
    OUT=$(jq -n --arg d "$body" --arg f "$2" --arg s "$3" \
        '{ok: true, data: {id: "T-1", description: $d,
          files: ($f | split("\n") | map(select(. != ""))),
          scope: ($s | split("\n") | map(select(. != "")))}}' |
        bash "$LINT" --base "$BASE" --repo "$REPO" 2>&1)
    RC=$?
}
expect_clean() { # <label>
    if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then pass "$1 (exit 0, no output)"
    else fail "$1 (want exit 0 with no output, got exit ${RC}: ${OUT})"
    fi
}
expect_line() { # <text> <label>: exit 1 and a line containing <text>
    if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qF -- "$1"; then pass "$2 (exit 1 names $1)"
    else fail "$2 (want exit 1 naming $1, got exit ${RC}: ${OUT})"
    fi
}

# AC-5: files and scope cover every AC-named path, a new file in an existing
# directory included, and the sibling test of x.go.
lint "- [ ] AC-1: \`src/pkg/x.go\` handles the case; docs/guide.md:1 \`# Guide\` and docs/new.md document it." \
    "$(printf 'src/pkg/x.go\ndocs/guide.md\ndocs/new.md')" \
    "$(printf 'src/pkg/**\ndocs/*.md')"
expect_clean "every AC path and the sibling test covered"

# AC-2: an AC path that `files` omits, while scope still admits it.
lint "- [ ] AC-1: docs/guide.md explains the flag." \
    "src/pkg/x.go" \
    "$(printf 'src/pkg/**\ndocs/**')"
expect_line "missing from files: docs/guide.md" "an AC path missing from files"
case "$OUT" in
    *scope*docs/guide.md* | *docs/guide.md*scope*) fail "a path the scope admits is also reported as out of scope: ${OUT}" ;;
    *) pass "a path the scope admits is not reported as out of scope" ;;
esac

# AC-2: a file the change must create is a repository path too.
lint "- [ ] AC-1: docs/new.md records the decision." \
    "docs/guide.md" \
    "docs/**"
expect_line "missing from files: docs/new.md" "a new AC-named file missing from files"

# AC-3: an AC path that no scope glob matches.
lint "- [ ] AC-1: docs/guide.md explains the flag." \
    "docs/guide.md" \
    "src/**"
expect_line "outside scope: docs/guide.md" "an AC path outside every scope glob"

# AC-3: `*` stays within one path segment, so src/*.go leaves src/pkg/x.go out.
lint "- [ ] AC-1: src/pkg/x.go returns the error." \
    "src/pkg/x.go" \
    "$(printf 'src/*.go\nsrc/pkg/x_test.go')"
expect_line "outside scope: src/pkg/x.go" "a single-star glob does not cross a directory"

# AC-4: x.go is in files, x_test.go exists beside it, and no glob matches it.
lint "- [ ] AC-1: the parser rejects empty input." \
    "src/pkg/x.go" \
    "src/pkg/x.go"
expect_line "outside scope: src/pkg/x_test.go" "a sibling _test.go outside every scope glob"

# A Go file with no test beside it needs no test in scope.
lint "- [ ] AC-1: the parser rejects empty input." \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_clean "a Go file with no sibling test"

# Brace globs match each alternative.
lint "- [ ] AC-1: src/pkg/x.go and docs/guide.md agree." \
    "$(printf 'src/pkg/x.go\ndocs/guide.md')" \
    "{src/pkg,docs}/**"
expect_clean "a brace glob covers both alternatives"

# Prose outside the criteria section, URLs, host:ports, relative paths that
# leave the repository, and dotted words are not repository paths.
lint "- [ ] AC-1: per https://example.com/docs/guide.md, ../docs/guide.md and 127.0.0.1:8080, e.g. src/pkg/y.go stays put." \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_clean "non-repository tokens and prose outside the criteria"

# A base that is not a commit, or input that is not an issue envelope, is a
# usage error, not a pass.
OUT=$(printf '{"data":{"description":"","files":[],"scope":[]}}' |
    bash "$LINT" --base 0000000000000000000000000000000000000000 --repo "$REPO" 2>&1)
RC=$?
[ "$RC" -eq 2 ] && pass "an unknown base exits 2" || fail "an unknown base exits ${RC}: ${OUT}"
OUT=$(printf 'not json\n' | bash "$LINT" --base "$BASE" --repo "$REPO" 2>&1)
RC=$?
[ "$RC" -eq 2 ] && pass "input that is not an issue envelope exits 2" || fail "malformed input exits ${RC}: ${OUT}"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
