# Shared Brewfile for macOS and Ubuntu (Linuxbrew): brew bundle --file=~/Brewfile
# CLI tools are managed by mise (~/.config/mise/config.toml, ~/.tool-versions) whenever
# they exist in the mise registry; keep here only what mise cannot provide
# (libraries, casks, GPG, custom taps).
# "homebrew/bundle" tap is no longer needed: bundle is built into brew

# Taps
tap "avisi-cloud/tools", trusted: true
tap "michaeldfallen/formula"

# Security / secrets
# GNU Privacy Guard (OpenPGP)
brew "gnupg"

# Cloud / IaC (azure-cli, awscli, terraform are managed by mise)
# Pretty-print terraform plan output
brew "terraform_landscape"

# Dev tooling
# Polyglot runtime manager (asdf rust clone)
brew "mise"
brew "randomize-lines"
#brew "navi"
brew "michaeldfallen/formula/git-radar"
# Static site generator for architecture models created with Structrizr DSL
brew "avisi-cloud/tools/structurizr-site-generatr"

# Fonts (macOS: ~/Library/Fonts, Linux: ~/.local/share/fonts)
# FiraCode Nerd Font: icons for the starship prompt
cask "font-fira-code-nerd-font"

# Libraries
# Linked by Python builds from mise (ssl, decimal, readline, lzma, zstd, gettext):
# keep them declared so "brew autoremove" never deletes them
brew "openssl@3"
brew "mpdecimal"
brew "readline"
brew "xz"
brew "zstd"
brew "gettext"
brew "sqlite"
# sudo apt install uuid-dev
brew "cairo"
brew "libxml2"
brew "libpq"

if OS.mac?
  # Pinentry for GPG on Mac
  brew "pinentry-mac"
  # App to build and share containerised applications and microservices
  cask "docker-desktop"
  # Rust-based terminal
  cask "warp"
  # Agentic development environment for command-line workflows
  cask "warp-agent-cli"
  # Visual diff and merge tool (diff.tool / merge.tool in ~/.gitconfig)
  cask "meld"
  # Lightweight IDE (on Ubuntu: sudo apt install geany)
  cask "geany"
end

if OS.linux?
  tap "linuxbrew/xorg"
  # On Ubuntu meld comes from apt: sudo apt install meld
end
# Bourne-Again SHell, a UNIX command interpreter
brew "bash"
# Go-based command-line wrapper for easy interaction with Datadog APIs
brew "datadog-labs/pack/pup"
