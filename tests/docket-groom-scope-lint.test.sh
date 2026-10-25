#!/bin/bash

# Behavior suite for the run-ready files-and-scope lint
# (skills/docket-groom/scripts/scope-lint.sh).
#
# WHY THIS EXISTS. Seven implement steps in one engine run parked because the
# fix needed a sibling `_test.go` or a doc file its acceptance criteria named,
# while the issue's `files` and `scope` left it out. docket-groom and
# docket-plan run this lint before calling an issue run-ready. Each rule has a
# failure that reads as success: a lint that checks only `files` passes an
# AC path no scope glob admits; one whose glob rules differ from the engine's
# passes a path the engine keeps out of the diff; one that ignores new or
# extension-less files passes a path an AC asks the change to touch; one that
# ends the criteria early, or lists only a subdirectory, drops AC paths
# unread; and one that never looks beside a scoped Go file passes the missing
# `_test.go`. The clean and prose cases keep the lint from refusing a ready
# issue.
#
# The engine filters a step's diff by passing each scope glob to git as a
# pathspec, so the glob expectations below are git's pathspec results: a
# literal glob covers itself and everything under it, `*` crosses `/`, and
# braces are literal characters.
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
mkdir -p "${REPO}/src/pkg/deep" "${REPO}/docs" "${REPO}/bin"
printf 'package pkg\n' > "${REPO}/src/pkg/x.go"
printf 'package pkg\n' > "${REPO}/src/pkg/x_test.go"
printf 'package pkg\n' > "${REPO}/src/pkg/y.go"
printf 'package deep\n' > "${REPO}/src/pkg/deep/z.go"
printf '# Guide\n' > "${REPO}/docs/guide.md"
printf 'notes\n' > "${REPO}/docs/notes.txt"
printf 'notes\n' > "${REPO}/src/pkg/notes.txt"
printf '#!/bin/sh\n' > "${REPO}/bin/docket-workflow-claim"
printf 'tests:\n' > "${REPO}/justfile"
printf '# nothing ignored\n' > "${REPO}/.gitignore"
git -C "$REPO" init -q
git -C "$REPO" -c user.email=t@t -c user.name=t -c commit.gpgsign=false add -A
git -C "$REPO" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q -m fixture
BASE=$(git -C "$REPO" rev-parse HEAD)

# envelope <description> <files, one per line> <scope globs, one per line>:
# prints a `docket issue show --json` envelope for that issue.
envelope() {
    jq -n --arg d "$1" --arg f "$2" --arg s "$3" \
        '{ok: true, data: {id: "T-1", description: $d,
          files: ($f | split("\n") | map(select(. != ""))),
          scope: ($s | split("\n") | map(select(. != "")))}}'
}
# lint_body <description> <files> <scope> [lint args]: runs the lint on that
# issue against the fixture repository; trailing args (a later --repo
# overrides the default) go to the lint. Exit status in $RC, stdout and
# stderr in $OUT.
lint_body() {
    local description="$1" files="$2" scope="$3"
    shift 3
    OUT=$(envelope "$description" "$files" "$scope" |
        bash "$LINT" --base "$BASE" --repo "$REPO" "$@" 2>&1)
    RC=$?
}
# lint <criteria> <files> <scope>: lint_body on a body that is a prose
# paragraph naming docs/prose-only.md followed by the criteria under an
# `## Acceptance criteria` heading.
lint() {
    lint_body "$(printf 'Context lives in docs/prose-only.md.\n\n## Acceptance criteria\n\n%s\n' "$1")" "$2" "$3"
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

# AC-2: files without an extension, by path or at the repository root, and
# dotfiles are repository paths.
lint "- [ ] AC-1: bin/docket-workflow-claim refuses a stale lease." \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_line "missing from files: bin/docket-workflow-claim" "an extension-less AC path missing from files"
lint "- [ ] AC-1: the justfile and .gitignore list the target." \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_line "missing from files: justfile" "a root file without an extension missing from files"
expect_line "missing from files: .gitignore" "a dotfile missing from files"

# AC-2: a unique bare file name resolves to its path.
lint "- [ ] AC-1: guide.md explains the flag." \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_line "missing from files: docs/guide.md" "a unique bare file name missing from files"

# AC-2: a `#` line inside a fenced block does not end the criteria section.
lint "$(printf -- '- [ ] AC-1: the snippet runs:\n\n```sh\n# regenerate\nmake\n```\n\n- [ ] AC-2: docs/guide.md explains it.')" \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_line "missing from files: docs/guide.md" "an AC path after a fenced # line"

# AC-2: a fence closes only on its own marker, so a ~~~ line inside a ```
# fence leaves the # line fenced.
lint "$(printf -- '- [ ] AC-1: the snippet shows:\n\n```md\n~~~\n# comment\n~~~\n```\n\n- [ ] AC-2: docs/guide.md explains it.')" \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_line "missing from files: docs/guide.md" "an AC path after a fenced # line inside the other marker"

# AC-2: a ~~~ fence holds its # line like a ``` fence does.
lint "$(printf -- '- [ ] AC-1: the snippet runs:\n\n~~~sh\n# regenerate\nmake\n~~~\n\n- [ ] AC-2: docs/guide.md explains it.')" \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_line "missing from files: docs/guide.md" "an AC path after a # line in a ~~~ fence"

# AC-2: a line that opens and closes a backtick span opens no fence, so the
# real fence after it still holds its # line.
lint "$(printf -- '```x```\n\n```sh\n# comment\n```\n\n- [ ] AC-2: docs/guide.md explains it.')" \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_line "missing from files: docs/guide.md" "an AC path after an inline backtick span line"

# AC-2: a description with no criteria heading is checked whole.
lint_body "Update docs/guide.md to explain the flag." \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_line "missing from files: docs/guide.md" "a body with no criteria heading"

# AC-2: run against a subdirectory of the checkout, paths still resolve from
# the repository root.
lint_body "$(printf '## Acceptance criteria\n\n- [ ] AC-1: docs/guide.md explains the flag.\n')" \
    "src/pkg/y.go" \
    "src/pkg/y.go" \
    --repo "${REPO}/src"
expect_line "missing from files: docs/guide.md" "a --repo below the repository root"
# A new file's directory resolves from the repository root too.
lint_body "$(printf '## Acceptance criteria\n\n- [ ] AC-1: docs/new.md records the decision.\n')" \
    "src/pkg/y.go" \
    "src/pkg/y.go" \
    --repo "${REPO}/src"
expect_line "missing from files: docs/new.md" "a new file outside the --repo subdirectory"

# AC-2, file argument: the envelope may be named instead of piped.
envelope "$(printf '## Acceptance criteria\n\n- [ ] AC-1: docs/guide.md explains the flag.\n')" \
    "src/pkg/y.go" "src/pkg/y.go" > "${WORK}/issue.json"
OUT=$(bash "$LINT" --base "$BASE" --repo "$REPO" "${WORK}/issue.json" 2>&1)
RC=$?
expect_line "missing from files: docs/guide.md" "an envelope passed as a file argument"

# AC-3: an AC path that no scope glob matches.
lint "- [ ] AC-1: docs/guide.md explains the flag." \
    "docs/guide.md" \
    "src/**"
expect_line "outside scope: docs/guide.md" "an AC path outside every scope glob"

# A repaired envelope: docket-groom's judge replaces a criterion with its
# repair and lints the result, so a repair naming a path that neither `files`
# nor `scope` holds must fail before the caller applies it.
lint "- [ ] AC-1: src/pkg/y.go returns the error and docs/notes.txt records it." \
    "src/pkg/y.go" \
    "src/pkg/y.go"
if [ "$RC" -ne 0 ] && printf '%s\n' "$OUT" | grep -qF -- "docs/notes.txt"; then
    pass "a repaired criterion naming a path absent from files and scope (exit ${RC} names docs/notes.txt)"
else
    fail "a repaired criterion naming a path absent from files and scope (want non-zero exit naming docs/notes.txt, got exit ${RC}: ${OUT})"
fi

# AC-3: braces are literal in a git pathspec, so this glob matches nothing.
lint "- [ ] AC-1: src/pkg/y.go and docs/guide.md agree." \
    "$(printf 'src/pkg/y.go\ndocs/guide.md')" \
    "{src/pkg,docs}/**"
expect_line "outside scope: docs/guide.md" "a brace glob matches nothing"

# AC-3: `a/**/b` needs a directory between a and b, as git matches it.
lint "- [ ] AC-1: src/pkg/deep/z.go returns the error." \
    "src/pkg/deep/z.go" \
    "src/pkg/deep/**/z.go"
expect_line "outside scope: src/pkg/deep/z.go" "a/**/b does not cover a/b"

# AC-3: a negated character class excludes its characters.
lint "- [ ] AC-1: src/pkg/x.go returns the error." \
    "src/pkg/x.go" \
    "$(printf 'src/pkg/[!x].go\nsrc/pkg/x_test.go')"
expect_line "outside scope: src/pkg/x.go (named by" "a negated class excludes the named file"

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

# AC-5, git pathspec rules: `*` crosses `/`, `?` matches one character, and
# a literal directory covers everything under it, a new file included.
lint "- [ ] AC-1: src/pkg/x.go and src/pkg/deep/z.go return the error." \
    "$(printf 'src/pkg/x.go\nsrc/pkg/deep/z.go')" \
    "src/*.go"
expect_clean "a single star crosses directories"
lint "- [ ] AC-1: src/pkg/y.go returns the error." \
    "src/pkg/y.go" \
    "src/pkg/?.go"
expect_clean "a question mark matches one character"
lint "- [ ] AC-1: docs/guide.md and docs/new.md explain the flag." \
    "$(printf 'docs/guide.md\ndocs/new.md')" \
    "docs"
expect_clean "a literal directory covers the files under it"

# AC-3: a literal glob covers a path only at a directory boundary, so `doc`
# leaves docs/ out.
lint "- [ ] AC-1: docs/guide.md explains the flag." \
    "docs/guide.md" \
    "doc"
expect_line "outside scope: docs/guide.md" "a literal glob that is a prefix of a directory name"

# Prose outside the criteria section, a later section, URLs, host:ports,
# relative paths that leave the repository, dotted words, directories,
# ambiguous bare names, and extension-less words that are not root files
# exist at base as no file, so none is a repository path.
lint_body "$(printf 'Context lives in docs/prose-only.md.\n\n## Acceptance criteria\n\n- [ ] AC-1: per https://example.com/docs/guide.md, ../docs/guide.md and 127.0.0.1:8080, e.g. src/pkg/y.go stays put; notes.txt, docket-workflow-claim, the src/pkg package and/or tests too.\n\n## Notes\n\nSee docs/guide.md.\n')" \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_clean "non-repository tokens, prose outside the criteria, and a later section"

# A path the criteria only inspect, named after `inspect:`, needs no files
# or scope entry.
lint "- [ ] AC-1: src/pkg/y.go returns the error; inspect: docs/guide.md for the wording." \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_clean "a path named only after inspect:"

# Every marker exempts the paths that follow it, through commas, `and` and
# backticks.
lint "$(printf -- '- [ ] AC-1: src/pkg/y.go returns the error; Inspect: docs/guide.md, `docs/notes.txt` and bin/docket-workflow-claim.\n- [ ] AC-2: run on justfile; guide: src/pkg/notes.txt; the check runs over: .gitignore.')" \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_clean "paths after each inspect-only marker"

# `over` is ordinary English, so only `over:` marks a path as inspected: an
# edit target after a bare `over` is still checked.
lint "- [ ] AC-1: the installer copies over docs/guide.md." \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_line "missing from files: docs/guide.md" "a path after a bare over"
lint "- [ ] AC-1: src/pkg/y.go returns the error; the check runs over: docs/guide.md." \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_clean "a path named only after over:"

# A marker exempts only within its sentence: the edit target in the next
# sentence of the same line is still checked.
lint "- [ ] AC-1: inspect: docs/guide.md. Then src/pkg/y.go returns the error." \
    "docs/notes.txt" \
    "docs/notes.txt"
expect_line "missing from files: src/pkg/y.go" "an edit target after a marked sentence on the same line"
case "$OUT" in
    *docs/guide.md*) fail "a path after inspect: is reported: ${OUT}" ;;
    *) pass "a path after inspect: is not reported beside a same-line edit target" ;;
esac

# A sentence end or a punctuation gap ends the run on its own: an edit
# target right after a period, after `and.`, or after a semicolon is checked.
for criterion in \
    "inspect: docs/guide.md. src/pkg/y.go returns the error." \
    "inspect: docs/guide.md and. src/pkg/y.go returns the error." \
    "inspect: docs/guide.md; src/pkg/y.go returns the error."; do
    lint "- [ ] AC-1: ${criterion}" "docs/notes.txt" "docs/notes.txt"
    expect_line "missing from files: src/pkg/y.go" "an edit target right after a marked run ends (${criterion})"
    case "$OUT" in
        *docs/guide.md*) fail "a path after inspect: is reported (${criterion}): ${OUT}" ;;
        *) pass "a path after inspect: is not reported (${criterion})" ;;
    esac
done

# The exemption belongs to the marked mention, not the path: the same path
# named again as an edit target is still checked.
lint "- [ ] AC-1: inspect: docs/guide.md for the wording. docs/guide.md must also gain a section." \
    "docs/notes.txt" \
    "docs/notes.txt"
expect_line "missing from files: docs/guide.md" "a marked path named again as an edit target"

# A word that is not a path ends the marker's run, so the path after it is
# checked.
lint "- [ ] AC-1: inspect: notes.txt src/pkg/y.go for the wording." \
    "docs/notes.txt" \
    "docs/notes.txt"
expect_line "missing from files: src/pkg/y.go" "a path after a non-path word that follows a marker"

# A bold criteria label starts the section like a heading.
lint_body "$(printf 'Context names docs/guide.md.\n\n**Acceptance criteria**\n\n- [ ] AC-1: src/pkg/y.go returns the error.\n')" \
    "src/pkg/y.go" \
    "src/pkg/y.go"
expect_clean "a bold criteria label"

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
