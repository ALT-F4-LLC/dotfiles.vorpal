#!/bin/bash

# The lane scripts are rendered files, one per workflow definition.
#
# Wired into CI: `.github/workflows/vorpal.yaml` lists this file by name,
# and tests/ci-suite-wiring.test.sh fails when it is not. Needs python3 (3.11+
# for tomllib) and node; no engine, no network.
#
# WHY THIS EXISTS. docket-run launches one Workflow script per issue lane,
# and the script is the issue's workflow's: `~/.claude/workflows/<name>.js`
# for the `name@version` the run bound the issue to. A Workflow script
# cannot import a file and nests one level only, so the shared wave machinery
# (skills/docket-run/scripts/lane_body.js) cannot live in one file at run
# time; lane_scripts.py renders it into every lane script instead, under a
# header carrying `meta` and `LANE = { workflow }`, the name alone, so a TOML
# edit that keeps the name re-renders nothing. The rendered copies are
# committed, since `just activate` copies the workflows
# directory whole, which leaves three ways to drift: a body edit not
# re-rendered, a hand edit to a rendered script, and a workflow definition
# with no script (or a script with no definition). Each is pinned here.
#
# WHAT IS PINNED:
#   1. `lane_scripts.py --check` passes on the checkout: every rendered
#      script matches its rendering byte for byte, none is missing, none is
#      stray. The same check against a mutated copy (a hand edit, a deleted
#      script, a stray rendered script, a renamed workflow) is red, and a
#      TOML version bump alone stays green, so the gate bites where it should.
#   2. One script per workflow definition, named after `[pipeline].name`,
#      whose `meta.name` is that name and whose LANE is `{ workflow }` with
#      that name and nothing else, so
#      the roster's workflow name picks the script to launch.
#   3. Every rendered script contains the body verbatim: the body's bytes are
#      a suffix of the script, and the body's TEST-BEGIN/TEST-END regions
#      are present once each.
#   4. The body itself has no `meta` and no LANE, so it cannot be launched
#      by mistake; its lane fence reads LANE.workflow, and the rendered header
#      declares it.
#   5. Every rendered script fits the Workflow tool's 524,288-byte cap with
#      headroom for growth.
#   6. The renderer refuses to overwrite a non-rendered file whose name a
#      pipeline would take, and exits 1 on a TOML without a pipeline name.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
RENDER="${ROOT}/src/user/claude_code/skills/docket-run/scripts/lane_scripts.py"
BODY="${ROOT}/src/user/claude_code/skills/docket-run/scripts/lane_body.js"
TOML_DIR="${ROOT}/src/user/docket/config/workflows"
OUT_DIR="${ROOT}/src/user/claude_code/workflows"
MARKER='// RENDERED FILE: lane_scripts.py wrote it from'
CAP=524288

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

command -v python3 >/dev/null 2>&1 || fatal "python3 is required"
command -v node >/dev/null 2>&1 || fatal "node is required"
[ -f "$RENDER" ] || fatal "lane_scripts.py not found at ${RENDER}"
[ -f "$BODY" ] || fatal "lane_body.js not found at ${BODY}"
[ -d "$TOML_DIR" ] || fatal "workflow definitions not found at ${TOML_DIR}"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/lane-scripts.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { # <0|1> <label>
    if [ "$1" -eq 0 ]; then pass=$((pass + 1)); printf 'PASS: %s\n' "$2"
    else fail=$((fail + 1)); printf 'FAIL: %s\n' "$2" >&2; fi
}

render() { # [args...]: run the renderer with -I; stdout+stderr to $WORK/out
    python3 -I "$RENDER" "$@" > "$WORK/out" 2>&1
}

# A copy of the checkout's inputs and outputs, for mutation. The renderer
# finds the body beside itself, so the scripts directory is copied too.
copy_tree() { # <dir>
    rm -rf "$1"
    mkdir -p "$1/src/user/docket/config" "$1/src/user/claude_code/skills/docket-run" "$1/src/user/claude_code"
    cp -R "$TOML_DIR" "$1/src/user/docket/config/workflows"
    cp -R "${ROOT}/src/user/claude_code/skills/docket-run/scripts" "$1/src/user/claude_code/skills/docket-run/scripts"
    cp -R "$OUT_DIR" "$1/src/user/claude_code/workflows"
}
mut_render() { # <tree> [args...]: the copied renderer against the copied tree
    python3 -I "$1/src/user/claude_code/skills/docket-run/scripts/lane_scripts.py" --root "$1" "${@:2}" > "$WORK/out" 2>&1
}

# ---- 1. the checkout is rendered -----------------------------------------
render --check
ok $? "lane_scripts.py --check passes on the checkout ($(tail -n 1 "$WORK/out"))"

# ---- 2. one script per definition, named and declared after the pipeline --
names=()
for toml in "$TOML_DIR"/*.toml; do
    name=$(sed -n 's/^name = "\([^"]*\)"$/\1/p' "$toml" | head -n 1)
    [ -n "$name" ]; ok $? "$(basename "$toml") declares a pipeline name (${name:-none})"
    names+=("$name")
    script="${OUT_DIR}/${name}.js"
    [ -f "$script" ]; ok $? "${name}.js exists for $(basename "$toml")"
    [ -f "$script" ] || continue
    grep -q "^    name: '${name}',\$" "$script"; ok $? "${name}.js: meta.name is '${name}'"
    grep -q "^const LANE = { workflow: '${name}' }\$" "$script"; ok $? "${name}.js: LANE is { workflow: '${name}' } and nothing else"
    head -n 12 "$script" | grep -qF -- "$MARKER"; ok $? "${name}.js: carries the rendered-file marker in its head"
    # 3. the body is a byte-for-byte suffix
    body_bytes=$(wc -c < "$BODY")
    tail -c "$body_bytes" "$script" | cmp -s - "$BODY"; ok $? "${name}.js: ends with lane_body.js verbatim"
    for region in configuration launch-rows claim-path gate-vote stage-ladder; do
        [ "$(grep -c "^// TEST-BEGIN ${region} " "$script")" -eq 1 ]
        ok $? "${name}.js: TEST-BEGIN ${region} appears once"
    done
    # 5. size headroom
    size=$(wc -c < "$script")
    [ "$size" -lt $((CAP - 65536)) ]; ok $? "${name}.js is ${size} bytes, at least 64 KiB under the ${CAP}-byte Workflow cap"
done
# no rendered script without a definition
for script in "$OUT_DIR"/*.js; do
    head -n 12 "$script" | grep -qF -- "$MARKER" || continue
    base=$(basename "$script" .js)
    found=1
    for n in "${names[@]}"; do [ "$n" = "$base" ] && found=0; done
    ok $found "rendered ${base}.js has a workflow definition"
done
[ "${#names[@]}" -ge 2 ]; ok $? "more than one workflow definition is rendered (${#names[@]})"

# ---- 4. the body alone is not launchable ----------------------------------
grep -q '^export const meta' "$BODY"; ok $(( ! $? )) "lane_body.js declares no meta of its own"
grep -q '^const LANE = ' "$BODY"; ok $(( ! $? )) "lane_body.js declares no LANE of its own"
grep -q 'LANE\.workflow' "$BODY"; ok $? "lane_body.js reads LANE.workflow (the lane fence)"
grep -q 'function assertLane' "$BODY"; ok $? "lane_body.js defines assertLane"
grep -q '^assertLane(input, rows)$' "$BODY"; ok $? "lane_body.js calls assertLane at the launch call site"

# ---- 1b. the gate bites on each kind of drift ------------------------------
T="$WORK/tree"
copy_tree "$T"
mut_render "$T" --check
ok $? "mutation baseline: the copied tree passes --check"

copy_tree "$T"
printf '\n// hand edit\n' >> "$T/src/user/claude_code/workflows/standard-change.js"
mut_render "$T" --check
[ $? -eq 1 ] && grep -q 'drift: .*standard-change.js' "$WORK/out"
ok $? "a hand edit to a rendered script is drift (exit 1, named)"

copy_tree "$T"
rm "$T/src/user/claude_code/workflows/ui-change.js"
mut_render "$T" --check
[ $? -eq 1 ] && grep -q 'missing: .*ui-change.js' "$WORK/out"
ok $? "a definition with no script is missing (exit 1, named)"

copy_tree "$T"
sed 's/^    name: .*/    name: '"'"'retired'"'"',/; s/^const LANE = .*/const LANE = { workflow: '"'"'retired'"'"' }/' \
    "$T/src/user/claude_code/workflows/small-change.js" > "$T/src/user/claude_code/workflows/retired.js"
mut_render "$T" --check
[ $? -eq 1 ] && grep -q 'stray: .*retired.js' "$WORK/out"
ok $? "a rendered script with no definition is stray (exit 1, named)"

copy_tree "$T"
printf '\n// body edit\n' >> "$T/src/user/claude_code/skills/docket-run/scripts/lane_body.js"
mut_render "$T" --check
[ $? -eq 1 ] && [ "$(grep -c '^lane_scripts: drift: ' "$WORK/out")" -eq "${#names[@]}" ]
ok $? "a body edit not re-rendered is drift in every script (${#names[@]})"

copy_tree "$T"
sed -i.bak 's/^version = \([0-9]*\)$/version = 999/' "$T/src/user/docket/config/workflows/disposition.toml"
mut_render "$T" --check
ok $? "a TOML version bump re-renders nothing: --check still passes (LANE is the name alone)"

copy_tree "$T"
sed -i.bak 's/^name = "disposition"$/name = "disposition-two"/' "$T/src/user/docket/config/workflows/disposition.toml"
mut_render "$T" --check
[ $? -eq 1 ] && grep -q 'stray: .*disposition.js' "$WORK/out"
ok $? "a renamed pipeline leaves its old script stray (exit 1, named)"
rm -f "$T/src/user/claude_code/workflows/disposition.js"
mut_render "$T" --check
[ $? -eq 1 ] && grep -q 'missing: .*disposition-two.js' "$WORK/out"
ok $? "...and its new name has no script (exit 1, named)"

# re-rendering the mutated tree makes it pass again, and writes only what changed
mut_render "$T"
rc=$?
[ $rc -eq 0 ] && [ "$(grep -c '^lane_scripts: wrote ' "$WORK/out")" -eq 1 ]
ok $? "rendering after one rename writes exactly one script (rc ${rc})"
grep -q "^const LANE = { workflow: 'disposition-two' }\$" "$T/src/user/claude_code/workflows/disposition-two.js"
ok $? "...the new script declares the new name"
mut_render "$T" --check
ok $? "...after which --check passes"

# ---- 6. refusals -----------------------------------------------------------
copy_tree "$T"
printf 'export const meta = { name: "x" }\n' > "$T/src/user/claude_code/workflows/spec-doc.js"
mut_render "$T"
[ $? -eq 1 ] && grep -q 'collision: .*spec-doc.js' "$WORK/out" && grep -q '^export const meta = { name: "x" }$' "$T/src/user/claude_code/workflows/spec-doc.js"
ok $? "a non-rendered file in a pipeline's name is never overwritten (exit 1, named)"

copy_tree "$T"
printf '[pipeline]\nversion = 1\n\n[[step]]\nname = "a"\n' > "$T/src/user/docket/config/workflows/nameless.toml"
mut_render "$T" --check
[ $? -eq 1 ] && grep -q 'nameless.toml declares no \[pipeline\].name' "$WORK/out"
ok $? "a TOML without a pipeline name exits 1 and names the file"

copy_tree "$T"
printf '[pipeline]\nname = "standard-change"\nversion = 1\n\n[[step]]\nname = "a"\n' > "$T/src/user/docket/config/workflows/dup.toml"
mut_render "$T" --check
[ $? -eq 1 ] && grep -q 'both declare pipeline' "$WORK/out"
ok $? "two TOMLs with one pipeline name exit 1"

# --list names every pipeline and writes nothing
copy_tree "$T"
before=$(find "$T/src/user/claude_code/workflows" -type f | sort | xargs cat | cksum)
mut_render "$T" --list
after=$(find "$T/src/user/claude_code/workflows" -type f | sort | xargs cat | cksum)
[ "$(wc -l < "$WORK/out")" -eq "${#names[@]}" ] && [ "$before" = "$after" ]
ok $? "--list prints one line per definition and writes nothing"

# ---- every rendered script still parses as an ES module ------------------
# tests/workflow-module-parse.test.sh is the full gate. This is the smoke
# check that the header the renderer emits is itself well-formed.
for n in "${names[@]}"; do
    sed -e 's/^return[[:space:]]*$/void 0/' -e 's/^return;/void 0;/' -e 's/^return /void /' \
        "${OUT_DIR}/${n}.js" > "$WORK/${n}.mjs"
    node --check "$WORK/${n}.mjs" >/dev/null 2>&1
    ok $? "${n}.js parses as an ES module with its top-level return neutralized"
done

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

