#!/usr/bin/env bash

[[ -n "${_SENSIBLE_REVAMPED_LOADED:-}" ]] && return 0
_SENSIBLE_REVAMPED_LOADED=1

parse_tmux_version() {
  printf '%s\n' "${1}" | sed -En 's/^tmux[ -]([a-z]+-)?([0-9]+\.[0-9]+).*/\2/p'
}

version_ge() {
  local have_major have_minor want_major want_minor
  have_major="$(_version_part "${1}" major)" || return 1
  have_minor="$(_version_part "${1}" minor)" || return 1
  want_major="$(_version_part "${2}" major)" || return 1
  want_minor="$(_version_part "${2}" minor)" || return 1
  if (( have_major != want_major )); then
    (( have_major > want_major ))
    return
  fi
  (( have_minor >= want_minor ))
}

_version_part() {
  local value="${1}" part
  if [[ "${2}" == "major" ]]; then
    part="${value%%.*}"
  elif [[ "${value}" == *.* ]]; then
    part="${value#*.}"
    part="${part%%[!0-9]*}"
  else
    part=0
  fi
  case "${part}" in
    ''|*[!0-9]*) return 1 ;;
  esac
  printf '%d' "$((10#${part}))"
}

truecolor_supported() {
  case "${1}" in
    *truecolor*|*24bit*) return 0 ;;
    *) return 1 ;;
  esac
}

nested_term() {
  case "${1}" in
    screen*|tmux*) return 0 ;;
    *) return 1 ;;
  esac
}

should_truecolor() {
  local ct="${1}" term="${2}"
  nested_term "${term}" && return 1
  truecolor_supported "${ct}" && return 0
  if [[ -z "${ct}" ]] && _terminfo_rgb "${term}"; then
    return 0
  fi
  return 1
}

extended_keys_terminal() {
  case "${2}" in
    iTerm.app|WezTerm|ghostty|mintty|contour|rio) return 0 ;;
  esac
  case "${1}" in
    xterm*|*kitty*|foot*|alacritty*|st|st-*|contour*|rio*|konsole*) return 0 ;;
    *) return 1 ;;
  esac
}

osc52_terminal() {
  case "${2}" in
    iTerm.app|WezTerm|ghostty|mintty|contour|rio) return 0 ;;
  esac
  case "${1}" in
    xterm*|*kitty*|foot*|alacritty*|st|st-*|contour*|rio*|konsole*|tmux*|screen*) return 0 ;;
    *) return 1 ;;
  esac
}

cursor_shape_terminal() {
  case "${2}" in
    iTerm.app|WezTerm|ghostty|mintty|contour|rio) return 0 ;;
  esac
  case "${1}" in
    xterm*|*kitty*|foot*|alacritty*|st|st-*|contour*|rio*|konsole*|vte*|gnome*) return 0 ;;
    *) return 1 ;;
  esac
}

sixel_terminal() {
  case "${2}" in
    iTerm.app|WezTerm|ghostty|contour) return 0 ;;
  esac
  case "${1}" in
    *kitty*|foot*|contour*|xterm*|mlterm*) return 0 ;;
    *) return 1 ;;
  esac
}

hyperlink_terminal() {
  case "${2}" in
    iTerm.app|WezTerm|ghostty|mintty|contour|rio) return 0 ;;
  esac
  case "${1}" in
    *kitty*|foot*|alacritty*|contour*|rio*|konsole*|vte*|gnome*) return 0 ;;
    *) return 1 ;;
  esac
}

choose_default_terminal() {
  if [[ "${1}" == "1" && "${2}" == "1" ]]; then
    echo "tmux-direct"
  elif [[ "${3}" == "1" ]]; then
    echo "tmux-256color"
  else
    echo "screen-256color"
  fi
}

default_terminal_unset() {
  case "${1}" in
    ""|screen|screen-256color) return 0 ;;
    *) return 1 ;;
  esac
}

os_kind() {
  case "${1}" in
    Darwin) echo "darwin"; return 0 ;;
  esac
  case "${2}" in
    *[Mm]icrosoft*|*WSL*) echo "wsl"; return 0 ;;
  esac
  case "${1}" in
    Linux) echo "linux" ;;
    *) echo "other" ;;
  esac
}

is_iterm() {
  case "${1}" in iTerm*) return 0 ;; esac
  case "${2}" in iTerm*) return 0 ;; esac
  return 1
}

editor_mode_keys() {
  case "${1}" in
    *vi*) echo "vi" ;;
    *) echo "emacs" ;;
  esac
}

_tmux_version_string() { tmux -V 2>/dev/null; }
_have() { command -v "${1}" >/dev/null 2>&1; }
_uname() { uname -s 2>/dev/null; }
_proc_version() { cat /proc/version 2>/dev/null; }
_has_terminfo() { infocmp "${1}" >/dev/null 2>&1; }
_terminfo_rgb() { infocmp -x "${1}" 2>/dev/null | grep -qE 'RGB|Tc'; }
_prefix() { tmux show-option -gv prefix 2>/dev/null; }
_get_server_option() { tmux show-option -sqv "${1}" 2>/dev/null; }
_get_window_option() { tmux show-option -wgqv "${1}" 2>/dev/null; }
_control_client_count() { tmux list-clients -F '#{client_control_mode}' 2>/dev/null | grep -c '^1$' || true; }

_key_unbound() {
  local key="${1//\\/\\\\}"
  ! tmux list-keys 2>/dev/null | grep -q "bind-key[[:space:]]\+\(-r[[:space:]]\+\)\?\(-T prefix[[:space:]]\+\)\?${key}[[:space:]]"
}

clipboard_command() {
  local wayland="${1}" display="${2}" os="${3}"
  if [[ -n "${wayland}" ]] && _have wl-copy; then
    echo "wl-copy"; return 0
  fi
  if _have termux-clipboard-set; then
    echo "termux-clipboard-set"; return 0
  fi
  if [[ "${os}" == "darwin" ]] && _have pbcopy; then
    echo "pbcopy"; return 0
  fi
  if [[ -n "${display}" ]] && _have xclip; then
    echo "xclip -selection clipboard"; return 0
  fi
  if [[ -n "${display}" ]] && _have xsel; then
    echo "xsel -ib"; return 0
  fi
  if [[ "${os}" == "wsl" ]] && _have clip.exe; then
    echo "clip.exe"; return 0
  fi
  echo ""
}

tmux_version() { parse_tmux_version "$(_tmux_version_string)"; }
current_os() { os_kind "$(_uname)" "$(_proc_version)"; }
resolve_clipboard() { clipboard_command "${WAYLAND_DISPLAY:-}" "${DISPLAY:-}" "$(current_os)"; }

export -f parse_tmux_version
export -f version_ge
export -f _version_part
export -f truecolor_supported
export -f nested_term
export -f should_truecolor
export -f extended_keys_terminal
export -f osc52_terminal
export -f cursor_shape_terminal
export -f sixel_terminal
export -f hyperlink_terminal
export -f choose_default_terminal
export -f default_terminal_unset
export -f os_kind
export -f is_iterm
export -f editor_mode_keys
export -f _tmux_version_string
export -f _have
export -f _uname
export -f _proc_version
export -f _has_terminfo
export -f _terminfo_rgb
export -f _prefix
export -f _get_server_option
export -f _get_window_option
export -f _control_client_count
export -f _key_unbound
export -f clipboard_command
export -f tmux_version
export -f current_os
export -f resolve_clipboard
