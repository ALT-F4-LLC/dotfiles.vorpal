#!/bin/bash

# Guard suite: the repository carries no advisor subagent, no hook that gates
# on the advisor, and no prose that launches one; the settings builder wires
# the built-in advisor model.
#
# Defect class: the advisor is a built-in tool, enabled by one setting
# (advisorModel, built in src/user/claude_code/settings.rs and wired in
# src/user/claude_code.rs). A restored agent file, a restored gate hook, its
# registration in the settings builder, or prose that launches an advisor
# agent would shadow the tool or promise a launch that cannot happen. The
# consult rules themselves live in tests/advisor-consult-rules.test.sh.
#
# The scan reads TRACKED files (git ls-files), so an untracked scratch copy
# does not count and a tracked leftover does. tests/ is skipped: the suites
# quote the retired strings on purpose to pin their absence, this one
# included. Text is flattened to one line before matching and compared
# case-insensitively, so rewrapping or recasing a retired phrase does not
# hide it. Binary files are skipped by grep -I.
#
# The one place the retired hook name may appear is the exact absence
# assertion in the Rust tests of src/user/claude_code.rs; any other line there
# naming it fails the registration pin.
#
# MIGRATION_ROOT overrides the repository root, so a mutation probe can point
# the suite at a deliberately broken COPY of a git checkout under $TMPDIR.
# The self-checks build their own throwaway repository and run the checks
# against it; MIGRATION_SELFCHECK=0 skips them. Each assertion's mutant, proven
# red:
#
#   a1  agents/advisor.md tracked: the agent-file pin fails
#   a2  hooks/docket-advisor-first-hook.sh tracked: the hook-file pin fails
#   a3  the hook registered in claude_code.rs: the registration pin fails
#   a4  another line in claude_code.rs naming the hook, beside the exact
#       absence assertion: the registration pin fails
#   a5  the hook name in another tracked non-test file: the hook-name pin fails
#   a6  a tracked non-test path containing the hook name: the same pin fails
#   b1-b6  each retired phrase in a tracked non-test file: its phrase pin
#       fails; recased, or wrapped across two lines: still fails (b7, b8)
#   c1  the wiring removed from claude_code.rs: the wiring pin fails
#   ok1 retired strings under tests/, in an untracked file, or in a tracked
#       file that only says "advisor consult" or "advisory": all stay green

set -u

root_default="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
root="${MIGRATION_ROOT:-$root_default}"

agent_file="src/user/claude_code/agents/advisor.md"
hook_file="src/user/claude_code/hooks/docket-advisor-first-hook.sh"
rust_file="src/user/claude_code.rs"
hook_name="docket-advisor-first-hook"

# The one line of claude_code.rs that may name the retired hook: the absence
# assertion. Leading whitespace is ignored; nothing else is.
absence_line='assert!(!rendered.contains("docket-advisor-first-hook"));'

pass=0
fail=0

ok() {
  pass=$((pass + 1))
  echo "ok   $1"
}

bad() {
  fail=$((fail + 1))
  echo "FAIL $1"
}

# tracked ROOT: tracked paths under ROOT, one per line.
tracked() { git -C "$1" ls-files; }

# file_absent ROOT PATH DESC: PATH is not tracked under ROOT.
file_absent() {
  if tracked "$1" | grep -qxF -- "$2"; then
    bad "$3 (still tracked: $2)"
  else
    ok "$3"
  fi
}

# scan ROOT ERE: tracked non-test files whose whitespace-flattened text
# matches ERE case-insensitively.
scan() {
  local r="$1" re="$2" p
  while IFS= read -r p; do
    [ -f "$r/$p" ] || continue
    if tr '\n' ' ' <"$r/$p" | tr -s ' ' | grep -IiqE -- "$re"; then
      echo "$p"
    fi
  done < <(tracked "$r" | grep -v '^tests/')
}

# no_phrase ROOT ERE DESC: no tracked non-test file matches ERE.
no_phrase() {
  local hits
  hits="$(scan "$1" "$2" | tr '\n' ' ')"
  if [ -n "$hits" ]; then
    bad "$3 (found in: $hits)"
  else
    ok "$3"
  fi
}

# no_hook_name ROOT DESC: no tracked non-test path, and no tracked non-test
# file other than claude_code.rs, names the retired hook.
no_hook_name() {
  local hits
  hits="$(tracked "$1" | grep -v '^tests/' | grep -F -- "$hook_name" | tr '\n' ' ')"
  hits="$hits$(scan "$1" "$hook_name" | grep -vxF -- "$rust_file" | tr '\n' ' ')"
  if [ -n "$hits" ]; then
    bad "$2 (found: $hits)"
  else
    ok "$2"
  fi
}

# no_registration ROOT DESC: claude_code.rs names the retired hook only on the
# exact absence assertion line.
no_registration() {
  local line hits=0
  if [ ! -f "$1/$rust_file" ]; then
    bad "$2 (missing file $rust_file)"
    return
  fi
  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"
    [ "$line" = "$absence_line" ] || hits=$((hits + 1))
  done < <(grep -F -- "$hook_name" "$1/$rust_file")
  if [ "$hits" -gt 0 ]; then
    bad "$2 ($hits other line(s) in $rust_file name the hook)"
  else
    ok "$2"
  fi
}

# wired ROOT DESC: claude_code.rs wires the advisor model.
wired() {
  if grep -qF -- '.with_advisor_model("fable")' "$1/$rust_file" 2>/dev/null; then
    ok "$2"
  else
    bad "$2 (missing in $rust_file: .with_advisor_model(\"fable\"))"
  fi
}

run_checks() {
  local r="$1"
  file_absent "$r" "$agent_file" "no advisor agent file"
  file_absent "$r" "$hook_file" "no advisor-first hook file"
  no_hook_name "$r" "no tracked file or path names the advisor-first hook outside the settings builder"
  no_registration "$r" "claude_code.rs does not register the advisor-first hook"
  no_phrase "$r" 'subagent_type:[[:space:]]*["'"'"']?advisor' "no subagent_type: advisor launch"
  no_phrase "$r" 'agents/advisor\.md' "no reference to agents/advisor.md"
  no_phrase "$r" 'advisor agent' "no advisor agent"
  no_phrase "$r" 'advisor launch' "no advisor launch"
  no_phrase "$r" 'launch the `advisor` agent' "no launch-the-advisor-agent phrase"
  wired "$r" "claude_code.rs wires .with_advisor_model(\"fable\")"
}

# ---- self-checks: a throwaway repository, mutated per case ----------------

# mk_fixture DIR: a clean tracked tree. Retired strings sit under tests/; the
# ok1 case adds an untracked file with them too. Both must stay green.
mk_fixture() {
  local d="$1"
  mkdir -p "$d/src/user/claude_code/references" "$d/tests"
  git -C "$d" init -q
  cat >"$d/$rust_file" <<'RUST'
fn settings() {
    builder.with_advisor_model("fable");
}
#[test]
fn no_gate() {
    assert!(!rendered.contains("docket-advisor-first-hook"));
}
RUST
  printf 'Consult the advisor before an approach. An advisory note.\n' >"$d/src/user/claude_code/CLAUDE.md"
  cat >"$d/tests/retired.test.sh" <<'TEST'
subagent_type: advisor
agents/advisor.md
advisor agent
advisor launch
launch the `advisor` agent
docket-advisor-first-hook
TEST
  git -C "$d" add -A
}

# stage DIR: stage every change so ls-files sees it.
stage() { git -C "$1" add -A; }

# run_fixture DIR: the checks' output for DIR.
run_fixture() { out="$(run_checks "$1")"; }

# expect_red NAME PATTERN: some FAIL line contains PATTERN.
expect_red() {
  if printf '%s\n' "$out" | grep -F 'FAIL' | grep -qF -- "$2"; then
    ok "self-check $1: red on '$2'"
  else
    bad "self-check $1: expected a FAIL line containing '$2'"
  fi
}

# expect_green NAME: no FAIL line.
expect_green() {
  if printf '%s\n' "$out" | grep -q '^FAIL'; then
    bad "self-check $1: expected green, got: $(printf '%s\n' "$out" | grep '^FAIL' | head -3 | tr '\n' ' ')"
  else
    ok "self-check $1: green"
  fi
}

# fresh NAME: a new fixture directory in $d.
fresh() { d="$tmp/$1"; mkdir -p "$d"; mk_fixture "$d"; }

self_checks() {
  local d out p s

  tmp="$(mktemp -d "${TMPDIR:-/tmp}/advisor-migration.XXXXXX")" || return
  trap 'rm -rf "$tmp"' RETURN

  fresh ok1
  printf 'advisor agent advisor launch\n' >"$d/untracked.md"
  run_fixture "$d"; expect_green ok1-clean-fixture
  out="$(run_checks "$d")"
  if [ "$(printf '%s\n' "$out" | grep -c '^ok ')" -ge 10 ]; then
    ok "self-check ok1: every check ran on the fixture"
  else
    bad "self-check ok1: fewer than ten checks ran"
  fi

  fresh ok2
  printf 'The advisor consult returned an advisory note.\n' >"$d/notes.md"; stage "$d"
  run_fixture "$d"; expect_green ok2-consult-and-advisory-words

  fresh a1
  mkdir -p "$d/$(dirname "$agent_file")"; echo x >"$d/$agent_file"; stage "$d"
  run_fixture "$d"; expect_red a1-agent-file 'still tracked: src/user/claude_code/agents/advisor.md'

  fresh a2
  mkdir -p "$d/$(dirname "$hook_file")"; echo x >"$d/$hook_file"; stage "$d"
  run_fixture "$d"; expect_red a2-hook-file 'still tracked: src/user/claude_code/hooks/docket-advisor-first-hook.sh'

  fresh a3
  printf '        .with_hook("PreToolUse", Some("AskUserQuestion"), "bash ~/.claude/hooks/docket-advisor-first-hook.sh", "command")\n' >>"$d/$rust_file"; stage "$d"
  run_fixture "$d"; expect_red a3-registration 'claude_code.rs does not register the advisor-first hook'

  fresh a4
  printf '    assert!(!rendered.contains("docket-advisor-first-hook")); // and more\n' >>"$d/$rust_file"; stage "$d"
  run_fixture "$d"; expect_red a4-extended-assertion 'claude_code.rs does not register the advisor-first hook'

  fresh a5
  printf 'Run hooks/docket-advisor-first-hook.sh first.\n' >"$d/notes.md"; stage "$d"
  run_fixture "$d"; expect_red a5-hook-name 'names the advisor-first hook outside the settings builder'

  fresh a6
  mkdir -p "$d/hooks"; echo x >"$d/hooks/$hook_name.sh"; stage "$d"
  run_fixture "$d"; expect_red a6-hook-name-in-a-path 'names the advisor-first hook outside the settings builder'

  s=0
  for p in 'subagent_type: advisor|no subagent_type: advisor launch' \
    'subagent_type: "advisor"|no subagent_type: advisor launch' \
    'see agents/advisor.md|no reference to agents/advisor.md' \
    'ask the advisor agent|no advisor agent' \
    'an advisor launch|no advisor launch' \
    'launch the `advisor` agent|no launch-the-advisor-agent phrase'; do
    s=$((s + 1))
    fresh "b$s"
    printf '%s\n' "${p%%|*}" >"$d/notes.md"; stage "$d"
    run_fixture "$d"; expect_red "b$s-phrase" "${p##*|}"
  done

  fresh b7
  printf 'Ask the ADVISOR Agent to look.\n' >"$d/notes.md"; stage "$d"
  run_fixture "$d"; expect_red b7-recased 'no advisor agent'

  fresh b8
  printf 'Ask the advisor\n  agent to look.\n' >"$d/notes.md"; stage "$d"
  run_fixture "$d"; expect_red b8-wrapped 'no advisor agent'

  fresh c1
  printf 'fn settings() {}\n' >"$d/$rust_file"; stage "$d"
  run_fixture "$d"; expect_red c1-wiring-removed 'missing in src/user/claude_code.rs: .with_advisor_model("fable")'
}

run_checks "$root"

if [ "${MIGRATION_SELFCHECK:-1}" = 1 ]; then
  echo
  self_checks
fi

echo
echo "advisor-tool-migration: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && echo "advisor-tool-migration: PASS"
[ "$fail" -eq 0 ]
