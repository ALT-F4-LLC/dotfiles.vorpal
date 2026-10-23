#!/bin/bash

# Contract suite for the three audit skills that file Docket issues instead of
# editing the checkout: corpus-check, docket-cli-audit, and docket-retro.
# simplify-code and simplify-corpus pin the same contract in their own suites.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `bash` and `grep`.
#
# WHY THIS EXISTS. These skills once applied their fixes. Prose is all that
# keeps them filing, so a reword that restores an edit, a commit, or a replayed
# idempotency key would pass every other gate. The suite pins the label, the
# fingerprint or key shape, the regression suffix, and the absence of
# checkout-writing steps.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKILLS="${SKILLS_DIR:-${SCRIPT_DIR}/../src/user/claude_code/skills}"

pass=0
fail=0

check() {
    local desc="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        printf 'FAIL: %s\n' "$desc" >&2
    fi
}

has() { grep -qF -- "$2" "$1"; }
lacks() { ! grep -qiE -- "$2" "$1"; }

for s in corpus-check docket-cli-audit docket-retro; do
    f="${SKILLS}/${s}/SKILL.md"
    [ -f "$f" ] || { printf 'FATAL: %s not found\n' "$f" >&2; exit 2; }
    check "${s}: files with docket issue" has "$f" 'docket issue'
    check "${s}: passes --idempotency-key" has "$f" '--idempotency-key'
    check "${s}: regression key carries /after-<prior issue id>" has "$f" '/after-<prior issue id>'
    check "${s}: closed wont-do files nothing" has "$f" 'wont-do'
    check "${s}: never commits or pushes" lacks "$f" 'git (commit|push)|commit skill|landing (them|fixes)|Apply directly|Apply and verify|vote/apply|fixed directly|confirm the staged batch'
done

check "corpus-check: label corpus-drift" has "${SKILLS}/corpus-check/SKILL.md" 'corpus-drift'
check "corpus-check: fingerprint line" has "${SKILLS}/corpus-check/SKILL.md" 'Drift fingerprint:'
check "corpus-check: no operator-confirmed semantic fixes" lacks "${SKILLS}/corpus-check/SKILL.md" 'applies? semantic fixes|fix(es)? mechanical breakage directly'

check "docket-cli-audit: label cli-drift" has "${SKILLS}/docket-cli-audit/SKILL.md" 'cli-drift'
check "docket-cli-audit: evidence fingerprint" has "${SKILLS}/docket-cli-audit/SKILL.md" 'docket-cli-audit/evidence/'
check "docket-cli-audit: fresh inventory goes to scratch" has "${SKILLS}/docket-cli-audit/SKILL.md" '--inventory "$SCRATCH/cli-inventory.json" --write'
check "docket-cli-audit: fresh fixtures go to scratch" has "${SKILLS}/docket-cli-audit/SKILL.md" '--fixtures "$SCRATCH/cli-fixtures.json" --write'
check "docket-cli-audit: every runnable --write targets scratch" bash -c '! grep -E "^python3 .*--write" "$1" | grep -vF SCRATCH' _ "${SKILLS}/docket-cli-audit/SKILL.md"

check "docket-retro: label retro-proposal" has "${SKILLS}/docket-retro/SKILL.md" 'retro-proposal'
check "docket-retro: fingerprint line" has "${SKILLS}/docket-retro/SKILL.md" 'Retro fingerprint:'
check "docket-retro: dedupe lists closed issues" has "${SKILLS}/docket-retro/SKILL.md" 'docket issue list --all'
check "docket-retro: truncation held" has "${SKILLS}/docket-retro/SKILL.md" '.data.truncated'
check "docket-retro: store state is filed, not handed over" has "${SKILLS}/docket-retro/SKILL.md" 'store state is filed'

section_has() { awk -v h="### $2" 'index($0,"### ")==1 || index($0,"## ")==1 {on=($0==h)} on' "$1" | sed -n '/Never target/,$p' | grep -qF -- "$3"; }
for sec in "Simplify mode" "Tighten mode"; do
    for p in 'src/user/claude_code/CLAUDE.md' 'src/user/claude_code/references/working-agreement.md'; do
        check "simplify-corpus: ${sec} Never-target list names ${p}" section_has "${SKILLS}/simplify-corpus/SKILL.md" "${sec}" "${p}"
    done
done
check "docket-cli-audit: closed decision issue files nothing" has "${SKILLS}/docket-cli-audit/SKILL.md" 'A closed decision issue without `wont-do`'

printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
