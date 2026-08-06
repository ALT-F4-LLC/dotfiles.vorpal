#!/bin/bash
# Emits {lock_sha256, cargo_audit_json} keyed to the current Cargo.lock hash,
# cached by that hash so a repeat call with an unchanged lockfile skips
# re-running `cargo audit`. Produces the shared pre-computed brief artifact
# team-lead.md Rule 8(c) and security-engineer.md's CVE-check step consume.
set -euo pipefail

usage() {
    echo "Usage: audit_snapshot.sh [--no-cache]" >&2
    echo "  Emits {lock_sha256, cargo_audit_json, cached_at} for the current" >&2
    echo "  Cargo.lock, cached by lock_sha256 in \$AUDIT_SNAPSHOT_CACHE_DIR" >&2
    echo "  (default: \${TMPDIR:-/tmp}/audit_snapshot)." >&2
    echo "  --no-cache forces a fresh 'cargo audit --json' run and refreshes the cache." >&2
    exit 1
}

NO_CACHE=0
case "${1:-}" in
    --no-cache) NO_CACHE=1 ;;
    "") ;;
    *) usage ;;
esac

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "audit_snapshot.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

[ -f "Cargo.lock" ] || {
    echo "audit_snapshot.sh: no Cargo.lock at repo root" >&2
    exit 1
}

if command -v sha256sum >/dev/null 2>&1; then
    LOCK_SHA256=$(sha256sum Cargo.lock | awk '{print $1}')
else
    LOCK_SHA256=$(shasum -a 256 Cargo.lock | awk '{print $1}')
fi

CACHE_DIR="${AUDIT_SNAPSHOT_CACHE_DIR:-${TMPDIR:-/tmp}/audit_snapshot}"
CACHE_FILE="${CACHE_DIR}/${LOCK_SHA256}.json"

if [ "$NO_CACHE" -eq 0 ] && [ -f "$CACHE_FILE" ]; then
    cat "$CACHE_FILE"
    exit 0
fi

if command -v cargo-audit >/dev/null 2>&1; then
    RAW_OUTPUT=$(cargo audit --json 2>/dev/null || true)
else
    RAW_OUTPUT=""
fi

if [ -n "$RAW_OUTPUT" ] && printf '%s' "$RAW_OUTPUT" | jq -e . >/dev/null 2>&1; then
    CARGO_AUDIT_JSON="$RAW_OUTPUT"
elif command -v cargo-audit >/dev/null 2>&1; then
    CARGO_AUDIT_JSON=$(jq -n --arg raw "$RAW_OUTPUT" \
        '{error: "cargo audit produced no parseable JSON", raw: $raw}')
else
    CARGO_AUDIT_JSON=$(jq -n \
        '{error: "cargo-audit not installed — install via `cargo install cargo-audit` or the project toolchain, then re-run"}')
fi

mkdir -p "$CACHE_DIR"
jq -n \
    --arg lockSha256 "$LOCK_SHA256" \
    --argjson cargoAuditJson "$CARGO_AUDIT_JSON" \
    --arg cachedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{lock_sha256: $lockSha256, cargo_audit_json: $cargoAuditJson, cached_at: $cachedAt}' \
    | tee "$CACHE_FILE"
