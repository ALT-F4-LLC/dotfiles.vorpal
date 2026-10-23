#!/bin/bash
# Behavior suite for .docket/bin/crossref-check.
#
# THE PROPERTY UNDER TEST: every name the prose corpus points at exists —
# paths, relative links and their heading anchors, /docket-* skill references
# and the skill names a description hands off to, schema versions, workflow
# executors, workflow gates, routing labels, each definition's declared
# name, Contents line counts, and prose tables and lists that mirror the CLI
# inventory and fixtures — and the gate names the check and the
# location of every reference that does not resolve. Nothing else reads both trees: a rename
# on one side used to leave the other side describing a thing that is gone,
# with every other gate green.
#
# SEAM. Each case builds a small synthetic corpus under $TMPDIR — not a copy
# of the real one, so each mutant changes exactly one reference — and runs
# the real gate against it through CORPUS_ROOT. The baseline passes; every
# mutant below is proven red by its own case, and two positive cases pin the
# deliberate exemptions (a renamed path inside changelogs/,
# an unquoted route-<word> that is ordinary English, and a PROJECT_GATES row).

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
GATE="${CROSSREF_CHECK_GATE:-${REPO_ROOT}/.docket/bin/crossref-check}"

PASS=0
FAIL=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    FAIL=$((FAIL + 1))
}

pass() {
    printf 'PASS: %s\n' "$1"
    PASS=$((PASS + 1))
}

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$GATE" ] || fatal "gate not found at ${GATE}"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/crossref-check-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

# build_corpus <dir>; a corpus in which every reference resolves. The
# changelogs/ entries cite contracts/old.md, which does not exist, and the
# skill body says "route-specific" unquoted: both must pass.
build_corpus() { # <dir>
    local d="$1"
    rm -rf "$d"
    mkdir -p "$d/src/user/claude_code/skills/alpha/references" \
             "$d/src/user/claude_code/skills/docket-beta" \
             "$d/src/user/claude_code/agents" \
             "$d/src/user/docket/config/contracts" \
             "$d/src/user/docket/config/fragments" \
             "$d/src/user/docket/config/schemas" \
             "$d/src/user/docket/config/workflows" \
             "$d/src/user/docket/config/changelogs"

    printf 'build:\n    true\n\ntests:\n    true\n' > "$d/justfile"

    cat > "$d/src/user/claude_code/skills/alpha/SKILL.md" <<'EOF'
---
name: alpha
description: fixture
---
# alpha

Read [notes](references/notes.md#notes-on-alpha) first, then /docket-beta. The contract is
src/user/docket/config/contracts/implement.md and it emits `ac-report@2`.
Issues carry `route-run`; a route-specific step follows.
EOF
    printf '# Notes on `alpha`\n\n```\n# not a heading\n```\n' > "$d/src/user/claude_code/skills/alpha/references/notes.md"
    printf -- '---\nname: docket-beta\ndescription: fixture\n---\n# beta\n' \
        > "$d/src/user/claude_code/skills/docket-beta/SKILL.md"
    printf -- '---\nname: executor-x\ndescription: fixture\n---\n# x\n' \
        > "$d/src/user/claude_code/agents/executor-x.md"

    printf '# Naming\n' > "$d/src/user/docket/config/README.md"
    cat > "$d/src/user/docket/config/policy.toml" <<'EOF'
[policy]
version = 1

[executors]
implement = { variant = "sonnet-high" }
EOF
    printf '# policy changelog\n\n## 1\n\ninitial; cites contracts/old.md, which is history\n' \
        > "$d/src/user/docket/config/changelogs/policy.md"
    printf -- '---\nnode: implement\nversion: 1\n---\n# Charter\n' \
        > "$d/src/user/docket/config/contracts/implement.md"
    printf -- '---\nfragment: truth\nversion: 1\n---\n# Truth\n' \
        > "$d/src/user/docket/config/fragments/truth.md"
    printf '{}\n' > "$d/src/user/docket/config/schemas/ac-report@2.json"
    cat > "$d/src/user/docket/config/workflows/ui-change.toml" <<'EOF'
[pipeline]
name = "ui-change"
version = 2

[match]
labels_any = ["ui"]
unless_labels = ["blocked", "route-direct", "route-loop"]

[[step]]
name = "implement"
executor = "implement"
packet = ["contracts/{executor}.md"]
gates = ["build", { name = "render-verify", pre = true }]
EOF
    printf '# ui-change changelog\n\n## 2\n\nimplement no longer reads contracts/old.md\n(renamed to contracts/implement.md)\n' \
        > "$d/src/user/docket/config/changelogs/ui-change.md"
}

run_gate() { # <dir>
    CORPUS_ROOT="$1" bash "$GATE" 2>&1
}

# expect_pass <label> <dir>
expect_pass() {
    local out
    if out=$(run_gate "$2"); then
        pass "$1"
    else
        fail "$1 (expected pass): $out"
    fi
}

# expect_fail <label> <dir> <check> <needle>; red, and the failure line names
# the check and the reference.
expect_fail() {
    local out
    if out=$(run_gate "$2"); then
        fail "$1 (expected fail, got pass)"
    elif ! grep -q "crossref-check: $3 " <<< "$out"; then
        fail "$1 (failed, but not on check '$3'): $out"
    elif ! grep -q -- "$4" <<< "$out"; then
        fail "$1 (failed, but did not name '$4'): $out"
    else
        pass "$1"
    fi
}

FIX="$WORK/fix"
SKILL="src/user/claude_code/skills/alpha/SKILL.md"
WF="src/user/docket/config/workflows/ui-change.toml"

# --- baseline ---------------------------------------------------------------
build_corpus "$FIX"
expect_pass "baseline corpus resolves, changelogs/ and English route-word exempt" "$FIX"

# --- path ---------------------------------------------------------------------
build_corpus "$FIX"
echo 'See src/user/docket/config/contracts/gone.md.' >> "$FIX/$SKILL"
expect_fail "path: repo-rooted path to a missing file" "$FIX" path "contracts/gone.md"

build_corpus "$FIX"
echo 'packet = ["fragments/gone.md"]' >> "$FIX/$WF"
expect_fail "path: bare corpus path inside the docket tree" "$FIX" path "fragments/gone.md"

build_corpus "$FIX"
echo 'Example layout: config/fragments/gone.md.' >> "$FIX/$SKILL"
expect_pass "path: bare corpus path outside the docket tree is not checked" "$FIX"

build_corpus "$FIX"
printf '\n# implement once read contracts/old.md\n' >> "$FIX/src/user/docket/config/policy.toml"
expect_fail "path: renamed path in a TOML comment" "$FIX" path "contracts/old.md"

build_corpus "$FIX"
sed -i.bak 's|^version = 2$|version = 2  # 2: implement no longer reads contracts/old.md|' "$FIX/$WF"
expect_fail "path: renamed path in a version-line comment is not exempt" "$FIX" path "contracts/old.md"

build_corpus "$FIX"
echo '# history: changelogs/gone.md' >> "$FIX/$WF"
expect_fail "path: bare changelogs path inside the docket tree" "$FIX" path "changelogs/gone.md"

# --- link -------------------------------------------------------------------
build_corpus "$FIX"
echo 'Then read [more](references/missing.md).' >> "$FIX/$SKILL"
expect_fail "link: relative link to a missing file" "$FIX" link "references/missing.md"

build_corpus "$FIX"
echo 'Then read [more](references/notes.md#notes-on-beta).' >> "$FIX/$SKILL"
expect_fail "link: anchor names no heading in the target" "$FIX" link "#notes-on-beta"

build_corpus "$FIX"
echo 'Then read [more](references/notes.md#not-a-heading).' >> "$FIX/$SKILL"
expect_fail "link: a heading inside a code fence is not an anchor" "$FIX" link "#not-a-heading"

# --- skill --------------------------------------------------------------------
build_corpus "$FIX"
echo 'Hand off to /docket-gone.' >> "$FIX/$SKILL"
expect_fail "skill: /docket-<x> with no directory" "$FIX" skill "/docket-gone"

build_corpus "$FIX"
sed -i.bak 's|^description: fixture|description: fixture; hand off to docket-gone|' "$FIX/$SKILL"
expect_fail "skill: description names a docket-<x> with no directory" "$FIX" skill "docket-gone, not a skill"

build_corpus "$FIX"
sed -i.bak 's|^description: fixture|description: fixture; authoring belongs to `beta`|' "$FIX/$SKILL"
expect_fail "skill: description uses a short form of a docket- skill" "$FIX" skill "the skill is docket-beta"

build_corpus "$FIX"
sed -i.bak 's|^description: fixture|description: fixture; hand off to `docket-beta` or `alpha`|' "$FIX/$SKILL"
expect_pass "skill: description naming real skills in full passes" "$FIX"

# --- schema -------------------------------------------------------------------
build_corpus "$FIX"
echo 'The payload is `ac-report@7`.' >> "$FIX/$SKILL"
expect_fail "schema: version with no file" "$FIX" schema "ac-report@7"

# --- executor -----------------------------------------------------------------
build_corpus "$FIX"
sed -i.bak 's|^executor = "implement"|executor = "phantom"|' "$FIX/$WF"
expect_fail "executor: no contract file" "$FIX" executor "phantom has no contract"

build_corpus "$FIX"
sed -i.bak 's|^implement = |implemnt = |' "$FIX/src/user/docket/config/policy.toml"
expect_fail "executor: no policy row" "$FIX" executor "no \[executors\] row"

# --- payload ------------------------------------------------------------------
# pin_payload <dir> <contract-pin> <step-payload>: the implement contract's
# frontmatter pins <contract-pin>, the implement step declares <step-payload>,
# and both versions have a schema file so only the comparison can fail.
pin_payload() {
    printf '{}\n' > "$1/src/user/docket/config/schemas/ac-report@3.json"
    sed -i.bak "s|^version: 1\$|version: 1\\
payload: $2|" "$1/src/user/docket/config/contracts/implement.md"
    sed -i.bak "s|^executor = \"implement\"\$|executor = \"implement\"\\
payload = \"$3\"|" "$1/$WF"
}

build_corpus "$FIX"
pin_payload "$FIX" "ac-report@2" "ac-report@2"
expect_pass "payload: step payload matches its executor contract's pin" "$FIX"

build_corpus "$FIX"
pin_payload "$FIX" "ac-report@2" "ac-report@3"
expect_fail "payload: step payload differs from its executor contract's pin" "$FIX" payload \
    "step implement declares ac-report@3; src/user/docket/config/contracts/implement.md pins ac-report@2"

build_corpus "$FIX"
pin_payload "$FIX" "ac-report@2" "ac-report@2"
printf '\n[[step]]\nname = "review"\nfanout = [\n  "implement",\n]\npayload = "ac-report@3"\n' >> "$FIX/$WF"
expect_fail "payload: a fanout member's pin differs from the step payload" "$FIX" payload \
    "step review declares ac-report@3"

# A spec-author-<x> fanout member executes contracts/spec-author.md.
build_corpus "$FIX"
pin_payload "$FIX" "ac-report@2" "ac-report@2"
printf -- '---\nnode: spec-author\nversion: 1\npayload: ac-report@2\n---\n# Charter\n' \
    > "$FIX/src/user/docket/config/contracts/spec-author.md"
printf '\n[[step]]\nname = "spec"\nfanout = ["spec-author-foo"]\npayload = "ac-report@3"\n' >> "$FIX/$WF"
expect_fail "payload: a spec-author-* member's pin is read from spec-author.md" "$FIX" payload \
    "step spec declares ac-report@3; src/user/docket/config/contracts/spec-author.md pins ac-report@2"

build_corpus "$FIX"
pin_payload "$FIX" "ac-report@1" "ac-report@1"
printf '{}\n' > "$FIX/src/user/docket/config/schemas/ac-report@1.json"
printf -- '---\nnode: spec-author\nversion: 1\npayload: ac-report@2\n---\n# Charter\n' \
    > "$FIX/src/user/docket/config/contracts/spec-author.md"
printf '\n[[step]]\nname = "spec"\nfanout = ["spec-author-foo"]\npayload = "ac-report@2"\n' >> "$FIX/$WF"
expect_pass "payload: a spec-author-* member matching spec-author.md passes" "$FIX"

build_corpus "$FIX"
pin_payload "$FIX" "ac-report@2" "ac-report@2"
printf '\n[[step]]\nname = "reconcile"\npayload = "ac-report@3"\n' >> "$FIX/$WF"
expect_pass "payload: a step with no executor and no fanout is not compared" "$FIX"

build_corpus "$FIX"
sed -i.bak 's|^executor = "implement"$|executor = "implement"\
payload = "ac-report@2"|' "$FIX/$WF"
expect_pass "payload: a contract with no payload pin is not compared" "$FIX"

# --- gate ---------------------------------------------------------------------
build_corpus "$FIX"
sed -i.bak 's|"build"|"nope"|' "$FIX/$WF"
expect_fail "gate: not a justfile recipe" "$FIX" gate "gate nope"

build_corpus "$FIX"
mv "$FIX/$WF" "$FIX/src/user/docket/config/workflows/other.toml"
sed -i.bak 's|name = "ui-change"|name = "other"|' "$FIX/src/user/docket/config/workflows/other.toml"
expect_fail "gate: PROJECT_GATES row is per workflow" "$FIX" gate "render-verify"

# --- label --------------------------------------------------------------------
build_corpus "$FIX"
echo 'Set `route-queued` on it.' >> "$FIX/$SKILL"
expect_fail "label: quoted label outside the three" "$FIX" label "route-queued"

build_corpus "$FIX"
sed -i.bak 's|, "route-loop"||' "$FIX/$WF"
expect_fail "label: unless_labels missing a routed-away label" "$FIX" label 'lacks "route-loop"'

# --- name ---------------------------------------------------------------------
build_corpus "$FIX"
sed -i.bak 's|^node: implement|node: implemnt|' "$FIX/src/user/docket/config/contracts/implement.md"
expect_fail "name: contract node differs from stem" "$FIX" name "expected 'implement'"

build_corpus "$FIX"
sed -i.bak 's|^fragment: truth|fragment: lies|' "$FIX/src/user/docket/config/fragments/truth.md"
expect_fail "name: fragment name differs from stem" "$FIX" name "expected 'truth'"

build_corpus "$FIX"
sed -i.bak 's|^name: alpha|name: beta|' "$FIX/$SKILL"
expect_fail "name: skill name differs from directory" "$FIX" name "expected 'alpha'"

build_corpus "$FIX"
sed -i.bak 's|^name: executor-x|name: executor-y|' "$FIX/src/user/claude_code/agents/executor-x.md"
expect_fail "name: agent name differs from stem" "$FIX" name "expected 'executor-x'"

# --- contents -------------------------------------------------------------------
# A Contents list whose counts equal the anchor spans passes; a stale count and
# an entry with no anchor each fail with the entry named.
REF="src/user/claude_code/skills/alpha/references/notes.md"
write_contents() { # <dir> <first-count> <second-id>
    cat > "$1/$REF" <<EOF
# Notes on \`alpha\`

- [One](#one) — $2 lines
- [Two](#$3) — 3 lines

<a id="one"></a>

One.
<a id="two"></a>

Two.
EOF
}

build_corpus "$FIX"
write_contents "$FIX" 3 two
expect_pass "contents: counts equal the anchor spans" "$FIX"

build_corpus "$FIX"
write_contents "$FIX" 4 two
expect_fail "contents: a stale line count" "$FIX" contents "#one states 4 lines; the anchors span 3"

build_corpus "$FIX"
write_contents "$FIX" 3 three
expect_fail "contents: an entry with no anchor" "$FIX" contents "entry #three has no <a id> anchor"

# --- inventory ----------------------------------------------------------------
# add_inventory <dir>: the CLI inventory plus the docket-run prose that mirrors
# it, all in agreement. Each case below removes one entry and expects red.
add_inventory() { # <dir>
    local d="$1" s="$1/src/user/claude_code/skills"
    mkdir -p "$s/docket/references" "$s/docket-run/references"
    cat > "$s/docket/references/cli-inventory.json" <<'JSON'
{"commands": [
 {"command": "docket dispatch close", "flags": [{"name": "--help"}, {"name": "--no-conditions"}, {"name": "--run"}], "inherited_flags": [{"name": "--json"}]},
 {"command": "docket step claim", "flags": [{"name": "--help"}, {"name": "--owner"}], "inherited_flags": []},
 {"command": "docket step approve", "flags": [{"name": "--help"}], "inherited_flags": []},
 {"command": "docket step reject", "flags": [{"name": "--help"}], "inherited_flags": []},
 {"command": "docket step integrate", "flags": [{"name": "--help"}], "inherited_flags": []},
 {"command": "docket pin show", "flags": [{"name": "--help"}], "inherited_flags": []}
]}
JSON
    cat > "$s/docket/reference.md" <<'EOF2'
# Reference

The engine-conductor families (dispatch, step,
pin) are documented elsewhere.
EOF2
    cat > "$s/docket-run/references/dispatch.md" <<'EOF2'
# Dispatch

#### `docket dispatch close`

| Flag | Type | Notes |
|---|---|---|
| `--run` | string | **required** |
| `--no-conditions` | string | close despite unlinked conditions |

Prose after the table.
EOF2
    cat > "$s/docket-run/references/step.md" <<'EOF2'
# Step

| Verb | Token | Effect |
|---|---|---|
| `step claim STEP-N` | no | claim |
| `step approve\|reject STEP-N` | **conductor** | decide |
| `step integrate STEP-N…` | **conductor** | cherry-pick |

#### `docket step claim`

| Flag | Type | Notes |
|---|---|---|
| `--owner` | string | **required** |
EOF2
    cat > "$s/docket-run/references/run.md" <<'EOF2'
# Run

#### `docket pin show RUN-N PATH`

Reads what a run pinned.
EOF2
}
INV_S="src/user/claude_code/skills"

build_corpus "$FIX"; add_inventory "$FIX"
expect_pass "inventory: prose that covers the inventory passes" "$FIX"

build_corpus "$FIX"; add_inventory "$FIX"
sed -i.bak '/--no-conditions` | string/d' "$FIX/$INV_S/docket-run/references/dispatch.md"
expect_fail "inventory: a flag missing from its table" "$FIX" inventory "docket dispatch close --no-conditions"

build_corpus "$FIX"; add_inventory "$FIX"
sed -i.bak 's/`--run` | string/`--run-id` | string/' "$FIX/$INV_S/docket-run/references/dispatch.md"
expect_fail "inventory: a longer flag name does not satisfy a shorter one" "$FIX" inventory "docket dispatch close --run"

build_corpus "$FIX"; add_inventory "$FIX"
sed -i.bak '/step integrate STEP-N/d' "$FIX/$INV_S/docket-run/references/step.md"
expect_fail "inventory: a step verb missing from the verb table" "$FIX" inventory "docket step integrate"

build_corpus "$FIX"; add_inventory "$FIX"
sed -i.bak 's/step approve\\|reject STEP-N/step approve STEP-N/' "$FIX/$INV_S/docket-run/references/step.md"
expect_fail "inventory: one half of an approve|reject row is missing" "$FIX" inventory "docket step reject"

build_corpus "$FIX"; add_inventory "$FIX"
sed -i.bak 's/^pin) are/) are/' "$FIX/$INV_S/docket/reference.md"
expect_fail "inventory: a family with a heading is missing from the family list" "$FIX" inventory "family pin"

build_corpus "$FIX"; add_inventory "$FIX"
rm "$FIX/$INV_S/docket-run/references/dispatch.md" "$FIX/$INV_S/docket-run/references/step.md"
expect_pass "inventory: a missing target file skips its rule" "$FIX"

# --- fixtures -----------------------------------------------------------------
# add_fixtures <dir>: the CLI fixtures plus the docket-skill lists that mirror
# them, all in agreement. step approve/reject share one alternation in the
# SKILL.md row, and `run hold-issue` also sits in its no-authority sentence so
# a case can prove that sentence does not stand in for the gated list.
add_fixtures() { # <dir>
    local d="$1" s="$1/src/user/claude_code/skills"
    mkdir -p "$s/docket/references" "$s/docket-cli-audit/references"
    cat > "$s/docket-cli-audit/references/cli-fixtures.json" <<'JSON'
{"records": [
 {"id": "run-hold-issue-without-token", "mode": "text", "argv": ["docket", "run", "hold-issue"], "exit": 3, "stderr": "Error: RUN-3 is bound to a conductor capability and run hold-issue requires it: supply the run's token via DOCKET_TOKEN or stdin"},
 {"id": "step-approve-without-token", "mode": "text", "argv": ["docket", "step", "approve"], "exit": 3, "stderr": "Error: RUN-1 is bound to a conductor capability and step approve requires it: supply the run's token via DOCKET_TOKEN or stdin"},
 {"id": "step-reject-without-token", "mode": "text", "argv": ["docket", "step", "reject"], "exit": 3, "stderr": "Error: RUN-1 is bound to a conductor capability and step reject requires it: supply the run's token via DOCKET_TOKEN or stdin"},
 {"id": "config-get-all", "mode": "json", "argv": ["docket", "config", "get"], "exit": 0, "json": {"ok": true, "data": {"entries": [{"key": "lease.ttl.default"}, {"key": "routing.security_label"}], "total": 2}}}
]}
JSON
    printf -- '---\nname: docket\ndescription: fixture\n---\n# docket\n\n| Verbs | Rule |\n|---|---|\n| `step approve/reject`, `run hold-issue` | Require the run'"'"'s conductor capability on a bound run. `run resume` and `run hold-issue` take no `--authority`. |\n' \
        > "$s/docket/SKILL.md"
    cat > "$s/docket/references/transport.md" <<'EOF2'
# Transport

| `code` | Exit | Meaning |
|---|---|---|
| `AUTH_ERROR` | 5 | not the run's conductor capability on a conductor-gated verb: `step approve`, `step reject`, `run hold-issue` |

On a bound run the conductor-gated verbs read it from `DOCKET_TOKEN` or
stdin:

- `step approve`, `step reject`
- `run hold-issue`

Three `--authority` rules apply:
EOF2
    cat > "$s/docket/references/workflows.md" <<'EOF2'
# Workflows

| Key | Type | Default | Meaning |
|---|---|---|---|
| `lease.ttl.default` | duration | `15m` | fallback lease TTL |
| `routing.security_label` | label | `security` | the security label |

After the table.
EOF2
}
FX_S="src/user/claude_code/skills"

build_corpus "$FIX"; add_fixtures "$FIX"
expect_pass "fixtures: lists that cover the fixtures pass" "$FIX"

build_corpus "$FIX"; add_fixtures "$FIX"
sed -i.bak '/^- `run hold-issue`$/d' "$FIX/$FX_S/docket/references/transport.md"
expect_fail "fixtures: a gated verb missing from the transport bullets" "$FIX" fixtures "run hold-issue needs the conductor token"

build_corpus "$FIX"; add_fixtures "$FIX"
sed -i.bak 's/`step approve`, `step reject`, `run hold-issue` |/`step approve`, `step reject` |/' "$FIX/$FX_S/docket/references/transport.md"
expect_fail "fixtures: a gated verb missing from the AUTH_ERROR row" "$FIX" fixtures "run hold-issue needs the conductor token"

build_corpus "$FIX"; add_fixtures "$FIX"
sed -i.bak 's/^| `step approve\/reject`, `run hold-issue` |/| `step approve\/reject` |/' "$FIX/$FX_S/docket/SKILL.md"
expect_fail "fixtures: the no-authority sentence does not stand in for the gated row" "$FIX" fixtures "run hold-issue needs the conductor token"

build_corpus "$FIX"; add_fixtures "$FIX"
sed -i.bak 's/`step approve\/reject`/`step approve`/' "$FIX/$FX_S/docket/SKILL.md"
expect_fail "fixtures: one half of an approve/reject alternation is missing" "$FIX" fixtures "step reject needs the conductor token"

build_corpus "$FIX"; add_fixtures "$FIX"
sed -i.bak '/^| `routing.security_label`/d' "$FIX/$FX_S/docket/references/workflows.md"
expect_fail "fixtures: a config key missing from the table" "$FIX" fixtures "config key routing.security_label"

build_corpus "$FIX"; add_fixtures "$FIX"
sed -i.bak 's/^| Key | Type/| Name | Type/' "$FIX/$FX_S/docket/references/workflows.md"
expect_fail "fixtures: a table that cannot be found is named, not skipped" "$FIX" fixtures "cannot find the engine configuration table"

build_corpus "$FIX"; add_fixtures "$FIX"
rm "$FIX/$FX_S/docket-cli-audit/references/cli-fixtures.json"
expect_pass "fixtures: a corpus without the fixtures skips the rules" "$FIX"

# --- every failure is listed, not only the first ------------------------------
build_corpus "$FIX"
echo 'See src/user/docket/config/contracts/gone.md and /docket-gone.' >> "$FIX/$SKILL"
out=$(run_gate "$FIX")
if grep -q 'crossref-check: path ' <<< "$out" && grep -q 'crossref-check: skill ' <<< "$out"; then
    pass "reports every failing check in one run"
else
    fail "reports every failing check in one run: $out"
fi

# --- ask ----------------------------------------------------------------------
build_corpus "$FIX"
printf '\nAsk the operator which option to take.\n' >> "$FIX/$SKILL"
expect_fail "ask: asks the operator without naming the channel" "$FIX" ask "AskUserQuestion"

build_corpus "$FIX"
printf '\nAsk the operator through `AskUserQuestion` which option to take.\n' >> "$FIX/$SKILL"
expect_pass "ask: names AskUserQuestion" "$FIX"

build_corpus "$FIX"
printf '\nA subagent returns the question to its caller; it cannot ask\nthe operator.\n' >> "$FIX/$SKILL"
expect_pass "ask: a negated ask across a line wrap is exempt" "$FIX"

# --- the live corpus ------------------------------------------------------------
if out=$(CORPUS_ROOT="$REPO_ROOT" bash "$GATE" 2>&1); then
    pass "live corpus resolves"
else
    fail "live corpus resolves: $out"
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
