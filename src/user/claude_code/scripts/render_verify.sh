#!/bin/bash
# Design-QA render verification per ux-designer.md:236-242 "Render mechanism by
# surface class". Four arms, dispatched by the first argument:
#   html    — headless-browser screenshot -> PNG (Static-export/HTML/slide surfaces)
#   tui     — captured terminal output via a pty (TUI surfaces)
#   cli     — captured stdout/stderr from the real invocation (CLI surfaces)
#   tui-go  — scratch-Go-module build+run for deterministic Go TUI/CLI
#             internal-package render QA
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
#
# The tui-go arm exists because Go's internal-package visibility is
# structural (import-path enforced), so a target repo's internal/... TUI
# styling/sanitize logic can never be imported from an external script,
# and writing a temporary _test.go inside the target repo's internal
# package would cross the read-only verification boundary this script is
# meant to preserve. Instead, tui-go builds and runs an already-authored
# throwaway Go module (its own go.mod, given as <module-dir>) that
# externally reproduces the pure rendering logic under test, resolving its
# pinned dependencies offline (GOPROXY=off) against the ambient GOMODCACHE
# so zero network is needed once that cache already holds the target
# repo's exact dependency versions. This script only handles offline
# dependency resolution and build+capture; forcing deterministic non-TTY
# output (e.g. lipgloss.SetColorProfile(termenv.Ascii) or
# termenv.TrueColor) is the module source's own responsibility, since only
# the module knows which color profile it needs to force to exercise a
# given render path.
set -uo pipefail

usage() {
    echo "Usage:" >&2
    echo "  render_verify.sh html   <url-or-file> [output.png] [width] [height]" >&2
    echo "  render_verify.sh tui    <command-string> [output.txt]" >&2
    echo "  render_verify.sh cli    <command-string> [output.txt]" >&2
    echo "  render_verify.sh tui-go <module-dir> [output.txt]" >&2
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

    tui-go)
        MODDIR="${1:-}"
        [ -z "$MODDIR" ] && usage
        [ -d "$MODDIR" ] || {
            echo "render_verify.sh: tui-go module directory not found: ${MODDIR}" >&2
            exit 1
        }
        [ -f "$MODDIR/go.mod" ] || {
            echo "render_verify.sh: tui-go module directory has no go.mod: ${MODDIR}" >&2
            exit 1
        }
        MODDIR=$(cd "$MODDIR" && pwd)
        OUTPUT="${2:-${TMPDIR:-/tmp}/render_verify_$(date +%s).txt}"
        GO_VERSION="${RENDER_VERIFY_GO_VERSION:-1.26.0}"

        if command -v go >/dev/null 2>&1; then
            GO_BIN=$(command -v go)
        elif command -v vorpal >/dev/null 2>&1; then
            GOROOT=$(vorpal run "go:${GO_VERSION}" env GOROOT) || {
                echo "SKIPPED: failed to resolve go toolchain via 'vorpal run go:${GO_VERSION} env GOROOT' — tui-go arm unavailable, no new dependency added" >&2
                exit 2
            }
            GO_BIN="${GOROOT}/bin/go"
        else
            echo "SKIPPED: no go toolchain found (native 'go' or 'vorpal') — tui-go arm unavailable, no new dependency added" >&2
            exit 2
        fi

        GOMODCACHE=$("$GO_BIN" env GOMODCACHE)
        echo "Using go: ${GO_BIN} (GOMODCACHE: ${GOMODCACHE})"

        BIN="${MODDIR}/.render_verify_tui_go_bin"
        (
            cd "$MODDIR" && \
            GOFLAGS=-mod=mod GOPROXY=off GOMODCACHE="$GOMODCACHE" "$GO_BIN" mod tidy && \
            GOFLAGS=-mod=mod GOPROXY=off GOMODCACHE="$GOMODCACHE" "$GO_BIN" build -o "$BIN" .
        )
        STATUS=$?
        if [ "$STATUS" -ne 0 ]; then
            echo "render_verify.sh: tui-go module build failed offline (exit ${STATUS}) — this recipe requires the module's pinned dependency versions to already be present in GOMODCACHE; warm the cache once with 'GOPROXY=direct GOSUMDB=off go mod tidy' in the module dir, then rerun" >&2
            exit 1
        fi

        "$BIN" >"$OUTPUT" 2>&1
        STATUS=$?
        rm -f "$BIN"
        echo "OK: built and ran scratch Go module offline (exit ${STATUS}) to ${OUTPUT}"
        cat "$OUTPUT"
        ;;

    *)
        usage
        ;;
esac
