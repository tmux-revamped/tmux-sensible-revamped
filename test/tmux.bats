#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
}

@test "tmux.sh - get returns the default for an unset option" {
  # Arrange
  local option=@absent

  # Act
  lib_call tmux revamped_tmux_get "${option}" fallback

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" = "fallback" ]]
  expected="$(printf 'show-option -gqv @absent\nshow-option -gq @absent')"
  actual="$(tmux_calls)"
  [[ "${actual}" == "${expected}" ]]
}

@test "tmux.sh - get returns a set value with one query" {
  # Arrange
  tmux set-option -gq @set value

  # Act
  lib_call tmux revamped_tmux_get @set fallback

  # Assert
  [[ "${output}" = "value" ]]
  actual="$(sed -n '$p' "${REVAMPED_TEST_TMUX_LOG}")"
  [[ "${actual}" = "show-option -gqv @set" ]]
}

@test "tmux.sh - get keeps an option explicitly set to empty" {
  # Arrange
  tmux set-option -gq @empty ""

  # Act
  lib_call tmux revamped_tmux_get @empty fallback

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" = "" ]]
}

@test "tmux.sh - get with no default queries once" {
  # Arrange
  local option=@absent

  # Act
  lib_call tmux revamped_tmux_get "${option}"

  # Assert
  [[ "${output}" = "" ]]
  actual="$(tmux_calls)"
  [[ "${actual}" = "show-option -gqv @absent" ]]
}

@test "tmux.sh - set then get round-trips the value" {
  # Arrange
  lib_call tmux revamped_tmux_set @foo bar

  # Act
  lib_call tmux revamped_tmux_get @foo other

  # Assert
  [[ "${output}" = "bar" ]]
}

@test "tmux.sh - unset removes the option" {
  # Arrange
  tmux set-option -gq @foo bar

  # Act
  lib_call tmux revamped_tmux_unset @foo

  # Assert
  [[ "${status}" -eq 0 ]]
  actual="$(tmux show-option -gqv @foo)"
  [[ -z "${actual}" ]]
}

@test "tmux.sh - a window option round-trips and falls back" {
  # Arrange
  lib_call tmux revamped_tmux_set_window @win value

  # Act
  lib_call tmux revamped_tmux_get_window @win fallback

  # Assert
  [[ "${output}" = "value" ]]
}

@test "tmux.sh - an unset window option falls back to the default" {
  # Arrange
  local option=@win

  # Act
  lib_call tmux revamped_tmux_get_window "${option}" fallback

  # Assert
  [[ "${output}" = "fallback" ]]
}

@test "tmux.sh - a pane option round-trips without a target" {
  # Arrange
  lib_call tmux revamped_tmux_set_pane @pane value

  # Act
  lib_call tmux revamped_tmux_get_pane @pane fallback

  # Assert
  [[ "${output}" = "value" ]]
}

@test "tmux.sh - a pane option round-trips with a target" {
  # Arrange
  lib_call tmux revamped_tmux_set_pane @pane other %1

  # Act
  lib_call tmux revamped_tmux_get_pane @pane fallback %1

  # Assert
  [[ "${output}" = "other" ]]
  actual="$(sed -n '$p' "${REVAMPED_TEST_TMUX_LOG}")"
  [[ "${actual}" = "show-option -pqv -t %1 @pane" ]]
}

@test "tmux.sh - current pane asks for the pane id" {
  # Arrange
  tmux_answer '#{pane_id}' %3

  # Act
  lib_call tmux revamped_tmux_current_pane

  # Assert
  [[ "${output}" = "%3" ]]
  actual="$(tmux_calls)"
  [[ "${actual}" = "display-message -p #{pane_id}" ]]
}

@test "tmux.sh - current window asks for the window id" {
  # Arrange
  tmux_answer '#{window_id}' @2

  # Act
  lib_call tmux revamped_tmux_current_window

  # Assert
  [[ "${output}" = "@2" ]]
}

@test "tmux.sh - pane count reads the window's pane count" {
  # Arrange
  tmux_answer '#{window_panes}' 2

  # Act
  lib_call tmux revamped_tmux_pane_count

  # Assert
  [[ "${output}" = "2" ]]
  actual="$(tmux_calls)"
  [[ "${actual}" = "display-message -p #{window_panes}" ]]
}

@test "tmux.sh - pane width passes the target pane" {
  # Arrange
  tmux_answer '#{pane_width}' 80 %1

  # Act
  lib_call tmux revamped_tmux_pane_width %1

  # Assert
  [[ "${output}" = "80" ]]
  actual="$(tmux_calls)"
  [[ "${actual}" = "display-message -p -t %1 #{pane_width}" ]]
}

@test "tmux.sh - pane height without a target reads the current pane" {
  # Arrange
  tmux_answer '#{pane_height}' 24

  # Act
  lib_call tmux revamped_tmux_pane_height

  # Assert
  [[ "${output}" = "24" ]]
}

@test "tmux.sh - window width reads the window" {
  # Arrange
  tmux_answer '#{window_width}' 200

  # Act
  lib_call tmux revamped_tmux_window_width

  # Assert
  [[ "${output}" = "200" ]]
}

@test "tmux.sh - window height reads the window" {
  # Arrange
  tmux_answer '#{window_height}' 50

  # Act
  lib_call tmux revamped_tmux_window_height

  # Assert
  [[ "${output}" = "50" ]]
}

@test "tmux.sh - a failing display-message falls back to zero" {
  # Arrange
  export REVAMPED_TEST_TMUX_FAIL=1

  # Act
  lib_call tmux revamped_tmux_pane_width %1

  # Assert
  [[ "${output}" = "0" ]]
}

@test "tmux stub - display-message expands the options a test stored" {
  # Arrange
  printf 'a, b' >"${REVAMPED_TEST_TMUX_DIR}/g.-._x"
  printf 'line one\nline two' >"${REVAMPED_TEST_TMUX_DIR}/g.-._y"

  # Act
  run tmux display-message -p '[#{@x}|#{@missing}|#{@y}]'

  # Assert
  [[ "${output}" == $'[a, b||line one\nline two]' ]]
}
