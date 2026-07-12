#!/bin/bash
# Design-QA render verification per ux-designer.md:236-242 "Render mechanism by
# surface class". Three arms, dispatched by the first argument:
#   html — headless-browser screenshot -> PNG (Static-export/HTML/slide surfaces)
#   tui  — captured terminal output via a pty (TUI surfaces)
#   cli  — captured stdout/stderr from the real invocation (CLI surfaces)
#
# The html arm is RUNTIME-DETECTED, not a hard dependency: it probes for an
# already-installed browser binary (on PATH or the standard macOS app bundle
# paths) and shells out to it with --headless=new --screenshot. No new
# dependency is added by this script. If no browser is found, the arm prints
# a distinct SKIPPED message and exits 2 (arm-unavailable, not a hard
# failure) rather than adding playwright/puppeteer or any other dependency —
# that decision is out of scope for this script (advisor + team-lead
# consult, DKT-187: a new render-automation dependency is a supply-chain
# decision, never added silently here).
#
# The tui arm uses the `script` utility (BSD script(1) on macOS) to capture
# a pty session, since many TUIs detect a non-tty stdout and silently drop
# color/rendering. Note: pty allocation (openpty) is a privileged syscall
# some restricted/containerized execution environments deny; a failure
# there is an environment property of the caller's shell, not a defect in
# this script.
set -uo pipefail

usage() {
    echo "Usage:" >&2
    echo "  render_verify.sh html <url-or-file> [output.png] [width] [height]" >&2
    echo "  render_verify.sh tui  <command-string> [output.txt]" >&2
    echo "  render_verify.sh cli  <command-string> [output.txt]" >&2
    exit 1
}

if [ "$#" -lt 2 ]; then
    usage
fi

ARM="$1"
shift

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "render_verify.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

find_browser() {
    local candidates=(
        chrome-headless-shell
        chromium
        chromium-browser
        google-chrome
        google-chrome-stable
    )
    for c in "${candidates[@]}"; do
        if command -v "$c" >/dev/null 2>&1; then
            command -v "$c"
            return 0
        fi
    done
    local bundles=(
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        "/Applications/Chromium.app/Contents/MacOS/Chromium"
    )
    for b in "${bundles[@]}"; do
        if [ -x "$b" ]; then
            printf '%s' "$b"
            return 0
        fi
    done
    return 1
}

case "$ARM" in
    html)
        TARGET="${1:-}"
        [ -z "$TARGET" ] && usage
        OUTPUT="${2:-${TMPDIR:-/tmp}/render_verify_$(date +%s).png}"
        WIDTH="${3:-1280}"
        HEIGHT="${4:-800}"

        if ! BROWSER=$(find_browser); then
            echo "SKIPPED: no headless browser found on PATH or in /Applications — html arm unavailable, no new dependency added" >&2
            exit 2
        fi

        echo "Using browser: ${BROWSER}"
        "$BROWSER" --headless=new --disable-gpu \
            --screenshot="$OUTPUT" \
            --window-size="${WIDTH},${HEIGHT}" \
            "$TARGET"
        STATUS=$?
        if [ "$STATUS" -ne 0 ] || [ ! -s "$OUTPUT" ]; then
            echo "render_verify.sh: browser screenshot failed (exit ${STATUS}) or produced an empty file: ${OUTPUT}" >&2
            exit 1
        fi
        echo "OK: screenshot written to ${OUTPUT}"
        ;;

    tui)
        CMD="${1:-}"
        [ -z "$CMD" ] && usage
        OUTPUT="${2:-${TMPDIR:-/tmp}/render_verify_$(date +%s).txt}"

        script -q "$OUTPUT" bash -c "$CMD"
        STATUS=$?
        echo "OK: captured pty session (command exit ${STATUS}) to ${OUTPUT}"
        cat "$OUTPUT"
        ;;

    cli)
        CMD="${1:-}"
        [ -z "$CMD" ] && usage
        OUTPUT="${2:-${TMPDIR:-/tmp}/render_verify_$(date +%s).txt}"

        bash -c "$CMD" 2>&1 | tee "$OUTPUT"
        STATUS="${PIPESTATUS[0]}"
        echo "OK: captured stdout/stderr (command exit ${STATUS}) to ${OUTPUT}"
        ;;

    *)
        usage
        ;;
esac
