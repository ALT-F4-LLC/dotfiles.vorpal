#!/bin/bash

# Behavior suite for the docket-reconcile planner,
# skills/docket-reconcile/scripts/reconcile_plan.py: what it plans for a
# project's workflow and schema registries against the corpus, in what order,
# and what it reports without planning.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by
# name and this one is in that list. It needs only `python3`; `docket` is a
# stub on PATH that serves canned registry state and logs every call.
#
# WHY THIS EXISTS. The planner once lived only as a code block in SKILL.md
# and covered workflows alone, so schema drift (a corpus schema never
# registered in ten projects, removed versions still in service) went
# unreported through a pass that printed "0 action(s)". Its apply order
# matters too: a workflow cannot register before the schema it names, and a
# schema cannot retire while a live workflow still names it.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="${SCRIPT_DIR}/.."
SCRIPT="${RECONCILE_PLAN_PY:-${ROOT}/src/user/claude_code/skills/docket-reconcile/scripts/reconcile_plan.py}"
SKILL="${DOCKET_RECONCILE_SKILL:-${ROOT}/src/user/claude_code/skills/docket-reconcile/SKILL.md}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$SCRIPT" ] || fatal "reconcile_plan.py not found at ${SCRIPT}"
[ -f "$SKILL" ] || fatal "SKILL.md not found at ${SKILL}"
command -v python3 >/dev/null 2>&1 || fatal "python3 is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/reconcile-plan.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT
WORK=$(cd "$WORK" && pwd -P)

pass=0
fail=0
ok() { # <condition-already-evaluated: 0/1> <label>
    if [ "$1" -eq 0 ]; then
        pass=$((pass + 1)); printf 'PASS: %s\n' "$2"
    else
        fail=$((fail + 1)); printf 'FAIL: %s\n' "$2" >&2
    fi
}

sha() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | cut -d' ' -f1
    else
        shasum -a 256 "$1" | cut -d' ' -f1
    fi
}

# --- corpus -----------------------------------------------------------------
export HOME="$WORK/home"
CFG="$HOME/.docket/config"
REPO="$WORK/repo"
mkdir -p "$CFG/schemas" "$CFG/contracts" "$CFG/fragments" "$CFG/workflows" "$REPO" "$WORK/bin"

printf '{"s":1}' > "$CFG/schemas/s@1.json"
printf '{"s":2}' > "$CFG/schemas/s@2.json"
printf '{"t":1}' > "$CFG/schemas/t@1.json"
printf '{"u":1}' > "$CFG/schemas/u@1.json"
printf '{}' > "$CFG/schemas/badname.json"
printf 'fragment\n' > "$CFG/fragments/f.md"
cat > "$CFG/contracts/x.md" <<'EOF'
---
node: x
packet_includes:
  - fragments/f.md
payload: s@2
---
# Charter
payload: s@404 in the body is prose, not frontmatter
EOF
cat > "$CFG/contracts/y.md" <<'EOF'
---
node: y
packet_includes:
  - fragments/nope.md
payload: s@9
---
EOF
printf 'judge\n' > "$CFG/contracts/judge-a.md"
for w in a b c d r; do printf '# %s\n' "$w" > "$CFG/workflows/$w.toml"; done

S1=$(sha "$CFG/schemas/s@1.json")
T1=$(sha "$CFG/schemas/t@1.json")

# --- registry state the stub serves -----------------------------------------
cat > "$WORK/state.json" <<EOF
{
  "projects": [
    {"prefix": "PRJ", "identity": "$REPO"},
    {"prefix": "GON", "identity": "$WORK/gone"}
  ],
  "lint": {
    "a.toml": {"ok": true, "data": {"name": "a", "version": 2, "registration": "unchanged"}},
    "b.toml": {"ok": true, "data": {"name": "b", "version": 1, "registration": "new"}},
    "c.toml": {"ok": false, "code": "CONFLICT", "error": "c@1 is registered with different bytes (aa != bb)"},
    "d.toml": {"ok": false, "code": "VALIDATION_ERROR", "error": "step \"x\": vote_rule \"v\" is not registered here"},
    "r.toml": {"ok": true, "data": {"name": "r", "version": 3, "registration": "unchanged"}}
  },
  "workflows": [
    {"name": "a", "version": 1},
    {"name": "a", "version": 2},
    {"name": "c", "version": 1},
    {"name": "r", "version": 2},
    {"name": "r", "version": 3, "deprecated_at_ms": 1},
    {"name": "gone", "version": 4},
    {"name": "dead", "version": 1, "deprecated_at_ms": 1}
  ],
  "schemas": [
    {"name": "s", "version": 1, "source_sha256": "$S1"},
    {"name": "s", "version": 3, "source_sha256": "x"},
    {"name": "t", "version": 1, "source_sha256": "$T1", "deprecated_at_ms": 1},
    {"name": "u", "version": 1, "source_sha256": "0000"},
    {"name": "old", "version": 1, "source_sha256": "x", "deprecated_at_ms": 1},
    {"name": "agg", "version": 1, "source_sha256": "x", "builtin": true}
  ],
  "show": {
    "a@2": {"source_path": "$CFG/workflows/a.toml", "source_status": {"state": "drifted"},
            "definition": {"steps": [
              {"name": "impl", "executor": "x", "packet": ["contracts/{executor}.md"]},
              {"name": "review", "fanout": ["judge-a", "judge-b"], "packet": ["contracts/{executor}.md"]}
            ]}},
    "r@3": {"source_path": "$CFG/workflows/r.toml", "source_status": {"state": "matches"},
            "definition": {"steps": []}}
  }
}
EOF

cat > "$WORK/bin/docket" <<'EOF'
#!/usr/bin/env python3
import json, os, sys
d = os.environ["STUB_DIR"]
with open(os.path.join(d, "calls.log"), "a") as log:
    log.write(" ".join(sys.argv[1:]) + "\n")
state = json.load(open(os.path.join(d, "state.json")))
a = sys.argv[1:]
def out(o):
    print(json.dumps(o)); sys.exit(0 if o.get("ok") else 1)
trunc = os.environ.get("STUB_TRUNCATED") == "1"
if a[:2] == ["project", "list"]:
    cwd = os.path.realpath(os.getcwd())
    out({"ok": True, "data": {"items": [dict(p, current=os.path.realpath(p["identity"]) == cwd) for p in state["projects"]]}})
if a[:2] == ["workflow", "lint"]:
    out(state["lint"][os.path.basename(a[2])])
if a[:2] in (["workflow", "list"], ["schema", "list"]):
    items = state["workflows" if a[0] == "workflow" else "schemas"]
    out({"ok": True, "data": {"items": items, "total": len(items), "truncated": trunc}})
if a[:2] == ["workflow", "show"]:
    out({"ok": True, "data": state["show"][a[2]]})
out({"ok": False, "error": "stub: unexpected call " + " ".join(a)})
EOF
chmod +x "$WORK/bin/docket"
export PATH="$WORK/bin:$PATH" STUB_DIR="$WORK"

# --- one project ------------------------------------------------------------
: > "$WORK/calls.log"
(cd "$REPO" && python3 "$SCRIPT") > "$WORK/plan.txt" 2> "$WORK/err"
ok $? "single-project plan exits 0 without --strict"

has() { grep -qF -- "$1" "$WORK/plan.txt"; }
line_of() { grep -nF -- "$1" "$WORK/plan.txt" | head -1 | cut -d: -f1; }

has "project: PRJ $REPO"; ok $? "names the project the checkout resolves to"
has "REGISTER  docket schema register s@2 $CFG/schemas/s@2.json"; ok $? "unregistered corpus schema version is REGISTER"
has "RESTORE   docket schema deprecate t@1 --restore"; ok $? "retired corpus schema version is RESTORE"
has "CONFLICT  # schema u@1 registered bytes"; ok $? "schema hash mismatch is CONFLICT"
has "DEPRECATE docket schema deprecate s@3"; ok $? "live schema version with no file is DEPRECATE"
has "INVALID   # $CFG/schemas/badname.json is not named"; ok $? "schema file without name@version is INVALID"
! has "schema deprecate s@1"; ok $? "registered, matching schema version is left alone"
! has "agg@1"; ok $? "builtin schema is never retired"
! has "old@1"; ok $? "already-retired schema is left alone"

has "DANGLING  # $CFG/contracts/y.md pins payload s@9"; ok $? "contract payload with no schema file is DANGLING"
has "DANGLING  # $CFG/contracts/y.md includes fragments/nope.md"; ok $? "contract include with no file is DANGLING"
! has "contracts/x.md"; ok $? "contract whose payload and includes resolve is clean"
! has "s@404"; ok $? "only frontmatter is read for payload pins"

has "REGISTER  docket workflow lint $CFG/workflows/b.toml && docket workflow register $CFG/workflows/b.toml"; ok $? "new workflow is REGISTER"
has "DEPRECATE docket workflow deprecate a@1"; ok $? "other live version of a corpus workflow is DEPRECATE"
has "RESTORE   docket workflow deprecate r@3 --restore"; ok $? "retired corpus workflow version is RESTORE"
has "DEPRECATE docket workflow deprecate r@2"; ok $? "version binding in place of a retired corpus version is DEPRECATE"
has "CONFLICT  # workflow c@1 registered bytes"; ok $? "workflow lint CONFLICT is reported"
! has "workflow deprecate c@"; ok $? "a CONFLICT name's binding is left untouched"
has "INVALID   # $CFG/workflows/d.toml fails lint"; ok $? "workflow lint failure is INVALID"
has "ORPHAN    # workflow gone declared by no file; still binding: [4]"; ok $? "live workflow name with no file is ORPHAN"
! has "dead"; ok $? "retired orphan workflow is not reported"
has "DRIFT     # workflow a@2 source drifted"; ok $? "drifted binding source is DRIFT"
has "step review packs contracts/judge-b.md"; ok $? "fanout seat with no contract is DANGLING"
! has "contracts/judge-a.md"; ok $? "fanout seat with a contract is clean"
! has "packs contracts/x.md"; ok $? "executor step with a contract is clean"
has "target binding set = 4 workflows, 4 schema versions"; ok $? "targets count corpus workflows (CONFLICT names included) and schema files"

s_in=$(line_of "schema register s@2"); w_in=$(line_of "workflow register"); w_out=$(line_of "workflow deprecate a@1"); s_out=$(line_of "schema deprecate s@3")
[ "$s_in" -lt "$w_in" ] && [ "$w_in" -lt "$w_out" ] && [ "$w_out" -lt "$s_out" ]
ok $? "apply order: schemas in, workflows in, workflows out, schemas out"

! grep -qE '^(workflow|schema) (register|deprecate)' "$WORK/calls.log"; ok $? "planning runs no register or deprecate"

(cd "$REPO" && python3 "$SCRIPT" --strict) > /dev/null 2>&1
[ $? -eq 1 ]; ok $? "--strict exits 1 while actionable lines remain"

(cd "$REPO" && STUB_TRUNCATED=1 python3 "$SCRIPT") > /dev/null 2> "$WORK/err"
rc=$?
[ $rc -eq 2 ] && grep -q "truncated" "$WORK/err"; ok $? "a truncated registry listing refuses to plan (exit 2)"

# --- every project ----------------------------------------------------------
python3 "$SCRIPT" --all-projects --summary > "$WORK/summary.txt" 2> "$WORK/err"
ok $? "--all-projects --summary exits 0"
grep -qE '^PRJ +.*[0-9]+ DEPRECATE' "$WORK/summary.txt"; ok $? "summary counts each project's actions"
grep -qF "GON    SKIPPED checkout missing at $WORK/gone" "$WORK/summary.txt"; ok $? "a missing checkout is SKIPPED, not a crash"

python3 "$SCRIPT" "$REPO" > "$WORK/arg.txt" 2>&1
grep -qF "project: PRJ $REPO" "$WORK/arg.txt"; ok $? "a checkout argument plans that project from any cwd"

# --- SKILL.md side ----------------------------------------------------------
grep -qF 'scripts/reconcile_plan.py' "$SKILL"; ok $? "SKILL.md runs the installed planner script"
! grep -q '^```python' "$SKILL"; ok $? "SKILL.md carries no inline planner program"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
