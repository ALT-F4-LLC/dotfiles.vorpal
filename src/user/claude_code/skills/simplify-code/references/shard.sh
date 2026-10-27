#!/usr/bin/env bash
# Split a repository's source files into disjoint shards for the simplify-code
# discovery round, highest priority first. Usage: shard.sh <repo> [lines per
# shard, default 4000] [pathspec...]. Prints a JSON array [{ name, files,
# lines }] on stdout.
#
# Shards pack files that sit together in the tree, so a scout reads one
# neighbourhood. Priority is churn per line over the last six months: cruft in
# a hotspot is read most. Every tracked file with a recognized source
# extension is in, repository-wide, and pathspecs only narrow that to the
# tracked files under them. Left out, for the reasons the discovery
# reference states: test files, which the frozen contracts forbid a worker to
# edit (the TEST pattern, the same set the workflow's exclusionReason uses);
# generated, vendored and lock files, which are not the repository's code (the
# GEN pattern). Needs git, awk, grep, xargs, and jq.
set -euo pipefail

repo=${1:?usage: shard.sh <repo> [lines per shard] [pathspec...]}
target=${2:-4000}
shift $(( $# >= 2 ? 2 : $# ))
cd "$repo"

EXT='go|rs|py|pyi|js|jsx|mjs|cjs|ts|tsx|mts|cts|vue|svelte|rb|java|kt|kts|groovy|scala|cs|php|c|cc|cxx|cpp|h|hh|hpp|m|mm|swift|dart|sh|bash|ex|exs|erl|hs|ml|clj|pl|lua|zig'
TEST='(^|/)(tests?|__tests__|spec|specs|testdata|fixtures|__snapshots__)/|\.(test|spec)\.[^/]+$|_(test|spec)\.[^/]+$|(^|/)test_[^/]+\.py$|(^|/)conftest\.py$'
GEN='(^|/)(node_modules|vendor|target|dist|build|\.git)/|(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock|go\.sum|poetry\.lock|Gemfile\.lock|uv\.lock)$|\.min\.(js|css)$|\.generated\.'

work=$(mktemp -d "${TMPDIR:-/tmp}/simplify-shard.XXXXXX")
trap 'rm -rf "$work"' EXIT

git ls-files -z -- "$@" | tr '\0' '\n' | grep -E "\.(${EXT})\$" | grep -Ev "$TEST" | grep -Ev "$GEN" | sort > "$work/files" || true
[ -s "$work/files" ] || { echo '[]'; exit 0; }

tr '\n' '\0' < "$work/files" | xargs -0 wc -l | grep -v ' total$' | awk '{ n = $1; $1 = ""; sub(/^ /, ""); print n "\t" $0 }' > "$work/lines"
{ git log --since=6.months --name-only --pretty=format: | grep -v "^$" || true; } | sort | uniq -c | awk '{ n = $1; $1 = ""; sub(/^ /, ""); print n "\t" $0 }' > "$work/churn"

awk -F'\t' -v target="$target" '
    FILENAME == ARGV[1] { churn[$2] = $1; next }
    {
        n = $1; path = $2
        if (cur > 0 && cur + n > target) { idx++; cur = 0 }
        cur += n
        printf "%06d\t%s\t%d\t%d\n", idx, path, n, churn[path] + 0
    }
' "$work/churn" "$work/lines" | jq -R -s '
    split("\n") | map(select(length > 0) | split("\t"))
    | group_by(.[0])
    | map({ files: map(.[1]), lines: (map(.[2] | tonumber) | add), churn: (map(.[3] | tonumber) | add) })
    | map(. + { density: (.churn / (if .lines < 1 then 1 else .lines end)) })
    | sort_by(-.density)
    | to_entries
    | map(.value + { name: ("shard-" + ((.key + 1) | tostring) + ":" + (.value.files[0] | split("/")[0:2] | join("/"))) })
    | map({ name, files, lines })
'
