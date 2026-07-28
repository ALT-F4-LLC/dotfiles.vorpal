#!/bin/bash
# Shared inline-PR-review-comment poster + voice-sampling helper for the
# review-and-comment skill (Step 5 voice sampling, Step 8 comment posting) —
# previously a hand-run recipe with quoting/subshell hazards (GH/JQ path
# capture, heredoc-quoted body, jq --arg escaping).
set -euo pipefail

usage() {
    cat >&2 <<'EOF'
Usage:
  gh_inline_comment.sh <owner/repo> <pr> <head_sha> <path> <line>
    Posts one inline PR review comment. Comment body is read from stdin.
    Prints "OK <path>:<line> -> <html_url>" on success.

  gh_inline_comment.sh --sample-voice <login> <owner/repo>
    Prints up to 15 of <login>'s past inline PR review comment bodies in
    <owner/repo>, followed by any PR/issue review comment bodies from their
    public events feed, to help calibrate comment voice before drafting.

  gh_inline_comment.sh --existing <owner/repo> <pr> <path> <line>
    Checks whether an inline review comment already exists at <path>:<line>
    on <pr> (matching outdated comments via original_line too). Exit 0 and
    prints "EXISTS <path>:<line> -> <html_url>" if one is found. Exit 1 and
    prints "NONE <path>:<line>" if the lookup succeeded and found none --
    safe to post. Exit 2 if the lookup itself failed (gh api/jq error, e.g.
    auth/network/rate-limit) -- existence could NOT be determined; callers
    MUST treat this distinctly from exit 1 and must not post on exit 2.
    Run this before each post to avoid duplicate comments.
EOF
    exit 1
}

GH=$(command -v gh) || { echo "gh_inline_comment.sh: gh not found" >&2; exit 1; }
JQ=$(command -v jq) || { echo "gh_inline_comment.sh: jq not found" >&2; exit 1; }

if [ "$#" -eq 0 ]; then
    usage
fi

if [ "$1" = "--sample-voice" ]; then
    if [ "$#" -ne 3 ]; then
        usage
    fi
    LOGIN="$2"
    REPO="$3"
    "$GH" api "repos/${REPO}/pulls/comments?per_page=100" \
        --jq "[.[]|select(.user.login==\"${LOGIN}\")][0:15]|.[].body"
    "$GH" api "users/${LOGIN}/events?per_page=100" \
        --jq '.[]|select(.type=="IssueCommentEvent" or .type=="PullRequestReviewCommentEvent")|.payload.comment.body // empty'
    exit 0
fi

if [ "$1" = "--existing" ]; then
    if [ "$#" -ne 5 ]; then
        usage
    fi
    REPO="$2"
    PR="$3"
    FILE_PATH="$4"
    LINE="$5"

    if ! [[ "$LINE" =~ ^[0-9]+$ ]]; then
        echo "gh_inline_comment.sh: <line> must be a positive integer, got '${LINE}'" >&2
        exit 1
    fi

    if ! COMMENTS_JSON=$("$GH" api --paginate "repos/${REPO}/pulls/${PR}/comments?per_page=100" 2>&1); then
        echo "gh_inline_comment.sh: could not list existing comments for ${REPO}#${PR} -- existence UNKNOWN, do not assume none exists:" >&2
        echo "$COMMENTS_JSON" >&2
        exit 2
    fi

    if ! MATCH=$("$JQ" -rs --arg p "$FILE_PATH" --argjson l "$LINE" \
            '[.[]|.[]|select(.path==$p and (.line==$l or .original_line==$l))][0].html_url // empty' \
            <<<"$COMMENTS_JSON"); then
        echo "gh_inline_comment.sh: could not parse existing-comments response for ${REPO}#${PR} -- existence UNKNOWN" >&2
        exit 2
    fi

    if [ -n "$MATCH" ]; then
        echo "EXISTS ${FILE_PATH}:${LINE} -> ${MATCH}"
        exit 0
    fi
    echo "NONE ${FILE_PATH}:${LINE}"
    exit 1
fi

if [ "$#" -ne 5 ]; then
    usage
fi

REPO="$1"
PR="$2"
COMMIT="$3"
FILE_PATH="$4"
LINE="$5"

if ! [[ "$LINE" =~ ^[0-9]+$ ]]; then
    echo "gh_inline_comment.sh: <line> must be a positive integer, got '${LINE}'" >&2
    exit 1
fi

BODY=$(cat)

"$JQ" -n --arg b "$BODY" --arg c "$COMMIT" --arg p "$FILE_PATH" --argjson l "$LINE" \
    '{body:$b,commit_id:$c,path:$p,line:$l,side:"RIGHT"}' \
    | "$GH" api -X POST "repos/${REPO}/pulls/${PR}/comments" --input - \
        --jq '"OK \(.path):\(.line) -> \(.html_url)"'
