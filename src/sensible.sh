#!/usr/bin/env bash

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SENSIBLE_DEFAULT_WORD_SEPARATORS='!"#$%&'\''()*+,-./:;<=>?@[\]^`{|}~'
SENSIBLE_RESIZE_SAVED_OPTION='@sensible_revamped_resize_saved'

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/sensible/sensible.sh"

_emit() {
  if [[ -n "${SENSIBLE_DRY_RUN:-}" ]]; then
    echo "$*"
  else
    tmux "$@"
  fi
}

_get_option() { tmux show-option -gqv "${1}" 2>/dev/null; }

_set_default() {
  local opt="${1}" def="${2}" val="${3}" cur
  cur="$(_get_option "${opt}")"
  if [[ -z "${cur}" || "${cur}" == "${def}" ]]; then
    _emit set -g "${opt}" "${val}"
  fi
}

_set_server_default() {
  local opt="${1}" def="${2}" val="${3}" cur
  cur="$(_get_server_option "${opt}")"
  if [[ -z "${cur}" || "${cur}" == "${def}" ]]; then
    _emit set -sg "${opt}" "${val}"
  fi
}

_set_window_default() {
  local opt="${1}" def="${2}" val="${3}" cur
  cur="$(_get_window_option "${opt}")"
  if [[ -z "${cur}" || "${cur}" == "${def}" ]]; then
    _emit setw -g "${opt}" "${val}"
  fi
}

_append_once() {
  local flags="${1}" opt="${2}" entry="${3}" item current
  item="${entry#,}"
  current="$(_get_server_option "${opt}")"$'\n'"$(_get_option "${opt}")"
  current=",$(printf '%s' "${current}" | tr '\n' ','),"
  case "${current}" in
    *",${item},"*) return 0 ;;
  esac
  _emit set "${flags}" "${opt}" "${entry}"
}

_set_default_terminal() {
  local val="${1}" cur
  cur="$(_get_option default-terminal)"
  if default_terminal_unset "${cur}"; then
    _emit set -g default-terminal "${val}"
  fi
  cur="$(_get_server_option default-terminal)"
  if default_terminal_unset "${cur}"; then
    _emit set -sg default-terminal "${val}"
  fi
}

_config_path() {
  if [[ -n "${XDG_CONFIG_HOME:-}" && -f "${XDG_CONFIG_HOME}/tmux/tmux.conf" ]]; then
    echo "${XDG_CONFIG_HOME}/tmux/tmux.conf"
  elif [[ -f "${HOME}/.config/tmux/tmux.conf" ]]; then
    echo "${HOME}/.config/tmux/tmux.conf"
  else
    echo "${HOME}/.tmux.conf"
  fi
}

_apply_copy_bindings() {
  local ver="${1}" clip="${2}"
  if version_ge "${ver}" 2.4; then
    if [[ -n "${clip}" ]]; then
      _emit bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "${clip}"
      _emit bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "${clip}"
      _emit bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${clip}"
      _emit bind-key -T copy-mode M-w send-keys -X copy-pipe-and-cancel "${clip}"
      _emit bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "${clip}"
    else
      _emit bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      _emit bind-key -T copy-mode-vi Enter send-keys -X copy-selection-and-cancel
      _emit bind-key -T copy-mode M-w send-keys -X copy-selection-and-cancel
    fi
    _emit bind-key -T copy-mode-vi v send-keys -X begin-selection
    _emit bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
  else
    if [[ -n "${clip}" ]]; then
      _emit bind-key -t vi-copy y copy-pipe "${clip}"
      _emit bind-key -t emacs-copy M-w copy-pipe "${clip}"
    else
      _emit bind-key -t vi-copy y copy-selection
      _emit bind-key -t emacs-copy M-w copy-selection
    fi
    _emit bind-key -t vi-copy v begin-selection
    _emit bind-key -t vi-copy C-v rectangle-toggle
  fi
}

apply_sensible() {
  local ver os dt mk clip prefix iterm=0
  local tc=0 has_direct=0 has_256=0
  ver="$(tmux_version)"
  os="$(current_os)"
  mk="$(editor_mode_keys "${EDITOR:-}${VISUAL:-}")"
  is_iterm "${TERM_PROGRAM:-}" "${LC_TERMINAL:-}" && iterm=1

  should_truecolor "${COLORTERM:-}" "${TERM:-}" && tc=1
  _has_terminfo tmux-direct && has_direct=1
  _has_terminfo tmux-256color && has_256=1

  dt="$(choose_default_terminal "${tc}" "${has_direct}" "${has_256}")"
  _set_default_terminal "${dt}"

  if [[ "${tc}" -eq 1 ]]; then
    if version_ge "${ver}" 3.2; then
      _append_once -as terminal-features ",*:RGB"
    else
      _append_once -ga terminal-overrides ",*:Tc"
    fi
  fi
  if version_ge "${ver}" 3.0; then
    _append_once -ga terminal-overrides ',*:Smulx=\E[4::%p1%dm'
    _append_once -ga terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'
  fi

  if ! version_ge "${ver}" 3.2; then
    if osc52_terminal "${TERM:-}" "${TERM_PROGRAM:-}"; then
      _append_once -ga terminal-overrides ',*:Ms=\E]52;%p1%s;%p2%s\007'
    fi
    if cursor_shape_terminal "${TERM:-}" "${TERM_PROGRAM:-}"; then
      _append_once -ga terminal-overrides ',*:Ss=\E[%p1%d q:Se=\E[2 q'
    fi
  fi

  _set_server_default escape-time 500 10
  if version_ge "${ver}" 1.9; then
    _set_default focus-events off on
  fi

  _set_default set-clipboard external on
  if version_ge "${ver}" 3.2; then
    _append_once -as terminal-features ",*:clipboard:ccolour:cstyle:focus:title"
    _append_once -as terminal-features ",rxvt*:ignorefkeys"
  fi
  if version_ge "${ver}" 3.4; then
    _set_default allow-passthrough off all
  elif version_ge "${ver}" 3.3; then
    _set_default allow-passthrough off on
  fi
  if version_ge "${ver}" 3.4; then
    if sixel_terminal "${TERM:-}" "${TERM_PROGRAM:-}"; then
      _append_once -as terminal-features ",*:sixel"
    fi
    if hyperlink_terminal "${TERM:-}" "${TERM_PROGRAM:-}"; then
      _append_once -as terminal-features ",*:hyperlinks"
    fi
  fi

  if version_ge "${ver}" 3.2 && extended_keys_terminal "${TERM:-}" "${TERM_PROGRAM:-}"; then
    _set_server_default extended-keys off on
    _append_once -as terminal-features "xterm*:extkeys"
    if version_ge "${ver}" 3.5; then
      _set_server_default extended-keys-format xterm csi-u
    fi
  fi

  _set_default history-limit 2000 50000
  _set_default display-time 750 4000
  _set_default status-interval 15 5
  _set_default repeat-time 500 1000
  _set_default display-panes-time 1000 2000
  _set_default status-keys emacs emacs
  _set_default set-titles off on

  _set_window_default word-separators "${SENSIBLE_DEFAULT_WORD_SEPARATORS}" " "

  _set_default base-index 0 1
  if version_ge "${ver}" 1.6; then
    _set_window_default pane-base-index 0 1
  fi
  if version_ge "${ver}" 1.7; then
    _set_default renumber-windows off on
  fi
  _set_window_default automatic-rename on on
  if version_ge "${ver}" 3.0; then
    _apply_resize_hooks
  elif [[ "${iterm}" -eq 0 ]]; then
    _set_window_default aggressive-resize off on
  fi

  _set_window_default mode-keys emacs "${mk}"
  clip="$(resolve_clipboard)"
  _apply_copy_bindings "${ver}" "${clip}"

  if [[ "${os}" == "darwin" ]] && _have reattach-to-user-namespace; then
    # shellcheck disable=SC2016
    _set_default default-command '' 'reattach-to-user-namespace -l $SHELL'
  fi

  prefix="$(_prefix)"
  if [[ -n "${prefix}" && "${prefix}" != "C-b" ]]; then
    _emit unbind-key C-b
    if _key_unbound "${prefix}"; then
      _emit bind-key "${prefix}" send-prefix
    fi
  fi
  _apply_convenience_keys
}

_tmux_quote() {
  local quote="'" escaped="'\"'\"'"
  printf "'%s'" "${1//"${quote}"/${escaped}}"
}

_hash_escape() {
  local hash="#"
  printf '%s' "${1//"${hash}"/${hash}${hash}}"
}

_resize_sync_hook() {
  local script
  script="$(printf '%q' "${PLUGIN_DIR}/src/sensible.sh")"
  printf 'run-shell -b %s' "$(_tmux_quote "$(_hash_escape "bash ${script} --resize-sync")")"
}

_apply_resize_hooks() {
  local hook
  if [[ "$(_control_client_count)" -eq 0 ]]; then
    _set_window_default aggressive-resize off on
  fi
  hook="$(_resize_sync_hook)"
  _emit set-hook -g 'client-attached[1000]' "${hook}"
  _emit set-hook -g 'client-detached[1000]' "${hook}"
}

resize_sync() {
  local saved current
  saved="$(_get_option "${SENSIBLE_RESIZE_SAVED_OPTION}")"
  if [[ "$(_control_client_count)" -gt 0 ]]; then
    if [[ -z "${saved}" ]]; then
      current="$(_get_window_option aggressive-resize)"
      _emit set -g "${SENSIBLE_RESIZE_SAVED_OPTION}" "${current:-off}"
    fi
    _emit setw -g aggressive-resize off
    return 0
  fi
  [[ -n "${saved}" ]] || return 0
  _emit setw -g aggressive-resize "${saved}"
  _emit set -gu "${SENSIBLE_RESIZE_SAVED_OPTION}"
}

_apply_convenience_keys() {
  local last_key reload_key conf
  [[ "$(_get_option @sensible_revamped_keys)" == "off" ]] && return 0
  last_key="$(_get_option @sensible_revamped_last_window_key)"
  reload_key="$(_get_option @sensible_revamped_reload_key)"
  if [[ -n "${last_key}" ]] && _key_unbound "${last_key}"; then
    _emit bind-key "${last_key}" last-window
  fi
  if _key_unbound C-p; then
    _emit bind-key C-p previous-window
  fi
  if _key_unbound C-n; then
    _emit bind-key C-n next-window
  fi
  if [[ -n "${reload_key}" ]] && _key_unbound "${reload_key}"; then
    conf="$(_config_path)"
    _emit bind-key "${reload_key}" source-file "${conf}" '\;' display-message "tmux-sensible-revamped: reloaded"
  fi
  return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    --resize-sync) resize_sync ;;
    *) apply_sensible ;;
  esac
fi
