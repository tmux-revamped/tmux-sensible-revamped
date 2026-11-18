# shellcheck shell=bash
# shellcheck disable=SC2207

_sensible_revamped() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  case "${prev}" in
  --theme)
    COMPREPLY=($(compgen -W "kodougu catppuccin-mocha catppuccin-latte dracula nord gruvbox tokyo-night mono" -- "${cur}"))
    return
    ;;
  --keys)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --last-window-key | --reload-key)
    return
    ;;
  *) ;;
  esac

  COMPREPLY=($(compgen -W "apply list resize-sync doctor version help --json --theme --keys --last-window-key --reload-key" -- "${cur}"))
}

complete -F _sensible_revamped sensible-revamped
