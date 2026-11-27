# Docker Desktop CLI tools (absent when Docker Desktop is not installed)
[ -d "$HOME/.docker/bin" ] && export PATH="$PATH:$HOME/.docker/bin"

# macOS Terminal: disable per-tab history files (~/.zsh_sessions) so that
# ~/.zsh_history is shared across tabs (see SHARE_HISTORY in ~/.zshrc)
export SHELL_SESSION_HISTORY=0


eval "$(/opt/homebrew/bin/brew shellenv zsh)"
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
eval "$(mise activate zsh)"

# export NODE_OPTIONS=--no-webstorage
