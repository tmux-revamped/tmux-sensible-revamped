#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

@test "keys - prefix C-n and prefix C-p move to the next and the previous window" {
  # Arrange
  load_plugin
  tmux new-window -d -t test:
  tmux new-window -d -t test:
  tmux select-window -t test:0

  # Act
  press C-b C-n

  # Assert
  wait_for shows test: '#{window_index}' 1
  press C-b C-p
  wait_for shows test: '#{window_index}' 0
}

@test "keys - the last-window key goes back to the window before" {
  # Arrange
  setting last_window_key a
  load_plugin
  tmux new-window -d -t test:
  tmux new-window -d -t test:
  tmux select-window -t test:2
  tmux select-window -t test:0

  # Act
  press C-b a

  # Assert
  wait_for shows test: '#{window_index}' 2
}

@test "keys - the reload key sources the config again and says so" {
  # Arrange
  printf 'set -g @reloaded yes\n' >"${HOME}/.tmux.conf"
  setting reload_key R
  load_plugin

  # Act
  press C-b R

  # Assert
  wait_for option_is -gqv @reloaded yes
  wait_for host_shows "tmux-sensible-revamped: reloaded"
}

@test "keys - a key the person bound keeps their command, and doctor names it" {
  # Arrange
  tmux bind-key C-p set-option -g @mine yes
  load_plugin

  # Act
  press C-b C-p

  # Assert
  wait_for option_is -gqv @mine yes
  tool doctor
  [[ "${output}" =~ keys\ +warn\ +already\ bound\ and\ left\ alone:\ C-p ]]
}

@test "keys - with keys off the window keys stay unbound" {
  # Arrange
  local keys
  setting keys off
  setting reload_key R

  # Act
  load_plugin

  # Assert
  keys=$(prefix_keys)
  run grep -c -x -e 'C-p' -e 'C-n' -e 'R' <<<"${keys}"
  [[ "${output}" == "0" ]]
}

@test "keys - a custom prefix pressed twice reaches the app" {
  # Arrange
  tmux set-option -g prefix C-a
  load_plugin
  tmux respawn-pane -k -t %0 "cat -v"

  # Act
  press C-a C-a

  # Assert
  wait_for pane_shows %0 '^A'
}

@test "keys - in vi copy-mode v selects and y copies to the clipboard tool and leaves" {
  # Arrange
  tmux set-environment -g EDITOR vim
  load_plugin
  words

  # Act
  press k 0 v e y

  # Assert
  wait_for file_is "${BATS_TEST_TMPDIR}/clipboard" alpha
  wait_for shows %0 '#{pane_in_mode}' 0
}

@test "keys - in vi copy-mode Enter copies the selection too" {
  # Arrange
  tmux set-environment -g EDITOR vim
  load_plugin
  words

  # Act
  press k 0 w v e Enter

  # Assert
  wait_for file_is "${BATS_TEST_TMPDIR}/clipboard" beta
  wait_for shows %0 '#{pane_in_mode}' 0
}

@test "keys - in vi copy-mode C-v switches to a rectangle selection" {
  # Arrange
  tmux set-environment -g EDITOR vim
  load_plugin
  words

  # Act
  press v C-v

  # Assert
  wait_for shows %0 '#{rectangle_toggle}' 1
}

@test "keys - in emacs copy-mode M-w copies the selection to the clipboard tool" {
  # Arrange
  load_plugin
  words

  # Act
  press C-p C-a C-Space M-f M-w

  # Assert
  wait_for file_is "${BATS_TEST_TMPDIR}/clipboard" alpha
  wait_for shows %0 '#{pane_in_mode}' 0
}

@test "keys - a mouse drag in vi copy-mode ends in the clipboard tool" {
  # Arrange
  tmux set-environment -g EDITOR vim
  tmux set-option -g mouse on
  load_plugin
  words

  # Act
  command tmux -S "${HOST}" send-keys -t host -l $'\e[<0;1;2M\e[<32;3;2M\e[<32;5;2M\e[<0;5;2m'

  # Assert
  wait_for file_is "${BATS_TEST_TMPDIR}/clipboard" alpha
  wait_for shows %0 '#{pane_in_mode}' 0
}

@test "keys - a mouse drag in emacs copy-mode ends in the clipboard tool" {
  # Arrange
  tmux set-option -g mouse on
  load_plugin
  words

  # Act
  command tmux -S "${HOST}" send-keys -t host -l $'\e[<0;7;2M\e[<32;8;2M\e[<32;11;2M\e[<0;11;2m'

  # Assert
  wait_for file_is "${BATS_TEST_TMPDIR}/clipboard" beta
  wait_for shows %0 '#{pane_in_mode}' 0
}

@test "keys - without a clipboard tool y still copies, into a tmux buffer" {
  # Arrange
  local buffer
  without_clipboard_tools
  tmux set-environment -g EDITOR vim
  load_plugin
  words

  # Act
  press k 0 v e y

  # Assert
  wait_for shows %0 '#{pane_in_mode}' 0
  buffer=$(tmux show-buffer)
  [[ "${buffer}" == "alpha" ]]
}
