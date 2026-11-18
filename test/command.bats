#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
}

@test "command.sh - has_command is true for a command on PATH" {
  # Arrange
  local name=cat

  # Act
  lib_call command revamped_has_command "${name}"

  # Assert
  [[ "${status}" -eq 0 ]]
}

@test "command.sh - has_command is false for a missing command" {
  # Arrange
  local name=revamped-no-such-command

  # Act
  lib_call command revamped_has_command "${name}"

  # Assert
  [[ "${status}" -eq 1 ]]
}

@test "command.sh - the harness hides the tmux a test was started from" {
  # Arrange
  local name=TMUX_PANE

  # Act
  run printenv "${name}"

  # Assert
  [[ "${status}" -eq 1 ]]
}
