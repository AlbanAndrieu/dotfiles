grep -qxF '[[ -f ~/.aliases ]] && source ~/.aliases' ~/.zshrc || \
  echo '[[ -f ~/.aliases ]] && source ~/.aliases' >> ~/.zshrc

export PATH="$HOME/.local/bin:$PATH"

# Completions for CLI tools (mostly installed by mise), cached as zsh
# functions in ~/.cache/zsh/completions and regenerated when the tool is
# newer than its cache. Must run before compinit (fpath).
() {
  local dir=$HOME/.cache/zsh/completions spec name f
  mkdir -p $dir
  fpath=($dir $fpath)
  for spec in \
    'kubectl:kubectl completion zsh' 'helm:helm completion zsh' \
    'k9s:k9s completion zsh' 'kind:kind completion zsh' \
    'kustomize:kustomize completion zsh' 'popeye:popeye completion zsh' \
    'gh:gh completion -s zsh' 'glab:glab completion -s zsh' \
    'mise:mise completion zsh' 'just:just --completions zsh' \
    'starship:starship completions zsh' 'uv:uv generate-shell-completion zsh' \
    'rg:rg --generate complete-zsh' 'bat:bat --completion zsh' \
    'delta:delta --generate-completion zsh' 'poetry:poetry completions zsh' \
    'dagger:dagger completion zsh' 'act:act completion zsh' \
    'gitleaks:gitleaks completion zsh' 'opencode:opencode completion'; do
    name=${spec%%:*}; f=$dir/_$name
    (( $+commands[$name] )) || continue
    if [[ ! -s $f || $commands[$name] -nt $f ]]; then
      eval "${spec#*:}" >| $f 2>/dev/null && [[ $(head -c 8 $f) == '#compdef' ]] || rm -f $f
    fi
  done
}

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/alban.andrieu/.docker/completions $fpath)
autoload -Uz compinit
(( ${+_comps[docker]} )) || compinit
# End of Docker CLI completions
# Oh My Zsh: plugins only, no theme (the prompt is starship, see end of file).
# Loaded before ~/.aliases and the history settings below so that they win.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
zstyle ':omz:update' mode reminder
# zsh-syntax-highlighting must stay the last plugin
plugins=(git docker kubectl zsh-autosuggestions zsh-syntax-highlighting)
[[ -r $ZSH/oh-my-zsh.sh ]] && source "$ZSH/oh-my-zsh.sh"

# Nabla dev environment (PROJECT_*, PATH, completions); before ~/.aliases,
# whose cde/cdc aliases use PROJECT_DEV
[[ -r ~/github/nabla/env/home/dev.env.zsh ]] && source ~/github/nabla/env/home/dev.env.zsh
[[ -f ~/.aliases ]] && source ~/.aliases
export GPG_TTY=$(tty)

# History (zsh does not read ~/.inputrc, which is for bash/readline)
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_VERIFY

# Up/Down: browse history entries starting with what is already typed
# (zsh equivalent of readline history-search-backward/forward)
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

# Case-insensitive completion (readline completion-ignore-case)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# k = kubectl, with completion (k get pods <TAB>)
alias k=kubectl
compdef k=kubectl 2>/dev/null

# Bash-style completions (terraform, terragrunt, aws, az)
autoload -U +X bashcompinit && bashcompinit
(( $+commands[terraform] ))     && complete -o nospace -C terraform terraform
(( $+commands[terragrunt] ))    && complete -o nospace -C terragrunt terragrunt
(( $+commands[aws_completer] )) && complete -C aws_completer aws
if (( $+commands[az] )); then
  # register-python-argcomplete ships in az's own venv
  _az_reg=${commands[az]:A:h}/register-python-argcomplete
  [[ -x $_az_reg ]] && eval "$($_az_reg az 2>/dev/null)"
  unset _az_reg
fi

# Starship prompt (installed by mise, config: ~/.config/starship.toml)
# Needs a Nerd Font in the terminal, e.g. "FiraCode Nerd Font Mono"
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
