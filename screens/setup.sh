export PS1='$ '
export PATH="${SCREENS_REPO:?}/bin:${PATH}"
unset KODOUGU_THEME KODOUGU_ACCENT SENSIBLE_REVAMPED_THEME SENSIBLE_REVAMPED_ACCENT NO_COLOR
export HOME=/Users/Shared/demo/home
export EDITOR=vim
cd /Users/Shared/demo || return 1
printf '\033]2;demo\033\134'
clear
