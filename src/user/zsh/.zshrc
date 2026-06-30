# START MIGRATION: Needs to be moved to Vorpal

export HISTSIZE=100000
# Maximum lines saved to $HISTFILE
export SAVEHIST=100000
# Like INC_APPEND_HISTORY + re-read history whenever accessing it
setopt SHARE_HISTORY

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
alias -- s='doppler run --config "nixos" --project "$(whoami)"'
alias -- wt='git worktree'

## Direnv
eval "$(direnv hook zsh)"

## Starship
eval "$(starship init zsh)"

## Zoxide
eval "$(zoxide init zsh)"

## History search
bindkey -v
bindkey '^R' history-incremental-search-backward

# END MIGRATION: Needs to be moved to Vorpal

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/erikreinert/.lmstudio/bin"
# End of LM Studio CLI section

