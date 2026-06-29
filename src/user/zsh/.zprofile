# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Added by Cargo
source "$HOME/.cargo/env"

# Added by Vorpal: installation and user environment
export PATH="$HOME/.vorpal/bin:$PATH"
source ${HOME}/.vorpal/bin/vorpal-activate-shell
