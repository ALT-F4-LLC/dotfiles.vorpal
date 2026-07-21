#!/bin/bash
# Setup helper for the review-and-comment skill (Steps 1-2): resolves gh/jq to
# absolute paths, prints the acting identity, fetches PR metadata + head_sha +
# diff, and shallow-clones the PR head — codifying three hand-execution
# footguns: gh/jq not resolving inside shell-function subshells, the mandatory
# sandbox-disable for GitHub network calls, and $TMPDIR being remapped by the
# sandbox across calls (this script prints literal resolved absolute paths).
set -euo pipefail

usage() {
    cat >&2 <<'EOF'
Usage: rc_pr_setup.sh <owner/repo> <pr>
  Fetches PR metadata, head_sha, and diff; shallow-clones the PR head branch.
  Must be run with dangerouslyDisableSandbox: true (GitHub network calls fail
  under the sandbox proxy with TLS/x509 errors otherwise).

  Prints (one line each): IDENTITY, METADATA_JSON, HEAD_SHA, PR_JSON,
  DIFF_FILE, CLONE_DIR. Reuse the printed DIFF_FILE/CLONE_DIR absolute paths
  verbatim in later steps — do not reconstruct them from $TMPDIR, which the
  sandbox remaps between calls.
EOF
    exit 1
}

if [ "$#" -ne 2 ]; then
    usage
fi

REPO="$1"
PR="$2"

if ! [[ "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
    echo "rc_pr_setup.sh: <owner/repo> must be OWNER/REPO, got '${REPO}'" >&2
    exit 1
fi
if ! [[ "$PR" =~ ^[0-9]+$ ]]; then
    echo "rc_pr_setup.sh: <pr> must be a positive integer, got '${PR}'" >&2
    exit 1
fi

GH=$(command -v gh) || { echo "rc_pr_setup.sh: gh not found on PATH" >&2; exit 1; }
JQ=$(command -v jq) || { echo "rc_pr_setup.sh: jq not found on PATH" >&2; exit 1; }

# Runs a gh/git network call, capturing stdout for the caller while turning
# the sandbox's TLS/x509 failure signature into an actionable message instead
# of a cryptic curl error.
gh_call() {
    local errfile out status
    errfile=$(mktemp "${TMPDIR:-/tmp}/rc-pr-setup-err.XXXXXX")
    status=0
    out=$("$@" 2>"$errfile") || status=$?
    if [ "$status" -ne 0 ]; then
        if grep -qiE 'x509|certificate|SSL|TLS' "$errfile"; then
            echo "rc_pr_setup.sh: GitHub network call failed with a TLS/certificate error." >&2
            echo "This sandbox blocks gh/git network calls by default." >&2
            echo "Re-run this script with dangerouslyDisableSandbox: true." >&2
        else
            cat "$errfile" >&2
        fi
        rm -f "$errfile"
        exit "$status"
    fi
    rm -f "$errfile"
    printf '%s' "$out"
}

LOGIN=$(gh_call "$GH" api user --jq .login)
echo "IDENTITY: ${LOGIN}"

METADATA_JSON=$(gh_call "$GH" pr view "$PR" --repo "$REPO" \
    --json title,author,baseRefName,headRefName,additions,deletions,changedFiles,files,url)
echo "METADATA_JSON: ${METADATA_JSON}"

PR_JSON=$(gh_call "$GH" api "repos/${REPO}/pulls/${PR}" --jq '{head_sha:.head.sha, commits:.commits}')
HEAD_SHA=$(echo "$PR_JSON" | "$JQ" -r '.head_sha')
echo "PR_JSON: ${PR_JSON}"
echo "HEAD_SHA: ${HEAD_SHA}"

HEAD_REF=$(echo "$METADATA_JSON" | "$JQ" -r '.headRefName')

DIFF_FILE="${TMPDIR:-/tmp}/rc-pr${PR}.diff"
gh_call "$GH" pr diff "$PR" --repo "$REPO" > "$DIFF_FILE"
DIFF_FILE=$(cd "$(dirname "$DIFF_FILE")" && pwd -P)/$(basename "$DIFF_FILE")
echo "DIFF_FILE: ${DIFF_FILE} ($(wc -l < "$DIFF_FILE" | tr -d ' ') lines)"

CLONE_DIR="${TMPDIR:-/tmp}/rc-pr${PR}"
rm -rf "$CLONE_DIR"
gh_call "$GH" repo clone "$REPO" "$CLONE_DIR" -- --depth 1 --branch "$HEAD_REF" >/dev/null
CLONE_DIR=$(cd "$CLONE_DIR" && pwd -P)
echo "CLONE_DIR: ${CLONE_DIR}"
