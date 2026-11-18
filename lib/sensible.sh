#!/bin/sh

[ -n "${SENSIBLE_REVAMPED_SENSIBLE_LOADED:-}" ] && return 0
SENSIBLE_REVAMPED_SENSIBLE_LOADED=1

# shellcheck source=SCRIPTDIR/state.sh
. "${REVAMPED_LIB:?}/state.sh"
# shellcheck source=SCRIPTDIR/platform.sh
. "${REVAMPED_LIB}/platform.sh"
# shellcheck source=SCRIPTDIR/command.sh
. "${REVAMPED_LIB}/command.sh"

sensible_revamped_parse_version() {
  printf '%s\n' "$1" | sed -En 's/^tmux[ -]([a-z]+-)?([0-9]+\.[0-9]+).*/\2/p'
}

sensible_revamped_version_ge() {
  case "$1:$2" in
  *[!0-9.:]* | :* | *:) return 1 ;;
  *) ;;
  esac
  sensible_revamped_version_ge_have="${1%%.*}"
  sensible_revamped_version_ge_want="${2%%.*}"
  [ "${sensible_revamped_version_ge_have}" -gt "${sensible_revamped_version_ge_want}" ] && return 0
  [ "${sensible_revamped_version_ge_have}" -eq "${sensible_revamped_version_ge_want}" ] || return 1
  sensible_revamped_version_ge_have="${1#*.}"
  sensible_revamped_version_ge_want="${2#*.}"
  [ "${sensible_revamped_version_ge_have%%.*}" -ge "${sensible_revamped_version_ge_want%%.*}" ]
}

sensible_revamped_at_least() {
  sensible_revamped_version_ge "${SENSIBLE_REVAMPED_TMUX}" "$1"
}

sensible_revamped_flag() {
  case "$1" in
  s) SENSIBLE_REVAMPED_FLAG=-sqv ;;
  w) SENSIBLE_REVAMPED_FLAG=-wgqv ;;
  *) SENSIBLE_REVAMPED_FLAG=-gqv ;;
  esac
}

sensible_revamped_stream() {
  sensible_revamped_stream_rows="$1"
  set --
  while read -r sensible_revamped_stream_scope sensible_revamped_stream_name; do
    [ -n "${sensible_revamped_stream_name}" ] || continue
    if [ "${sensible_revamped_stream_scope}" = e ]; then
      set -- "$@" show-environment -g ";" display-message -p "${SENSIBLE_REVAMPED_MARK}" ";"
      continue
    fi
    sensible_revamped_flag "${sensible_revamped_stream_scope}"
    set -- "$@" show-option "${SENSIBLE_REVAMPED_FLAG}" "${sensible_revamped_stream_name}" ";" display-message -p "${SENSIBLE_REVAMPED_MARK}" ";"
  done <<EOF
${sensible_revamped_stream_rows}
EOF
  tmux "$@" list-clients -F '#{client_control_mode}' 2>/dev/null || :
}

sensible_revamped_stream_each() {
  while read -r sensible_revamped_stream_each_scope sensible_revamped_stream_each_name; do
    [ -n "${sensible_revamped_stream_each_name}" ] || continue
    sensible_revamped_flag "${sensible_revamped_stream_each_scope}"
    if [ "${sensible_revamped_stream_each_scope}" = e ]; then
      tmux show-environment -g 2>/dev/null || :
    else
      tmux show-option "${SENSIBLE_REVAMPED_FLAG}" "${sensible_revamped_stream_each_name}" 2>/dev/null || :
    fi
    printf '%s\n' "${SENSIBLE_REVAMPED_MARK}"
  done <<EOF
$1
EOF
  tmux list-clients -F '#{client_control_mode}' 2>/dev/null || :
}

sensible_revamped_parse() {
  SENSIBLE_REVAMPED_ROWS="$1" awk -v mark="${SENSIBLE_REVAMPED_MARK}" '
    function flush(key) {
      if (key == "e environment") { print "e_term\t" term; print "e_program\t" program; print "e_seen\t" (lines > 0) }
      gsub(/[^A-Za-z0-9]/, "_", key)
      if (key != "e_environment") { print key "\t" value }
      value = ""
      lines = 0
    }
    BEGIN { count = split(ENVIRON["SENSIBLE_REVAMPED_ROWS"], row, "\n"); at = 1 }
    $0 == mark { flush(row[at]); at++; next }
    row[at] == "e environment" {
      lines++
      if (index($0, "TERM=") == 1) { term = substr($0, 6) }
      if (index($0, "TERM_PROGRAM=") == 1) { program = substr($0, 14) }
      next
    }
    { value = (lines++ ? value "," : "") $0 }
    END { flush("clients"); print "marks\t" (at - 1 == count ? "ok" : "short") }
  '
}

sensible_revamped_assign() {
  while IFS='	' read -r sensible_revamped_assign_key sensible_revamped_assign_value; do
    [ -n "${sensible_revamped_assign_key}" ] || continue
    IFS= read -r "SENSIBLE_REVAMPED_O_${sensible_revamped_assign_key}" <<EOF
${sensible_revamped_assign_value}
EOF
  done <<EOF
$1
EOF
}

sensible_revamped_read() {
  sensible_revamped_read_rows=$(sensible_revamped_stream "$1" | sensible_revamped_parse "$1")
  sensible_revamped_assign "${sensible_revamped_read_rows}"
  [ "${SENSIBLE_REVAMPED_O_marks}" != ok ] || return 0
  sensible_revamped_read_rows=$(sensible_revamped_stream_each "$1" | sensible_revamped_parse "$1")
  sensible_revamped_assign "${sensible_revamped_read_rows}"
}

sensible_revamped_terminal() {
  SENSIBLE_REVAMPED_TERM="${TERM:-}" SENSIBLE_REVAMPED_PROGRAM="${TERM_PROGRAM:-}"
  [ "${SENSIBLE_REVAMPED_O_e_seen}" = 1 ] || return 0
  SENSIBLE_REVAMPED_TERM="${SENSIBLE_REVAMPED_O_e_term}" SENSIBLE_REVAMPED_PROGRAM="${SENSIBLE_REVAMPED_O_e_program}"
}

sensible_revamped_settings() {
  SENSIBLE_REVAMPED_S_keys="${SENSIBLE_REVAMPED_O_g__sensible_revamped_keys:-on}"
  SENSIBLE_REVAMPED_S_last_window_key="${SENSIBLE_REVAMPED_O_g__sensible_revamped_last_window_key}"
  SENSIBLE_REVAMPED_S_reload_key="${SENSIBLE_REVAMPED_O_g__sensible_revamped_reload_key}"
  [ -z "${SENSIBLE_REVAMPED_KEYS+set}" ] || SENSIBLE_REVAMPED_S_keys="${SENSIBLE_REVAMPED_KEYS}"
  [ -z "${SENSIBLE_REVAMPED_LAST_WINDOW_KEY+set}" ] || SENSIBLE_REVAMPED_S_last_window_key="${SENSIBLE_REVAMPED_LAST_WINDOW_KEY}"
  [ -z "${SENSIBLE_REVAMPED_RELOAD_KEY+set}" ] || SENSIBLE_REVAMPED_S_reload_key="${SENSIBLE_REVAMPED_RELOAD_KEY}"
}

sensible_revamped_emit() {
  for sensible_revamped_emit_arg in "$@"; do
    SENSIBLE_REVAMPED_PLAN="${SENSIBLE_REVAMPED_PLAN}${sensible_revamped_emit_arg}
"
  done
  SENSIBLE_REVAMPED_PLAN="${SENSIBLE_REVAMPED_PLAN}
"
}

sensible_revamped_default() {
  sensible_revamped_default_now="$1" sensible_revamped_default_stock="$2"
  shift 2
  [ -z "${sensible_revamped_default_now}" ] || [ "${sensible_revamped_default_now}" = "${sensible_revamped_default_stock}" ] || return 0
  sensible_revamped_emit "$@"
}

sensible_revamped_append() {
  sensible_revamped_append_item="${3#,}"
  case ",$4," in
  *",${sensible_revamped_append_item},"*) return 0 ;;
  *) ;;
  esac
  sensible_revamped_emit set "$1" "$2" "$3"
}

sensible_revamped_feature() {
  sensible_revamped_append -as terminal-features "$1" "${SENSIBLE_REVAMPED_O_s_terminal_features},${SENSIBLE_REVAMPED_O_g_terminal_features}"
}

sensible_revamped_override() {
  sensible_revamped_append -ga terminal-overrides "$1" "${SENSIBLE_REVAMPED_O_s_terminal_overrides},${SENSIBLE_REVAMPED_O_g_terminal_overrides}"
}

sensible_revamped_modern_program() {
  case "${SENSIBLE_REVAMPED_PROGRAM}" in
  iTerm.app | WezTerm | ghostty | mintty | contour | rio) return 0 ;;
  *) return 1 ;;
  esac
}

sensible_revamped_extended_keys_terminal() {
  ! sensible_revamped_modern_program || return 0
  case "${SENSIBLE_REVAMPED_TERM}" in
  xterm* | *kitty* | foot* | alacritty* | st | st-* | contour* | rio* | konsole*) return 0 ;;
  *) return 1 ;;
  esac
}

sensible_revamped_osc52_terminal() {
  ! sensible_revamped_extended_keys_terminal || return 0
  case "${SENSIBLE_REVAMPED_TERM}" in
  tmux* | screen*) return 0 ;;
  *) return 1 ;;
  esac
}

sensible_revamped_cursor_terminal() {
  ! sensible_revamped_extended_keys_terminal || return 0
  case "${SENSIBLE_REVAMPED_TERM}" in
  vte* | gnome*) return 0 ;;
  *) return 1 ;;
  esac
}

sensible_revamped_sixel_terminal() {
  case "${SENSIBLE_REVAMPED_PROGRAM}" in
  iTerm.app | WezTerm | ghostty | contour) return 0 ;;
  *) ;;
  esac
  case "${SENSIBLE_REVAMPED_TERM}" in
  *kitty* | foot* | contour* | xterm* | mlterm*) return 0 ;;
  *) return 1 ;;
  esac
}

sensible_revamped_hyperlink_terminal() {
  ! sensible_revamped_modern_program || return 0
  case "${SENSIBLE_REVAMPED_TERM}" in
  *kitty* | foot* | alacritty* | contour* | rio* | konsole* | vte* | gnome*) return 0 ;;
  *) return 1 ;;
  esac
}

sensible_revamped_iterm() {
  case "${SENSIBLE_REVAMPED_PROGRAM}:${LC_TERMINAL:-}" in
  iTerm*:* | *:iTerm*) return 0 ;;
  *) return 1 ;;
  esac
}

sensible_revamped_terminfo_rgb() {
  infocmp -x "$1" 2>/dev/null | grep -qE 'RGB|Tc'
}

sensible_revamped_truecolor() {
  case "${SENSIBLE_REVAMPED_TERM}" in
  screen* | tmux*) return 1 ;;
  *) ;;
  esac
  case "${COLORTERM:-}" in
  *truecolor* | *24bit*) return 0 ;;
  "") sensible_revamped_terminfo_rgb "${SENSIBLE_REVAMPED_TERM}" ;;
  *) return 1 ;;
  esac
}

sensible_revamped_terminal_name() {
  if [ "$1" = 1 ] && infocmp tmux-direct >/dev/null 2>&1; then
    printf 'tmux-direct\n'
  elif infocmp tmux-256color >/dev/null 2>&1; then
    printf 'tmux-256color\n'
  else
    printf 'screen-256color\n'
  fi
}

sensible_revamped_terminal_unset() {
  case "$1" in
  "" | screen | screen-256color) return 0 ;;
  *) return 1 ;;
  esac
}

sensible_revamped_mode_keys() {
  case "${EDITOR:-}${VISUAL:-}" in
  *vi*) printf 'vi\n' ;;
  *) printf 'emacs\n' ;;
  esac
}

sensible_revamped_wsl() {
  [ -r "${SENSIBLE_REVAMPED_PROC_VERSION}" ] || return 1
  IFS= read -r sensible_revamped_wsl_line <"${SENSIBLE_REVAMPED_PROC_VERSION}" || :
  case "${sensible_revamped_wsl_line}" in
  *[Mm]icrosoft* | *WSL*) return 0 ;;
  *) return 1 ;;
  esac
}

sensible_revamped_clipboard() {
  if [ -n "${WAYLAND_DISPLAY:-}" ] && revamped_has_command wl-copy; then
    printf 'wl-copy\n'
  elif revamped_has_command termux-clipboard-set; then
    printf 'termux-clipboard-set\n'
  elif revamped_is_macos && revamped_has_command pbcopy; then
    printf 'pbcopy\n'
  elif [ -n "${DISPLAY:-}" ] && revamped_has_command xclip; then
    printf 'xclip -selection clipboard\n'
  elif [ -n "${DISPLAY:-}" ] && revamped_has_command xsel; then
    printf 'xsel -ib\n'
  elif ! revamped_is_macos && revamped_has_command clip.exe && sensible_revamped_wsl; then
    printf 'clip.exe\n'
  fi
}

sensible_revamped_config() {
  if [ -n "${XDG_CONFIG_HOME:-}" ] && [ -f "${XDG_CONFIG_HOME}/tmux/tmux.conf" ]; then
    printf '%s\n' "${XDG_CONFIG_HOME}/tmux/tmux.conf"
  elif [ -f "${HOME}/.config/tmux/tmux.conf" ]; then
    printf '%s\n' "${HOME}/.config/tmux/tmux.conf"
  else
    printf '%s\n' "${HOME}/.tmux.conf"
  fi
}

sensible_revamped_tool() {
  sensible_revamped_tool_quoted=$(printf '%s\n' "${REVAMPED_LIB%/lib}/bin/sensible-revamped" | sed "s/'/'\\\\''/g")
  printf "'%s'\n" "${sensible_revamped_tool_quoted}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\$/\\$/g' -e 's/#/##/g'
}

sensible_revamped_controlled() {
  case ",${SENSIBLE_REVAMPED_O_clients}," in
  *,1,*) return 0 ;;
  *) return 1 ;;
  esac
}

sensible_revamped_plan_terminal() {
  sensible_revamped_plan_terminal_rgb=0
  ! sensible_revamped_truecolor || sensible_revamped_plan_terminal_rgb=1
  sensible_revamped_plan_terminal_name=$(sensible_revamped_terminal_name "${sensible_revamped_plan_terminal_rgb}")
  ! sensible_revamped_terminal_unset "${SENSIBLE_REVAMPED_O_g_default_terminal}" || sensible_revamped_emit set -g default-terminal "${sensible_revamped_plan_terminal_name}"
  ! sensible_revamped_terminal_unset "${SENSIBLE_REVAMPED_O_s_default_terminal}" || sensible_revamped_emit set -sg default-terminal "${sensible_revamped_plan_terminal_name}"
  if [ "${sensible_revamped_plan_terminal_rgb}" = 1 ] && sensible_revamped_at_least 3.2; then
    sensible_revamped_feature ",*:RGB"
  elif [ "${sensible_revamped_plan_terminal_rgb}" = 1 ]; then
    sensible_revamped_override ",*:Tc"
  fi
  if sensible_revamped_at_least 3.0; then
    sensible_revamped_override ',*:Smulx=\E[4::%p1%dm'
    sensible_revamped_override ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'
  fi
  ! sensible_revamped_at_least 3.2 || return 0
  ! sensible_revamped_osc52_terminal || sensible_revamped_override ',*:Ms=\E]52;%p1%s;%p2%s\007'
  ! sensible_revamped_cursor_terminal || sensible_revamped_override ',*:Ss=\E[%p1%d q:Se=\E[2 q'
}

sensible_revamped_plan_passthrough() {
  if sensible_revamped_at_least 3.4; then
    sensible_revamped_default "${SENSIBLE_REVAMPED_O_g_allow_passthrough}" off set -g allow-passthrough all
  elif sensible_revamped_at_least 3.3; then
    sensible_revamped_default "${SENSIBLE_REVAMPED_O_g_allow_passthrough}" off set -g allow-passthrough on
  fi
  sensible_revamped_at_least 3.4 || return 0
  ! sensible_revamped_sixel_terminal || sensible_revamped_feature ",*:sixel"
  ! sensible_revamped_hyperlink_terminal || sensible_revamped_feature ",*:hyperlinks"
}

sensible_revamped_plan_extended_keys() {
  sensible_revamped_at_least 3.2 || return 0
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_s_extended_keys}" off set -sg extended-keys on
  ! sensible_revamped_extended_keys_terminal || sensible_revamped_feature "xterm*:extkeys"
  ! sensible_revamped_at_least 3.5 || sensible_revamped_default "${SENSIBLE_REVAMPED_O_s_extended_keys_format}" xterm set -sg extended-keys-format csi-u
}

sensible_revamped_plan_server() {
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_s_escape_time}" 500 set -sg escape-time 10
  ! sensible_revamped_at_least 1.9 || sensible_revamped_default "${SENSIBLE_REVAMPED_O_g_focus_events}" off set -g focus-events on
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_g_set_clipboard}" external set -g set-clipboard on
  if sensible_revamped_at_least 3.2; then
    sensible_revamped_feature ",*:clipboard:ccolour:cstyle:focus:title"
    sensible_revamped_feature ",rxvt*:ignorefkeys"
  fi
  sensible_revamped_plan_passthrough
  sensible_revamped_plan_extended_keys
}

sensible_revamped_plan_session() {
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_g_history_limit}" 2000 set -g history-limit 50000
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_g_display_time}" 750 set -g display-time 4000
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_g_status_interval}" 15 set -g status-interval 5
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_g_repeat_time}" 500 set -g repeat-time 1000
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_g_display_panes_time}" 1000 set -g display-panes-time 2000
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_g_status_keys}" emacs set -g status-keys emacs
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_g_set_titles}" off set -g set-titles on
}

sensible_revamped_plan_resize() {
  if sensible_revamped_at_least 3.0; then
    sensible_revamped_controlled || sensible_revamped_default "${SENSIBLE_REVAMPED_O_w_aggressive_resize}" off setw -g aggressive-resize on
    sensible_revamped_plan_resize_tool=$(sensible_revamped_tool)
    sensible_revamped_emit set-hook -g "client-attached[${SENSIBLE_REVAMPED_HOOK_INDEX}]" "run-shell -b \"${sensible_revamped_plan_resize_tool} resize-sync\""
    sensible_revamped_emit set-hook -g "client-detached[${SENSIBLE_REVAMPED_HOOK_INDEX}]" "run-shell -b \"${sensible_revamped_plan_resize_tool} resize-sync\""
    return 0
  fi
  sensible_revamped_iterm || sensible_revamped_default "${SENSIBLE_REVAMPED_O_w_aggressive_resize}" off setw -g aggressive-resize on
}

sensible_revamped_plan_windows() {
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_w_word_separators}" "${SENSIBLE_REVAMPED_WORD_SEPARATORS}" setw -g word-separators " "
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_g_base_index}" 0 set -g base-index 1
  ! sensible_revamped_at_least 1.6 || sensible_revamped_default "${SENSIBLE_REVAMPED_O_w_pane_base_index}" 0 setw -g pane-base-index 1
  ! sensible_revamped_at_least 1.7 || sensible_revamped_default "${SENSIBLE_REVAMPED_O_g_renumber_windows}" off set -g renumber-windows on
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_w_automatic_rename}" on setw -g automatic-rename on
  sensible_revamped_plan_resize
  sensible_revamped_plan_windows_keys=$(sensible_revamped_mode_keys)
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_w_mode_keys}" emacs setw -g mode-keys "${sensible_revamped_plan_windows_keys}"
}

sensible_revamped_plan_copy_tables() {
  if [ -n "$1" ]; then
    sensible_revamped_emit bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "$1"
    sensible_revamped_emit bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "$1"
    sensible_revamped_emit bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "$1"
    sensible_revamped_emit bind-key -T copy-mode M-w send-keys -X copy-pipe-and-cancel "$1"
    sensible_revamped_emit bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "$1"
  else
    sensible_revamped_emit bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
    sensible_revamped_emit bind-key -T copy-mode-vi Enter send-keys -X copy-selection-and-cancel
    sensible_revamped_emit bind-key -T copy-mode M-w send-keys -X copy-selection-and-cancel
  fi
  sensible_revamped_emit bind-key -T copy-mode-vi v send-keys -X begin-selection
  sensible_revamped_emit bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
}

sensible_revamped_plan_copy_legacy() {
  if [ -n "$1" ]; then
    sensible_revamped_emit bind-key -t vi-copy y copy-pipe "$1"
    sensible_revamped_emit bind-key -t emacs-copy M-w copy-pipe "$1"
  else
    sensible_revamped_emit bind-key -t vi-copy y copy-selection
    sensible_revamped_emit bind-key -t emacs-copy M-w copy-selection
  fi
  sensible_revamped_emit bind-key -t vi-copy v begin-selection
  sensible_revamped_emit bind-key -t vi-copy C-v rectangle-toggle
}

sensible_revamped_plan_copy() {
  sensible_revamped_plan_copy_tool=$(sensible_revamped_clipboard)
  if sensible_revamped_at_least 2.4; then
    sensible_revamped_plan_copy_tables "${sensible_revamped_plan_copy_tool}"
  else
    sensible_revamped_plan_copy_legacy "${sensible_revamped_plan_copy_tool}"
  fi
  revamped_is_macos || return 0
  revamped_has_command reattach-to-user-namespace || return 0
  # shellcheck disable=SC2016
  sensible_revamped_default "${SENSIBLE_REVAMPED_O_g_default_command}" "" set -g default-command 'reattach-to-user-namespace -l $SHELL'
}

sensible_revamped_held() {
  tmux list-keys 2>/dev/null | SENSIBLE_REVAMPED_WANT="$1" awk -v quote="${SENSIBLE_REVAMPED_QUOTE}" '
    BEGIN {
      count = split(ENVIRON["SENSIBLE_REVAMPED_WANT"], pair, "\n")
      for (i = 1; i <= count; i++) { split(pair[i], field, "\t"); want[i] = field[1]; ours[i] = field[2] }
    }
    $1 != "bind-key" { next }
    {
      at = 2
      if ($at == "-r") { at++ }
      if ($at == "-n") { next }
      if ($at == "-T" && $(at + 1) != "prefix") { next }
      if ($at == "-T") { at += 2 }
      rest = ""
      for (i = at + 1; i <= NF; i++) { rest = rest (i > at + 1 ? " " : "") $i }
      for (i = 1; i <= count; i++) {
        if (want[i] == "") { continue }
        if ($at != want[i] && $at != "\\" want[i] && $at != "\"" want[i] "\"" && $at != quote want[i] quote) { continue }
        held[i] = 1
        if (index(rest, ours[i]) == 0) { theirs[i] = 1 }
      }
    }
    END {
      for (i = 1; i <= count; i++) { if (held[i]) { printf "%s ", want[i] } }
      printf "\t"
      for (i = 1; i <= count; i++) { if (theirs[i]) { printf "%s ", want[i] } }
    }
  '
}

sensible_revamped_bind() {
  case " ${SENSIBLE_REVAMPED_HELD} " in
  *" $1 "*)
    case " ${SENSIBLE_REVAMPED_THEIRS} " in
    *" $1 "*) SENSIBLE_REVAMPED_SKIPPED="${SENSIBLE_REVAMPED_SKIPPED}${SENSIBLE_REVAMPED_SKIPPED:+ }$1" ;;
    *) ;;
    esac
    return 0
    ;;
  *) ;;
  esac
  SENSIBLE_REVAMPED_HELD="${SENSIBLE_REVAMPED_HELD} $1"
  SENSIBLE_REVAMPED_THEIRS="${SENSIBLE_REVAMPED_THEIRS} $1"
  sensible_revamped_emit bind-key "$@"
}

sensible_revamped_plan_prefix() {
  case "${SENSIBLE_REVAMPED_O_g_prefix}" in
  "" | C-b) return 0 ;;
  *) ;;
  esac
  sensible_revamped_emit unbind-key C-b
  sensible_revamped_bind "${SENSIBLE_REVAMPED_O_g_prefix}" send-prefix
}

sensible_revamped_plan_keys() {
  sensible_revamped_plan_keys_bound=$(sensible_revamped_held "${SENSIBLE_REVAMPED_O_g_prefix}	send-prefix
${SENSIBLE_REVAMPED_S_last_window_key}	last-window
C-p	previous-window
C-n	next-window
${SENSIBLE_REVAMPED_S_reload_key}	tmux-sensible-revamped: reloaded")
  SENSIBLE_REVAMPED_HELD="${sensible_revamped_plan_keys_bound%%	*}"
  SENSIBLE_REVAMPED_THEIRS="${sensible_revamped_plan_keys_bound#*	}"
  sensible_revamped_plan_prefix
  [ "${SENSIBLE_REVAMPED_S_keys}" != off ] || return 0
  [ -z "${SENSIBLE_REVAMPED_S_last_window_key}" ] || sensible_revamped_bind "${SENSIBLE_REVAMPED_S_last_window_key}" last-window
  sensible_revamped_bind C-p previous-window
  sensible_revamped_bind C-n next-window
  [ -n "${SENSIBLE_REVAMPED_S_reload_key}" ] || return 0
  sensible_revamped_plan_keys_config=$(sensible_revamped_config)
  sensible_revamped_bind "${SENSIBLE_REVAMPED_S_reload_key}" source-file "${sensible_revamped_plan_keys_config}" '\;' display-message "tmux-sensible-revamped: reloaded"
}

sensible_revamped_plan() {
  sensible_revamped_plan_raw=$(tmux -V 2>/dev/null) || sensible_revamped_plan_raw=""
  SENSIBLE_REVAMPED_TMUX=$(sensible_revamped_parse_version "${sensible_revamped_plan_raw}")
  sensible_revamped_read "${SENSIBLE_REVAMPED_READS}"
  sensible_revamped_terminal
  sensible_revamped_settings
  SENSIBLE_REVAMPED_PLAN="" SENSIBLE_REVAMPED_SKIPPED=""
  sensible_revamped_plan_terminal
  sensible_revamped_plan_server
  sensible_revamped_plan_session
  sensible_revamped_plan_windows
  sensible_revamped_plan_copy
  sensible_revamped_plan_keys
}

sensible_revamped_plan_sync() {
  sensible_revamped_read "${SENSIBLE_REVAMPED_RESIZE_READS}"
  SENSIBLE_REVAMPED_PLAN=""
  if sensible_revamped_controlled; then
    [ -n "${SENSIBLE_REVAMPED_O_g__sensible_revamped_resize_saved}" ] || sensible_revamped_emit set -g "${SENSIBLE_REVAMPED_RESIZE_SAVED}" "${SENSIBLE_REVAMPED_O_w_aggressive_resize:-off}"
    sensible_revamped_emit setw -g aggressive-resize off
    return 0
  fi
  [ -n "${SENSIBLE_REVAMPED_O_g__sensible_revamped_resize_saved}" ] || return 0
  sensible_revamped_emit setw -g aggressive-resize "${SENSIBLE_REVAMPED_O_g__sensible_revamped_resize_saved}"
  sensible_revamped_emit set -gu "${SENSIBLE_REVAMPED_RESIZE_SAVED}"
}

sensible_revamped_send() {
  set --
  sensible_revamped_send_sep=""
  while IFS= read -r sensible_revamped_send_line; do
    if [ -z "${sensible_revamped_send_line}" ]; then
      [ "$#" -eq 0 ] || sensible_revamped_send_sep=";"
      continue
    fi
    [ -z "${sensible_revamped_send_sep}" ] || set -- "$@" "${sensible_revamped_send_sep}"
    sensible_revamped_send_sep=""
    set -- "$@" "${sensible_revamped_send_line}"
  done <<PLAN
${SENSIBLE_REVAMPED_PLAN}
PLAN
  [ "$#" -gt 0 ] || return 0
  tmux "$@" 2>/dev/null
}

sensible_revamped_send_each() {
  sensible_revamped_send_each_status=0
  set --
  while IFS= read -r sensible_revamped_send_each_line; do
    if [ -n "${sensible_revamped_send_each_line}" ]; then
      set -- "$@" "${sensible_revamped_send_each_line}"
      continue
    fi
    [ "$#" -gt 0 ] || continue
    tmux "$@" || sensible_revamped_send_each_status=1
    set --
  done <<PLAN
${SENSIBLE_REVAMPED_PLAN}
PLAN
  return "${sensible_revamped_send_each_status}"
}

sensible_revamped_apply() {
  sensible_revamped_plan
  ! sensible_revamped_send || return 0
  sensible_revamped_plan
  sensible_revamped_send_each
}

sensible_revamped_resize_sync() {
  sensible_revamped_plan_sync
  ! sensible_revamped_send || return 0
  sensible_revamped_plan_sync
  sensible_revamped_send_each
}

sensible_revamped_lines() {
  printf '%s' "${SENSIBLE_REVAMPED_PLAN}" | awk '$0 == "" && line != "" { print line; line = ""; next } $0 == "" { next } { line = (line == "" ? $0 : line " " $0) } END { if (line != "") { print line } }'
}

sensible_revamped_json() {
  printf '%s' "${SENSIBLE_REVAMPED_PLAN}" | awk '
    function quote(s,    out, i, c) {
      out = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") { out = out "\\\\" } else if (c == "\"") { out = out "\\\"" } else { out = out c }
      }
      return "\"" out "\""
    }
    /^$/ { if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" } args = ""; next }
    { args = args (args == "" ? "" : ",") quote($0) }
    END {
      if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" }
      print "{\"commands\":[" rows "]}"
    }
  '
}

sensible_revamped_count() {
  printf '%s' "${SENSIBLE_REVAMPED_PLAN}" | awk 'previous == "" && $0 != "" { count++ } { previous = $0 } END { print count + 0 }'
}

sensible_revamped_setting_name() {
  sensible_revamped_setting_name_raw=$(printf '%s\n' "${1#--}" | tr '-' '_')
  case " ${SENSIBLE_REVAMPED_NAMES} " in
  *" ${sensible_revamped_setting_name_raw} "*) printf '%s\n' "${sensible_revamped_setting_name_raw}" ;;
  *) printf '\n' ;;
  esac
}
