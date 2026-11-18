#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/tmux_helpers.bash"

screens() {
  printf 'host screen:\n'
  command tmux -S "${HOST}" capture-pane -p -t host || :
  printf 'pane:\n'
  tmux capture-pane -p -t %0 || :
  printf 'clipboard:\n'
  cat "${BATS_TEST_TMPDIR}/clipboard" 2>/dev/null || :
}

prefix_keys() {
  local table
  table=$(tmux list-keys -T prefix)
  awk '{ for (i = 1; i < NF; i++) { if ($i == "-T") { print $(i + 2); break } } }' <<<"${table}"
}

wait_for() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@" && return 0
  screens
  return 1
}

attached() {
  local clients
  clients=$(tmux list-clients -F x 2>/dev/null)
  [[ -n "${clients}" ]]
}

controlled() {
  local clients
  clients=$(tmux list-clients -F '#{client_control_mode}' 2>/dev/null)
  [[ "${clients}" == *1* ]]
}

uncontrolled() {
  ! controlled
}

shows() {
  local now
  now=$(tmux display-message -p -t "$1" "$2" 2>/dev/null)
  [[ "${now}" == "$3" ]]
}

option_is() {
  local now
  now=$(tmux show-option "$1" "$2" 2>/dev/null)
  [[ "${now}" == "$3" ]]
}

host_shows() {
  local screen
  screen=$(command tmux -S "${HOST}" capture-pane -p -t host)
  [[ "${screen}" == *"$1"* ]]
}

pane_shows() {
  local screen
  screen=$(tmux capture-pane -p -t "$1")
  [[ "${screen}" == *"$2"* ]]
}

file_is() {
  local now
  [[ -f "$1" ]] || return 1
  now=$(cat "$1")
  [[ "${now}" == "$2" ]]
}

everything() {
  tmux show-options -s
  tmux show-options -g
  tmux show-window-options -g
  tmux show-hooks -g
  tmux list-keys
}

setup() {
  ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  STUBS="${BATS_TEST_TMPDIR}/stubs"
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}" "${STUBS}"
  printf '#!/bin/sh\ncat >"%s.tmp"\nmv -f "%s.tmp" "%s"\n' "${BATS_TEST_TMPDIR}/clipboard" "${BATS_TEST_TMPDIR}/clipboard" "${BATS_TEST_TMPDIR}/clipboard" >"${STUBS}/wl-copy"
  chmod +x "${STUBS}/wl-copy"
  cp -f "${STUBS}/wl-copy" "${STUBS}/pbcopy"
  PATH="${STUBS}:${PATH}"
  setup_tmux_server
  HOST="${TMUX_SOCKET}-host"
  CONTROL="${TMUX_SOCKET}-control"
  tmux set-environment -g WAYLAND_DISPLAY wayland-test
  tmux set-environment -g TERM xterm-256color
  tmux set-environment -g TERM_PROGRAM none
  tmux set-environment -g EDITOR ed
  tmux set-environment -g VISUAL ed
  tmux set-environment -gr COLORTERM
  tmux set-environment -gr LC_TERMINAL
  tmux set-environment -gr XDG_CONFIG_HOME
  tmux set-option -g default-command "env PS1='$ ' sh"
  tmux respawn-pane -k -t test:0.0 "env PS1='$ ' sh"
  command tmux -S "${HOST}" -f /dev/null new-session -d -s host -x 100 -y 30 \
    "env -u TMUX TERM=xterm-256color tmux -S '${TMUX_SOCKET}' attach-session -t test"
  wait_for attached
}

teardown() {
  command tmux -S "${CONTROL}" kill-server 2>/dev/null || :
  command tmux -S "${HOST}" kill-server 2>/dev/null || :
  rm -f "${HOST}" "${CONTROL}"
  teardown_tmux_server
}

without_clipboard_tools() {
  local farm="${BATS_TEST_TMPDIR}/farm" dir name
  mkdir -p "${farm}"
  local IFS=:
  for dir in ${PATH}; do
    [[ -d "${dir}" ]] || continue
    [[ "${dir}" != "${STUBS}" ]] || continue
    ln -s "${dir}"/* "${farm}/" 2>/dev/null || :
  done
  unset IFS
  for name in wl-copy termux-clipboard-set pbcopy xclip xsel clip.exe; do
    rm -f "${farm:?}/${name}"
  done
  tmux set-environment -g PATH "${farm}"
}

load_plugin() {
  local quoted
  quoted=$(printf '%s' "${1:-${ROOT}}" | sed "s/'/'\\\\''/g")
  tmux run-shell "'${quoted}/sensible-revamped.tmux'"
}

setting() {
  set_option "@sensible_revamped_$1" "$2"
}

press() {
  local key
  for key in "$@"; do
    command tmux -S "${HOST}" send-keys -t host "${key}"
  done
}

tool() {
  # shellcheck disable=SC2086
  TMUX="${TMUX_SOCKET},1,0" run ${REVAMPED_TEST_SHELL:-sh} "${ROOT}/bin/sensible-revamped" "$@"
}

words() {
  tmux send-keys -t %0 "echo al''pha beta" Enter
  wait_for pane_shows %0 $'\nalpha beta'
  tmux copy-mode -t %0
  wait_for shows %0 '#{pane_in_mode}' 1
}

control_client() {
  command tmux -S "${CONTROL}" -f /dev/null new-session -d -s control -x 80 -y 24 \
    "env -u TMUX TERM=xterm-256color tmux -S '${TMUX_SOCKET}' -C attach-session -t test"
  wait_for controlled
}
