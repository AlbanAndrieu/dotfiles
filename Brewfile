# Shared Brewfile for macOS and Ubuntu (Linuxbrew): brew bundle --file=~/Brewfile
# "homebrew/bundle" tap is no longer needed: bundle is built into brew

# Taps
tap "avisi-cloud/tools", trusted: true
tap "michaeldfallen/formula"

# Security / secrets
# GNU Privacy Guard (OpenPGP)
brew "gnupg"
brew "gitleaks"
brew "gitguardian/tap/ggshield"
brew "terrascan"

# Cloud / IaC
brew "azure-cli"
brew "awscli"
# Pretty-print terraform plan output
brew "terraform_landscape"

# Dev tooling
# Polyglot runtime manager (asdf rust clone)
brew "mise"
brew "tfenv"
brew "dive"
brew "fzf"
brew "hadolint"
brew "github-markdown-toc"
brew "randomize-lines"
#brew "navi"
brew "michaeldfallen/formula/git-radar"
# Syntax-highlighting pager for git, diff and grep output (core.pager in ~/.gitconfig)
brew "git-delta"
# Static site generator for architecture models created with Structrizr DSL
brew "avisi-cloud/tools/structurizr-site-generatr"

# Libraries
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
end

if OS.linux?
  tap "linuxbrew/xorg"
  # On Ubuntu meld comes from apt: sudo apt install meld
end
