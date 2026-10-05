#!/bin/bash

# Build hook-probe shims: symlinks to the real executables a hook needs, so a
# probe can run the hook under a PATH of only those tools.
#
# `command -v`, with or without -p, reports an alias definition when the shell
# has one, and the agent's zsh carries the operator's `alias -- cat=bat`. A
# shim built from that output links to alias text. `type -P` searches PATH
# for an executable file and ignores aliases, functions, and builtins.
#
# From bash:  . tests/lib/hook-probe.sh; hook_probe_link_shims DIR TOOL...
# From zsh:   bash tests/lib/hook-probe.sh DIR TOOL...

hook_probe_link_shims() {
    local dir="$1" tool tool_path
    shift
    mkdir -p "$dir" || return 1
    for tool in "$@"; do
        tool_path=$(type -P "$tool") || {
            printf 'hook-probe: %s not found on PATH\n' "$tool" >&2
            return 1
        }
        ln -s "$tool_path" "${dir}/${tool}" || return 1
    done
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    [ "$#" -ge 2 ] || {
        printf 'usage: %s DIR TOOL...\n' "$0" >&2
        exit 64
    }
    hook_probe_link_shims "$@"
fi
