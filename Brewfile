toolset = ENV.fetch("HOMEBREW_REVAMPED_TOOLSET", "all")

brew "bats-core"
brew "bash"
brew "dash-shell"
brew "zsh"
brew "tmux"

if %w[all homebrew].include?(toolset)
  brew "coreutils"
  brew "findutils"
  brew "gnu-sed"
  brew "gawk"
  brew "grep"
  brew "diffutils", link: false
end

if %w[all uutils].include?(toolset)
  brew "uutils-coreutils"
  brew "uutils-diffutils"
  brew "uutils-findutils"
end

unless ENV.key?("CI")
  brew "shfmt"
  brew "shellcheck"
  brew "yamllint"
  brew "actionlint"
  brew "gum"
  brew "vhs"
  brew "imagemagick"
end
