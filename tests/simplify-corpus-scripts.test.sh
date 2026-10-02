#!/bin/bash

# Behavior suite for the simplify-corpus skill's mechanical scripts, all
# under skills/simplify-corpus/scripts: protected-spans.sh, the
# protected-span check behind both workflows and the main session's landing
# step; tighten-chunks.sh, which splits a file into chunks for tighten.js and
# joins them back; and simplify-check.sh with syntax_check.py, the check
# behind simplify-corpus.js.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by
# name and this one is in that list. It needs bash, awk, git, coreutils,
# node, python3, and mikefarah yq v4 — no engine, no network, and it never
# runs a workflow.
#
# WHY THIS EXISTS. The check once paired quote marks across the whole file,
# so quote marks inside code shifted every later pair. That locked 78% of
# docket-run's prose behind spans no edit could pass, and left 15 of its 23
# real quotations unchecked. Each probe below alters one
# protected span in a copy and expects exactly that kind to report it, and
# the regression probe edits prose between two such code spans and expects
# no report at all. The chunk properties run over every tracked Markdown
# file: a split that joins back to anything but the original bytes, or whose
# chunks' spans do not add up to the file's, would let a chunk-level check
# pass a broken file. The simplify-check probes break each kind's syntax
# gate and the contract version rule once, so a gate that stops gating is
# caught here rather than by a corrupted file landing.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
SCRIPTS="${SIMPLIFY_CORPUS_SCRIPTS:-${ROOT}/src/user/claude_code/skills/simplify-corpus/scripts}"
SPANS="${SCRIPTS}/protected-spans.sh"
CHUNKS="${SCRIPTS}/tighten-chunks.sh"
CHECK="${SCRIPTS}/simplify-check.sh"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

for script in "$SPANS" "$CHUNKS" "$CHECK" "${SCRIPTS}/syntax_check.py"; do
    [ -f "$script" ] || fatal "script not found: ${script}"
done
for tool in awk git cmp comm node python3 yq; do
    command -v "$tool" >/dev/null 2>&1 || fatal "${tool} is required to run this test"
done

WORK=$(mktemp -d "${TMPDIR:-/tmp}/simplify-corpus-scripts.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { # <condition-already-evaluated: 0/1> <label>
    if [ "$1" -eq 0 ]; then
        pass=$((pass + 1)); printf 'PASS: %s\n' "$2"
    else
        fail=$((fail + 1)); printf 'FAIL: %s\n' "$2" >&2
    fi
}

# ---- protected-spans.sh -------------------------------------------------

BASE="${WORK}/base.md"
cat > "$BASE" <<'MD'
---
name: fixture
description: >-
  Use on "check the spans" or "run the probe".
---

# Fixture

Pass the reason with `docket step reap STEP-N --reason "`. This sentence
sits between the two quote marks and must stay free to change. Close it
with `"` on the same line. Say "keep this phrase" exactly.

## Commands

```bash
docket step list --json | jq '.data[] | select(.status=="pending")'
echo "one"

echo "two"
```

See §4 and docket-run/SKILL.md:120, and [the guide](references/guide.md).
A quotation can hold code: "run `make test` first" is one span.

<!-- keep this comment -->

Preserve the work first:

    git -C <wt> add -A          # untracked included
    git tag preserved/<run> <sha>

- A list item that wraps
  onto a second line.

    A continuation paragraph of the item, indented four spaces, is prose.

## Ending

Last paragraph.

MD

variant() { # <name> <sed expression> — a copy of BASE with one edit
    sed "$2" "$BASE" > "${WORK}/$1.md"
    cmp -s "$BASE" "${WORK}/$1.md" && fatal "variant $1: the sed expression matched nothing"
}

report() { # <mode> <name> — the report and exit code for BASE against a variant
    bash "$SPANS" "$1" "$BASE" "${WORK}/$2.md" > "${WORK}/$2.$1.out" 2>&1
    echo $? > "${WORK}/$2.$1.rc"
}

changed_kinds() { # <name> <mode> — the kinds reported changed, space-separated
    sed -n 's/^kind \([a-z]*\) changed.*/\1/p' "${WORK}/$1.$2.out" | tr '\n' ' ' | sed 's/ $//'
}

expect_only() { # <name> <kind> <label> — equal mode reports exactly that kind
    report equal "$1"
    [ "$(cat "${WORK}/$1.equal.rc")" = 1 ] && [ "$(changed_kinds "$1" equal)" = "$2" ]
    ok $? "$3 -> only $2 changed"
}

cp "$BASE" "${WORK}/same.md"
report equal same
[ "$(cat "${WORK}/same.equal.rc")" = 0 ]; ok $? 'a file compared with itself is intact (exit 0)'
grep -qx 'result intact' "${WORK}/same.equal.out"; ok $? 'the report ends in result intact'
[ "$(grep -c '^kind [a-z]* ok$' "${WORK}/same.equal.out")" = 10 ]; ok $? 'equal mode reports all ten kinds'
grep -qE '^bytes [0-9]+ [0-9]+$' "${WORK}/same.equal.out"; ok $? 'the report carries byte counts'
[ "$(sed -n 's/^lines \([0-9]*\) .*/\1/p' "${WORK}/same.equal.out")" = "$(wc -l < "$BASE" | tr -d ' ')" ]; ok $? 'the line count is wc -l, blank lines included'

variant between 's/sits between the two quote marks and must/sits between them and must/'
whole_file_pairing() { tr -s '[:space:]' ' ' < "$1" | grep -oE '"[^"]+"' | sort; }
[ "$(whole_file_pairing "$BASE")" != "$(whole_file_pairing "${WORK}/between.md")" ]
ok $? 'self-check: the whole-file pairing this script replaced rejects the next edit'
report equal between
[ "$(cat "${WORK}/between.equal.rc")" = 0 ]; ok $? 'regression: prose between two code spans that each hold a quote mark is free to change'

printf '%s\n' 'The panel is 5" wide.' '' 'This paragraph must stay free to change.' '' 'Say "keep this phrase" exactly.' > "${WORK}/stray.md"
sed 's/must stay free to change/stays free to change/' "${WORK}/stray.md" > "${WORK}/stray-edit.md"
bash "$SPANS" equal "${WORK}/stray.md" "${WORK}/stray-edit.md" > /dev/null 2>&1
ok $? 'an unmatched quote mark pairs nothing outside its own paragraph'

{ sed -n '1,8p' "$BASE"; printf '%s\n' 'Pass the reason with `docket step reap STEP-N --reason "`.' 'This sentence sits between the two quote marks and must stay free to change.' 'Close it with `"` on the same line. Say "keep this phrase" exactly.'; sed -n '12,$p' "$BASE"; } > "${WORK}/rewrap.md"
report equal rewrap
[ "$(cat "${WORK}/rewrap.equal.rc")" = 0 ]; ok $? 'rewrapping a paragraph around code and quotations is intact'

variant quote 's/"keep this phrase"/"keep that phrase"/'
expect_only quote quotes 'a reworded quotation'
variant fencequote 's/select(.status=="pending")/select(.status=="ready")/'
expect_only fencequote fences 'a quote mark inside a fenced block'
variant fenceblank '18d'
expect_only fenceblank fences 'a blank line removed inside a fenced block'
variant code 's/`make test`/`make check`/'
report equal code
[ "$(changed_kinds code equal)" = "code quotes" ]; ok $? 'code inside a quotation is part of the quotation: both kinds report it'
variant heading 's/^## Commands$/## Command list/'
expect_only heading headings 'a reworded heading'
awk '/^## Commands$/ { print "## Ending"; next } /^## Ending$/ { print "## Commands"; next } { print }' "$BASE" > "${WORK}/order.md"
report equal order
grep -q '^kind headings changed: order$' "${WORK}/order.equal.out"; ok $? 'swapped headings report an order change'
variant section 's/§4/§5/'
expect_only section references 'a changed section reference'
variant fileline 's/SKILL.md:120/SKILL.md:121/'
expect_only fileline references 'a changed file:line reference'
variant link 's/(references\/guide.md)/(references\/guides.md)/'
expect_only link links 'a changed link target'
variant frontmatter 's/"run the probe"/"run a probe"/'
expect_only frontmatter frontmatter 'an edited frontmatter trigger phrase'
variant comment 's/keep this comment/keep that comment/'
expect_only comment comments 'an edited HTML comment'
variant indented 's/add -A          # untracked included/add -u          # untracked included/'
expect_only indented indented 'an edited line of an indented code block'
variant continuation 's/indented four spaces, is prose\./indented four spaces, stays prose./'
report equal continuation
[ "$(cat "${WORK}/continuation.equal.rc")" = 0 ]; ok $? 'an indented paragraph after a list line is a list continuation, free to change'
[ "$(bash "$SPANS" extract indented "$BASE" | wc -l | tr -d ' ')" = 2 ]; ok $? 'only the code block after a prose line counts as indented code'

head -c "$(($(wc -c < "$BASE") - 1))" "$BASE" > "${WORK}/nofinal.md"
expect_only nofinal edges 'a removed final newline'
sed '$d' "$BASE" > "${WORK}/notrailing.md"
expect_only notrailing edges 'a removed trailing blank line'

variant deleted 's/ Say "keep this phrase" exactly\.//'
report subset deleted
[ "$(cat "${WORK}/deleted.subset.rc")" = 0 ]; ok $? 'subset mode: deleting a quotation along with its prose is allowed'
report subset quote
[ "$(cat "${WORK}/quote.subset.rc")" = 1 ] && grep -q '^kind quotes changed: added "keep that phrase"$' "${WORK}/quote.subset.out"; ok $? 'subset mode: an altered quotation reports the added span'
report subset fencequote
[ "$(changed_kinds fencequote subset)" = "fences" ]; ok $? 'subset mode: an altered fence line is an addition'
[ "$(grep -c '^kind ' "${WORK}/quote.subset.out")" = 5 ]; ok $? 'subset mode checks code blocks, quotes, links, and comments only'
report subset indented
[ "$(changed_kinds indented subset)" = "indented" ]; ok $? 'subset mode: an altered indented code line is an addition'

bash "$SPANS" equal "$BASE" "${WORK}/missing.md" > /dev/null 2>&1
[ $? = 2 ]; ok $? 'a missing file exits 2'
bash "$SPANS" sideways "$BASE" "$BASE" > /dev/null 2>&1
[ $? = 2 ]; ok $? 'an unknown mode exits 2'
bash "$SPANS" extract nonsense "$BASE" > /dev/null 2>&1
[ $? = 2 ]; ok $? 'an unknown kind exits 2'
[ "$(bash "$SPANS" extract quotes "$BASE" | sort | tr '\n' '|')" = '"keep this phrase"|"run `make test` first"|' ]
ok $? 'quotations come from prose only, and a quote mark inside inline code never opens one'

# ---- simplify-check.sh ----------------------------------------------------

check() { # <name> <kind> <original> <candidate> — the report and exit code
    bash "$CHECK" "$2" "$3" "$4" > "${WORK}/$1.check" 2>&1
    echo $? > "${WORK}/$1.rc"
}
gate_failed() { # <name> <gate> — the run exited 1 and named that gate failed
    [ "$(cat "${WORK}/$1.rc")" = 1 ] && grep -q "^gate $2 failed: " "${WORK}/$1.check"
}
passed() { # <name> — the run exited 0 with result intact
    [ "$(cat "${WORK}/$1.rc")" = 0 ] && grep -qx 'result intact' "${WORK}/$1.check"
}

printf '%s\n' 'export const meta = { name: "x" }' 'function a() { return 1 }' 'return { a: a() }' > "${WORK}/module.js"
printf '%s\n' 'export const meta = { name: "x" }' 'function a() { return 1 }' 'return { a: a() }' > "${WORK}/module-tight.js"
printf '%s\n' 'export const meta = { name: "x" }' 'function a() { return 1 }' 'function a() { return 2 }' 'return a()' > "${WORK}/module-dup.js"
printf '%s\n' 'export const meta = = { name: "x" }' 'return 1' > "${WORK}/module-bad.js"
check js-ok javascript "${WORK}/module.js" "${WORK}/module-tight.js"
passed js-ok; ok $? 'javascript: a workflow module with a top-level return passes'
check js-dup javascript "${WORK}/module.js" "${WORK}/module-dup.js"
gate_failed js-dup node-module && grep -q "already been declared" "${WORK}/js-dup.check"; ok $? 'javascript: a duplicate top-level function fails in module mode, with node'"'"'s error line'
check js-bad javascript "${WORK}/module.js" "${WORK}/module-bad.js"
gate_failed js-bad node-module; ok $? 'javascript: a syntax error fails the gate'

printf '%s\n' 'def f():' '    return 1' > "${WORK}/ok.py"
printf '%s\n' 'def f(:' > "${WORK}/bad.py"
check py-ok python "${WORK}/ok.py" "${WORK}/ok.py"
passed py-ok; ok $? 'python: a file that compiles passes'
check py-bad python "${WORK}/ok.py" "${WORK}/bad.py"
gate_failed py-bad python && grep -q 'SyntaxError' "${WORK}/py-bad.check"; ok $? 'python: a syntax error fails the gate'
[ ! -e "${WORK}/__pycache__" ]; ok $? 'python: the gate writes no bytecode beside the candidate'

printf '%s\n' 'if true; then echo yes; fi' > "${WORK}/ok.sh"
printf '%s\n' 'if then fi' > "${WORK}/bad.sh"
check sh-bad shell "${WORK}/ok.sh" "${WORK}/bad.sh"
gate_failed sh-bad bash-n; ok $? 'shell: a syntax error fails bash -n'

printf '%s\n' '[pipeline]' 'name = "x"' 'version = 7' '' '[nodes.a]' 'version = 99' > "${WORK}/wf.toml"
sed 's/^version = 7$/version = 8/' "${WORK}/wf.toml" > "${WORK}/wf-bumped.toml"
printf '%s\n' '[pipeline' 'name = "x"' > "${WORK}/wf-bad.toml"
check toml-bump workflow-toml "${WORK}/wf.toml" "${WORK}/wf-bumped.toml"
passed toml-bump && grep -qx 'version 7 8' "${WORK}/toml-bump.check"; ok $? 'workflow-toml: the version is read from the [pipeline] table only'
check toml-bad workflow-toml "${WORK}/wf.toml" "${WORK}/wf-bad.toml"
gate_failed toml-bad toml && grep -q "gate toml failed: Error: bad file '-': " "${WORK}/toml-bad.check"; ok $? 'workflow-toml: a parse error fails the gate'
check toml-plain toml "${WORK}/wf.toml" "${WORK}/wf-bumped.toml"
grep -qx 'version -1 -1' "${WORK}/toml-plain.check"; ok $? 'plain toml reports no version'
printf '%s\n' '[pipeline]' 'name = "x"' '' '[nodes.a]' 'version = 3' > "${WORK}/wf-unversioned.toml"
check toml-unversioned workflow-toml "${WORK}/wf-unversioned.toml" "${WORK}/wf-unversioned.toml"
grep -qx 'version -1 -1' "${WORK}/toml-unversioned.check"; ok $? 'workflow-toml: a version outside [pipeline] is not the pipeline'"'"'s'
# A PATH holding every tool the toml path needs except yq.
mkdir -p "${WORK}/no-yq"
for tool in dirname grep sed head cut wc tr awk; do
    ln -s "$(command -v "$tool")" "${WORK}/no-yq/${tool}"
done
PATH="${WORK}/no-yq" "$BASH" "$CHECK" toml "${WORK}/wf.toml" "${WORK}/wf.toml" > "${WORK}/toml-no-yq.check" 2>&1
echo $? > "${WORK}/toml-no-yq.rc"
gate_failed toml-no-yq toml && grep -q '^gate toml failed: .*yq' "${WORK}/toml-no-yq.check" && ! grep -q '^gate toml ok' "${WORK}/toml-no-yq.check"
ok $? 'toml: without yq the gate fails closed and names yq'

printf '%s\n' '---' 'node: x' 'version: 4' '---' '' 'Body, said twice.' 'Body.' > "${WORK}/contract.md"
printf '%s\n' '---' 'node: x' 'version: 5' '---' '' 'Body.' > "${WORK}/contract-bumped.md"
printf '%s\n' '---' 'node: y' 'version: 5' '---' '' 'Body.' > "${WORK}/contract-renamed.md"
check contract-bump contract "${WORK}/contract.md" "${WORK}/contract-bumped.md"
passed contract-bump && grep -qx 'version 4 5' "${WORK}/contract-bump.check"; ok $? 'contract: a version-only frontmatter change passes and reports both versions'
check contract-renamed contract "${WORK}/contract.md" "${WORK}/contract-renamed.md"
[ "$(cat "${WORK}/contract-renamed.rc")" = 1 ] && grep -q '^kind frontmatter changed: removed node: x added node: y$' "${WORK}/contract-renamed.check"
ok $? 'contract: any other frontmatter change fails'
check prose-version prose "${WORK}/contract.md" "${WORK}/contract-bumped.md"
[ "$(cat "${WORK}/prose-version.rc")" = 1 ] && grep -q '^kind frontmatter changed' "${WORK}/prose-version.check"; ok $? 'prose: even a version line is protected frontmatter'

check prose-deleted prose "$BASE" "${WORK}/deleted.md"
passed prose-deleted; ok $? 'prose: deleting a quotation with its prose passes the subset check'
check prose-altered prose "$BASE" "${WORK}/quote.md"
[ "$(cat "${WORK}/prose-altered.rc")" = 1 ] && grep -q '^kind quotes changed: added "keep that phrase"$' "${WORK}/prose-altered.check"; ok $? 'prose: an altered quotation fails the subset check'

bash "$CHECK" nonsense "$BASE" "$BASE" > /dev/null 2>&1
[ $? = 2 ]; ok $? 'an unknown kind exits 2'
bash "$CHECK" prose "$BASE" "${WORK}/missing.md" > /dev/null 2>&1
[ $? = 2 ]; ok $? 'a missing candidate exits 2'

# ---- tighten-chunks.sh --------------------------------------------------

split_ok() { # <file> <workdir> <target>
    bash "$CHUNKS" split "$1" "$2" "$3" > "$2.manifest" 2>&1
}

FENCED="${WORK}/fenced.md"
{
    printf -- '---\nname: x\n---\n\n'
    for i in 1 2 3 4 5 6; do printf 'Paragraph %d.\n\n' "$i"; done
    printf '```bash\n## not a heading\n\necho one\n\n```\n\n'
    for i in 7 8 9; do printf 'Paragraph %d.\n\n' "$i"; done
    printf -- '---\n\nAfter a rule.\n'
} > "$FENCED"
split_ok "$FENCED" "${WORK}/fenced" 1; ok $? 'split succeeds at a one-line target'
starts=$(for c in "${WORK}"/fenced/orig/*.md; do head -n 1 "$c"; done)
! printf '%s\n' "$starts" | grep -qxE 'echo one|## not a heading'; ok $? 'no chunk starts inside a fenced block'
[ "$(printf '%s\n' "$starts" | grep -cx -- '---')" = 1 ]; ok $? 'only the frontmatter chunk starts with ---'
fences_even=0
for c in "${WORK}"/fenced/orig/*.md; do
    [ $(($(grep -c '^[[:space:]]*```' "$c") % 2)) = 0 ] || fences_even=1
done
ok "$fences_even" 'every chunk holds whole fenced blocks'
bash "$CHUNKS" join "${WORK}/fenced" "${WORK}/fenced.joined" > /dev/null && cmp -s "$FENCED" "${WORK}/fenced.joined"
ok $? 'joining with no chunk rewritten reproduces the file'

second=$(sed -n 's/^chunk \([0-9]*\) .*/\1/p' "${WORK}/fenced.manifest" | sed -n 2p)
printf 'Rewritten.\n\n' > "${WORK}/fenced/cand/${second}.md"
out=$(bash "$CHUNKS" join "${WORK}/fenced" "${WORK}/fenced.rewritten" "$second")
grep -qx 'Rewritten.' "${WORK}/fenced.rewritten" && printf '%s\n' "$out" | grep -qE '^joined [0-9]+ chunks, 1 rewritten, [0-9]+ bytes$'
ok $? 'join takes the named chunk from cand and reports it'
bash "$CHUNKS" join "${WORK}/fenced" "${WORK}/fenced.bad" 999 > /dev/null 2>&1
[ $? = 2 ]; ok $? 'join refuses an unknown chunk id'
bash "$CHUNKS" split "$FENCED" "${WORK}/fenced" 1 > /dev/null 2>&1
[ $? = 2 ]; ok $? 'split refuses a workdir that already holds chunks'

printf 'one\n\ntwo\n\nno final newline' > "${WORK}/nonl.md"
split_ok "${WORK}/nonl.md" "${WORK}/nonl" 1 && bash "$CHUNKS" join "${WORK}/nonl" "${WORK}/nonl.joined" > /dev/null && cmp -s "${WORK}/nonl.md" "${WORK}/nonl.joined"
ok $? 'a file without a final newline round-trips'
printf 'one\r\n\r\ntwo\r\n' > "${WORK}/crlf.md"
split_ok "${WORK}/crlf.md" "${WORK}/crlf" 1 && bash "$CHUNKS" join "${WORK}/crlf" "${WORK}/crlf.joined" > /dev/null && cmp -s "${WORK}/crlf.md" "${WORK}/crlf.joined"
ok $? 'a CRLF file round-trips'
: > "${WORK}/empty.md"
split_ok "${WORK}/empty.md" "${WORK}/empty" 200 && grep -qx 'chunks 0' "${WORK}/empty.manifest"
ok $? 'an empty file splits into zero chunks'

# Every tracked Markdown file: split, join back byte for byte, and check
# that the chunks' protected spans add up to the file's, kind by kind.
roundtrip=0
compose=0
files=0
while IFS= read -r f; do
    files=$((files + 1))
    wd="${WORK}/corpus/${files}"
    if ! bash "$CHUNKS" split "${ROOT}/${f}" "$wd" 200 > /dev/null 2>&1 \
        || ! bash "$CHUNKS" join "$wd" "$wd.joined" > /dev/null 2>&1 \
        || ! cmp -s "${ROOT}/${f}" "$wd.joined"; then
        printf '  round trip broke: %s\n' "$f" >&2
        roundtrip=1
        continue
    fi
    for kind in frontmatter fences indented headings comments code quotes references links; do
        whole=$(bash "$SPANS" extract "$kind" "${ROOT}/${f}" | sort)
        parts=$(for c in "$wd"/orig/*.md; do bash "$SPANS" extract "$kind" "$c"; done | sort)
        if [ "$whole" != "$parts" ]; then
            printf '  %s spans do not add up: %s\n' "$kind" "$f" >&2
            compose=1
        fi
    done
done < <(git -C "$ROOT" ls-files -- '*.md')
[ "$files" -gt 0 ]; ok $? "the corpus sweep found tracked Markdown files (${files})"
ok "$roundtrip" 'every tracked Markdown file splits and joins back byte for byte'
ok "$compose" "every tracked Markdown file's chunk spans add up to its own"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
