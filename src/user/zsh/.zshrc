# START MIGRATION: Needs to be moved to Vorpal

# Zsh saves no history unless HISTFILE is set
export HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
export HISTSIZE=100000
# Maximum lines saved to $HISTFILE
export SAVEHIST=100000
# Like INC_APPEND_HISTORY + re-read history whenever accessing it
setopt SHARE_HISTORY

# Claude Code agent shell. The Bash tool runs commands in this zsh, where an
# unmatched glob is a hard error: an unquoted `grep -rn X --include=*.go .`
# fails with "no matches found" and never runs, and agents that do not notice
# cite a search that did not happen. With NO_NOMATCH the pattern passes through
# literally, as bash does. Claude Code sets CLAUDECODE in the processes it
# starts, including the shell it snapshots this file from, so the operator's
# own terminal keeps the default. A program that expands a glob itself now
# receives it (`git add *.go` reaches subdirectories), as it does in bash.
# The markers below are read by tests/zsh-agent-nomatch.test.sh.
# BEGIN agent-shell-options
if [[ -n ${CLAUDECODE-} ]]; then
  setopt NO_NOMATCH
fi
# END agent-shell-options

## Claude Code
c () {
  emulate -L zsh

  # Scope = <repo>/<worktree> if inside a .git worktree path, else the current dir
  local dir="$PWD" scope
  if [[ "$dir" == *.git/* ]]; then
    local repo="${dir%%.git/*}"; repo="${repo:t}"
    local worktree="${dir#*.git/}"
    scope="$repo/$worktree"
  else
    scope="${dir:t}"
  fi

  # Name (required)
  local name
  while true; do
    name=$(gum input --prompt "session name: " --placeholder "e.g. workshop-docs") || return 1
    [[ -n "$name" ]] && break
    gum style --foreground 1 "A name is required."
  done

  # Task prompt (optional)
  local task
  task=$(gum write --placeholder "Optional task for Claude - Ctrl+D to dispatch, Esc to skip") || task=""

  local session="$scope#$name"
  local -a args=(--bg --name "$session")

  if [[ -n "$task" ]]; then
    claude "${args[@]}" "$task"
  else
    claude "${args[@]}"
  fi
}

## Kind
kindc () {
  cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
- role: worker
- role: worker
EOF
}

## Navigation
n () {
  if [ -n $NNNLVL ] && [ "$NNNLVL" -ge 1 ]; then
    echo "nnn is already running"
    return
  fi

  export NNN_TMPFILE="$HOME/.config/nnn/.lastd"

  nnn -adeHo "$@"

  if [ -f "$NNN_TMPFILE" ]; then
    . "$NNN_TMPFILE"
    rm -f "$NNN_TMPFILE" > /dev/null
  fi
}

## Lazygit
function lg() {
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
    command lazygit "$@"
    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
      cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
      rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}

## Aliases
alias -- cat=bat
alias -- dk=docket
alias -- lg=lazygit
alias -- ll=n
alias -- s='doppler run --config "mac17-7" --project "$(whoami)"'
alias -- wt='git worktree'

## Direnv
eval "$(direnv hook zsh)"

## Starship
eval "$(starship init zsh)"

## Completion
# Interactive shells only; the shells that source this file without a prompt
# have no use for a completion system. This must stay above `zoxide init`,
# which registers the `z` completion only when `compdef` already exists.
if [[ -o interactive ]]; then
  # Plugin symlinks, one per plugin, each pointing at its Vorpal store path
  # (src/user/zsh.rs). ZSH_PLUGIN_ROOT overrides the directory.
  ZSH_PLUGIN_ROOT=${ZSH_PLUGIN_ROOT:-${HOME}/.config}
  _zsh_cache=${XDG_CACHE_HOME:-${HOME}/.cache}/zsh
  _zsh_comp_dir=${_zsh_cache}/completions
  mkdir -p ${_zsh_comp_dir}

  # Writes the completion script a tool generates itself to
  # ${_zsh_comp_dir}/_<tool>. A tool whose script is current is not run: the
  # script is current while the tool resolves to the same path (a new store
  # path after an upgrade changes it) and the binary is not newer than the
  # script (an in-place upgrade outside the store). The path sits in a dot
  # file because compinit reads every `_*` file in fpath. A tool that is
  # absent, fails, or prints something other than a `#compdef` script leaves
  # any earlier script alone, and is tried again at the next shell start.
  _zsh_comp_gen () {
    emulate -L zsh
    local tool=$1; shift
    local bin=${commands[$tool]}
    local file=${_zsh_comp_dir}/_${tool} stamp=${_zsh_comp_dir}/.src-${tool}
    [[ -n $bin ]] || return 0
    if [[ -s $file && -f $stamp && "$(<$stamp)" == "$bin" && ! $bin -nt $file ]]; then
      return 0
    fi
    local out
    out=$("$bin" "$@" 2>/dev/null) || return 0
    [[ $out == '#compdef'* ]] || return 0
    print -r -- "$out" >| $file && print -r -- "$bin" >| $stamp
  }

  _zsh_comp_gen kubectl completion zsh
  _zsh_comp_gen gh completion -s zsh
  _zsh_comp_gen just --completions zsh
  _zsh_comp_gen starship completions zsh
  _zsh_comp_gen uv generate-shell-completion zsh
  _zsh_comp_gen k9s completion zsh
  _zsh_comp_gen rg --generate complete-zsh
  _zsh_comp_gen fd --gen-completions zsh
  _zsh_comp_gen docket completion zsh
  _zsh_comp_gen delta --generate-completion zsh
  _zsh_comp_gen bat --completion zsh
  _zsh_comp_gen gum completion zsh
  _zsh_comp_gen jj util completion zsh
  _zsh_comp_gen yq completion zsh
  _zsh_comp_gen sesh completion zsh
  _zsh_comp_gen gitleaks completion zsh
  _zsh_comp_gen rumdl completions zsh
  _zsh_comp_gen op completion zsh
  _zsh_comp_gen doppler completion zsh

  # fpath must be complete before compinit reads it.
  fpath=(${_zsh_comp_dir} $fpath)
  # zsh-completions is a plugin, so the Claude Code agent shell skips it too.
  [[ -z ${CLAUDECODE-} ]] && fpath=(${ZSH_PLUGIN_ROOT}/zsh-completions/src $fpath)
  autoload -Uz compinit
  compinit -d ${_zsh_cache}/zcompdump-${ZSH_VERSION}

  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
fi

## Zoxide
eval "$(zoxide init zsh)"

## Key bindings
# Vi mode keeps Esc for normal mode. Insert mode gets the emacs-style
# defaults back, since vi mode drops most of them.
bindkey -v
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^B' backward-char
bindkey -M viins '^D' delete-char-or-list
bindkey -M viins '^E' end-of-line
bindkey -M viins '^F' forward-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^K' kill-line
bindkey -M viins '^N' down-line-or-history
bindkey -M viins '^P' up-line-or-history
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M viins '^T' transpose-chars
bindkey -M viins '^U' kill-whole-line
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^Y' yank
bindkey -M viins '^_' undo
bindkey -M viins '^[b' backward-word
bindkey -M viins '^[d' kill-word
bindkey -M viins '^[f' forward-word
bindkey -M viins '^[.' insert-last-word

## Plugins
# Sourced from store paths through the symlinks in ZSH_PLUGIN_ROOT, never
# fetched at shell start. After compinit (Completion, above) and after the
# key bindings, so fzf-tab and autosuggestions bind into the vi-mode keymap.
# Order matters: fzf-tab first, autosuggestions last, because autosuggestions
# wraps the widgets the others bind. The Claude Code agent shell loads none.
if [[ -o interactive && -z ${CLAUDECODE-} ]]; then
  [[ -r ${ZSH_PLUGIN_ROOT}/fzf-tab/fzf-tab.plugin.zsh ]] \
    && source ${ZSH_PLUGIN_ROOT}/fzf-tab/fzf-tab.plugin.zsh
  [[ -r ${ZSH_PLUGIN_ROOT}/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
    && source ${ZSH_PLUGIN_ROOT}/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# END MIGRATION: Needs to be moved to Vorpal

# Added by LM Studio CLI (lms)
export PATH="$PATH:${HOME}/.lmstudio/bin"
# End of LM Studio CLI section


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Added by Devin
export PATH="${HOME}/.codeium/windsurf/bin:$PATH"
