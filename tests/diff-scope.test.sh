#!/bin/bash

# Behavior suite for .docket/bin/diff-scope, the gate that keeps a change on
# the docs-only, trivial and small tracks inside the footprint its label
# promises. Each case builds a throwaway git repo under $TMPDIR, makes a
# working-tree change, and asserts the gate's verdict for a track. The pass
# cases prove the gate does not refuse a change that honors its label; the
# refusal cases each mutate exactly one rule's input, so a rule that stops
# being enforced turns its own case red.
#
# Needs only git and bash; no engine, no network.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
GATE="${DIFF_SCOPE:-${SCRIPT_DIR}/../.docket/bin/diff-scope}"
GATE=$(cd "$(dirname "$GATE")" && pwd)/$(basename "$GATE")

fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }
[ -x "$GATE" ] || fatal "diff-scope not executable at ${GATE}"
command -v git >/dev/null 2>&1 || fatal "git is required"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/diff-scope.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

pass=0; fail=0
ok()   { pass=$((pass + 1)); printf 'PASS: %s\n' "$1"; }
bad()  { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1"; }

# fresh_repo <name>: a repo with a committed baseline of docs and code.
fresh_repo() {
    local d="$WORK/$1"
    rm -rf "$d"; mkdir -p "$d/docs" "$d/src/a" "$d/src/b" "$d/hooks"
    (
        cd "$d" || exit 1
        git init -q
        git config user.email t@example.invalid; git config user.name t
        printf '# Title\n\nline one\n' > docs/guide.md
        printf 'readme\n' > README.md
        printf 'fn a() {}\n' > src/a/lib.rs
        printf 'fn a2() {}\n' > src/a/other.rs
        printf 'fn b() {}\n' > src/b/lib.rs
        printf 'guard\n' > hooks/guard.sh
        git add -A && git commit -qm base
    )
    printf '%s' "$d"
}

# expect <label> <track> <want-exit> <repo>
expect() {
    local label="$1" track="$2" want="$3" repo="$4" out got
    out=$(cd "$repo" && "$GATE" "$track" 2>&1); got=$?
    if [ "$got" -eq "$want" ]; then ok "$label (exit $got)"
    else bad "$label (want exit $want, got $got): $out"; fi
}

# ---- docs-only ---------------------------------------------------------------
r=$(fresh_repo docs-pass); printf 'more\n' >> "$r/docs/guide.md"; printf 'x\n' >> "$r/README.md"
expect "docs-only: document edits pass" docs-only 0 "$r"

r=$(fresh_repo docs-new-md); printf 'new\n' > "$r/docs/new.md"
expect "docs-only: an added markdown file passes" docs-only 0 "$r"

r=$(fresh_repo docs-code); printf 'more\n' >> "$r/docs/guide.md"; printf '// x\n' >> "$r/src/a/lib.rs"
expect "docs-only: a code edit beside the doc edit is refused" docs-only 1 "$r"

r=$(fresh_repo docs-untracked-code); printf 'fn c() {}\n' > "$r/src/a/new.rs"
expect "docs-only: an untracked code file is refused" docs-only 1 "$r"

# ---- trivial ---------------------------------------------------------------
r=$(fresh_repo triv-pass); printf 'fn a() { 1 }\n' > "$r/src/a/lib.rs"
expect "trivial: one file, two changed lines passes" trivial 0 "$r"

r=$(fresh_repo triv-two); printf '// x\n' >> "$r/src/a/lib.rs"; printf '// y\n' >> "$r/src/a/other.rs"
expect "trivial: two files are refused" trivial 1 "$r"

r=$(fresh_repo triv-add); printf 'fn n() {}\n' > "$r/src/a/new.rs"
expect "trivial: an added file is refused" trivial 1 "$r"

r=$(fresh_repo triv-del); rm "$r/src/a/other.rs"
expect "trivial: a deleted file is refused" trivial 1 "$r"

r=$(fresh_repo triv-long); for i in $(seq 1 12); do printf '// line %s\n' "$i" >> "$r/src/a/lib.rs"; done
expect "trivial: twelve changed lines exceed the ten-line bound" trivial 1 "$r"

r=$(fresh_repo triv-bound); for i in $(seq 1 12); do printf '// line %s\n' "$i" >> "$r/src/a/lib.rs"; done
out=$(cd "$r" && DIFF_SCOPE_TRIVIAL_MAX_LINES=20 "$GATE" trivial 2>&1); got=$?
[ "$got" -eq 0 ] && ok "trivial: the line bound is the env-configurable one" || bad "trivial: env bound not honored: $out"

# ---- small ---------------------------------------------------------------
r=$(fresh_repo small-pass); printf '// x\n' >> "$r/src/a/lib.rs"; printf '// y\n' >> "$r/src/a/other.rs"
expect "small: two files in one directory pass" small 0 "$r"

r=$(fresh_repo small-dirs); printf '// x\n' >> "$r/src/a/lib.rs"; printf '// y\n' >> "$r/src/b/lib.rs"
expect "small: two files in two directories are refused" small 1 "$r"

r=$(fresh_repo small-three); printf '// x\n' >> "$r/src/a/lib.rs"; printf '// y\n' >> "$r/src/a/other.rs"; printf 'x\n' >> "$r/README.md"
expect "small: three files are refused" small 1 "$r"

r=$(fresh_repo small-add); printf 'fn n() {}\n' > "$r/src/a/new.rs"
expect "small: an added file is refused" small 1 "$r"

# ---- control-class paths (every track) ------------------------------------
r=$(fresh_repo ctrl); mkdir -p "$r/.docket"; printf '# control classes\nhooks/*\n' > "$r/.docket/scope-control-paths"
printf 'x\n' >> "$r/hooks/guard.sh"
expect "control paths: a hooks/ edit is refused on trivial" trivial 1 "$r"
expect "control paths: a hooks/ edit is refused on small" small 1 "$r"

r=$(fresh_repo ctrl-absent); printf 'x\n' >> "$r/hooks/guard.sh"
expect "control paths: no pattern file means no control check" trivial 0 "$r"

# ---- harness scaffolding is nobody's change --------------------------------
# A sandboxed executor's git status carries untracked `.claude/` mounts and an
# `.mcp.json` under its working directories; the gate must not count them.
scaffold() { mkdir -p "$1/.claude/hooks" "$1/src/a/.claude"; printf '{}\n' > "$1/.claude/settings.json"; printf 'x\n' > "$1/src/a/.claude/loop.md"; printf '{}\n' > "$1/.mcp.json"; }
r=$(fresh_repo scaffold-only); scaffold "$r"
expect "scaffolding: untracked .claude/ and .mcp.json alone pass docs-only" docs-only 0 "$r"
expect "scaffolding: untracked .claude/ and .mcp.json alone pass trivial" trivial 0 "$r"
r=$(fresh_repo scaffold-code); scaffold "$r"; printf 'fn a() { 1 }\n' > "$r/src/a/lib.rs"
expect "scaffolding: ignored beside a one-file code edit on trivial" trivial 0 "$r"
expect "scaffolding: ignored beside a one-file code edit on small" small 0 "$r"

r=$(fresh_repo scaffold-tracked); mkdir -p "$r/.claude"; printf '{}\n' > "$r/.claude/settings.json"
(cd "$r" && git add -A && git commit -qm scaffold)
printf '{"a":1}\n' > "$r/.claude/settings.json"; printf 'fn a() { 1 }\n' > "$r/src/a/lib.rs"
expect "scaffolding: a TRACKED .claude/ file this step modified still counts (two paths on trivial)" trivial 1 "$r"

# ---- edges -----------------------------------------------------------------
r=$(fresh_repo clean)
expect "a clean tree passes every track" docs-only 0 "$r"
expect "a clean tree passes trivial" trivial 0 "$r"

out=$("$GATE" 2>&1); got=$?
[ "$got" -eq 2 ] && ok "no track argument is a usage error (exit 2)" || bad "usage: want exit 2, got $got"

out=$(cd "$WORK" && "$GATE" trivial 2>&1); got=$?
[ "$got" -eq 2 ] && ok "outside a git tree refuses with exit 2" || bad "non-git cwd: want exit 2, got $got: $out"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
