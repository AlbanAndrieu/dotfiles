# macOS Terminal: disable per-tab history files (~/.zsh_sessions) so that
# ~/.zsh_history is shared across tabs (see SHARE_HISTORY in ~/.zshrc)
export SHELL_SESSION_HISTORY=0

# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/alban.andrieu/.docker/bin"
# End of Docker Desktop section.

eval "$(/opt/homebrew/bin/brew shellenv zsh)"
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
eval "$(mise activate zsh)"

# export NODE_OPTIONS=--no-webstorage
