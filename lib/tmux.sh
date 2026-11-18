#!/bin/sh

[ -n "${REVAMPED_TMUX_LOADED:-}" ] && return 0
REVAMPED_TMUX_LOADED=1

revamped_tmux_get() {
  revamped_tmux_get_value=$(tmux show-option -gqv "$1" 2>/dev/null) || revamped_tmux_get_value=""
  if [ -n "${revamped_tmux_get_value}" ] || [ -z "${2:-}" ]; then
    printf '%s\n' "${revamped_tmux_get_value}"
    return 0
  fi
  revamped_tmux_get_line=$(tmux show-option -gq "$1" 2>/dev/null) || revamped_tmux_get_line=""
  if [ -n "${revamped_tmux_get_line}" ]; then
    printf '\n'
    return 0
  fi
  printf '%s\n' "$2"
}

revamped_tmux_set() {
  tmux set-option -gq "$1" "$2" 2>/dev/null
}

revamped_tmux_unset() {
  tmux set-option -gqu "$1" 2>/dev/null
}

revamped_tmux_get_window() {
  revamped_tmux_get_window_value=$(tmux show-option -wqv "$1" 2>/dev/null) || revamped_tmux_get_window_value=""
  printf '%s\n' "${revamped_tmux_get_window_value:-${2:-}}"
}

revamped_tmux_set_window() {
  tmux set-option -wq "$1" "$2" 2>/dev/null
}

revamped_tmux_get_pane() {
  if [ -n "${3:-}" ]; then
    revamped_tmux_get_pane_value=$(tmux show-option -pqv -t "$3" "$1" 2>/dev/null) || revamped_tmux_get_pane_value=""
  else
    revamped_tmux_get_pane_value=$(tmux show-option -pqv "$1" 2>/dev/null) || revamped_tmux_get_pane_value=""
  fi
  printf '%s\n' "${revamped_tmux_get_pane_value:-${2:-}}"
}

revamped_tmux_set_pane() {
  if [ -n "${3:-}" ]; then
    tmux set-option -pq -t "$3" "$1" "$2" 2>/dev/null
  else
    tmux set-option -pq "$1" "$2" 2>/dev/null
  fi
}

revamped_tmux_display() {
  if [ -n "${2:-}" ]; then
    tmux display-message -p -t "$2" "$1" 2>/dev/null || printf '%s\n' "${3:-}"
  else
    tmux display-message -p "$1" 2>/dev/null || printf '%s\n' "${3:-}"
  fi
}

revamped_tmux_current_pane() {
  revamped_tmux_display '#{pane_id}'
}

revamped_tmux_current_window() {
  revamped_tmux_display '#{window_id}'
}

revamped_tmux_pane_count() {
  revamped_tmux_display '#{window_panes}' '' 0
}

revamped_tmux_pane_width() {
  revamped_tmux_display '#{pane_width}' "${1:-}" 0
}

revamped_tmux_pane_height() {
  revamped_tmux_display '#{pane_height}' "${1:-}" 0
}

revamped_tmux_window_width() {
  revamped_tmux_display '#{window_width}' '' 0
}

revamped_tmux_window_height() {
  revamped_tmux_display '#{window_height}' '' 0
}
