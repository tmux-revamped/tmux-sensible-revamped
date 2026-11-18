#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

@test "entrypoint - git tracks the entry point and the tool as executable" {
  # Arrange
  local modes

  # Act
  modes=$(git -C "${ROOT}" ls-files --stage -- sensible-revamped.tmux bin/sensible-revamped)

  # Assert
  run awk '$1 != "100755" { bad++ } END { print NR ":" bad + 0 }' <<<"${modes}"
  [[ "${output}" == "2:0" ]]
}

@test "entrypoint - loading sets the defaults on a stock server" {
  # Arrange
  local features

  # Act
  load_plugin

  # Assert
  option_is -gqv history-limit 50000
  option_is -sqv escape-time 10
  option_is -gqv focus-events on
  option_is -gqv set-clipboard on
  option_is -gqv display-time 4000
  option_is -gqv status-interval 5
  option_is -gqv base-index 1
  option_is -wgqv pane-base-index 1
  option_is -gqv renumber-windows on
  option_is -wgqv word-separators " "
  option_is -wgqv mode-keys emacs
  option_is -wgqv aggressive-resize on
  option_is -sqv extended-keys on
  features=$(tmux show-option -sqv terminal-features)
  [[ "${features}" == *"*:clipboard:ccolour:cstyle:focus:title"* ]]
  [[ "${features}" == *"xterm*:extkeys"* ]]
}

@test "entrypoint - loading twice changes nothing" {
  # Arrange
  local before after
  load_plugin
  before=$(everything)

  # Act
  load_plugin

  # Assert
  after=$(everything)
  [[ "${after}" == "${before}" ]]
}

@test "entrypoint - options the person set before loading are left alone" {
  # Arrange
  tmux set-option -g history-limit 9000
  tmux set-option -s escape-time 0
  tmux set-option -g base-index 3
  tmux set-window-option -g mode-keys vi
  tmux set-option -g status-keys vi

  # Act
  load_plugin

  # Assert
  option_is -gqv history-limit 9000
  option_is -sqv escape-time 0
  option_is -gqv base-index 3
  option_is -wgqv mode-keys vi
  option_is -gqv status-keys vi
}

@test "entrypoint - a truecolor terminal gets the RGB feature, and a vi editor the vi keys" {
  # Arrange
  local features
  tmux set-environment -g COLORTERM truecolor
  tmux set-environment -g EDITOR nvim

  # Act
  load_plugin

  # Assert
  features=$(tmux show-option -sqv terminal-features)
  [[ "${features}" == *"*:RGB"* ]]
  option_is -wgqv mode-keys vi
}

@test "entrypoint - a control-mode client turns aggressive-resize off, and its leaving puts it back, from a checkout path with a space, a quote and a hash" {
  # Arrange
  local copy="${BATS_TEST_TMPDIR}/it's #1 dir"
  mkdir -p "${copy}"
  cp -Rf "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/sensible-revamped.tmux" "${copy}/"
  load_plugin "${copy}"
  option_is -wgqv aggressive-resize on

  # Act
  control_client

  # Assert
  wait_for option_is -wgqv aggressive-resize off
  wait_for option_is -gqv @sensible_revamped_resize_saved on
  command tmux -S "${CONTROL}" kill-server
  wait_for uncontrolled
  wait_for option_is -wgqv aggressive-resize on
  wait_for option_is -gqv @sensible_revamped_resize_saved ""
}

@test "entrypoint - list prints the commands for the live server and doctor passes on it" {
  # Arrange
  load_plugin

  # Act
  tool list

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"set-hook -g client-attached[1000] run-shell -b "* ]]
  [[ "${output}" != *"history-limit"* ]]
  tool doctor
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ keys\ +ok ]]
}
