grep -qxF '[[ -f ~/.aliases ]] && source ~/.aliases' ~/.zshrc || \
  echo '[[ -f ~/.aliases ]] && source ~/.aliases' >> ~/.zshrc

export PATH="$HOME/.local/bin:$PATH"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/alban.andrieu/.docker/completions $fpath)
autoload -Uz compinit
(( ${+_comps[docker]} )) || compinit
# End of Docker CLI completions
[[ -f ~/.aliases ]] && source ~/.aliases
export GPG_TTY=$(tty)
export GPG_TTY=$(tty)
