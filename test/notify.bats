#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
}

@test "notify.sh - backend is osascript on macOS when osascript exists" {
  # Arrange
  stub_command osascript
  stub_command notify-send
  harness_hide osascript notify-send
  export REVAMPED_TEST_UNAME_S=Darwin

  # Act
  lib_call notify revamped_notify_backend

  # Assert
  [[ "${output}" = "osascript" ]]
}

@test "notify.sh - backend is notify-send on Linux even when osascript exists" {
  # Arrange
  stub_command osascript
  stub_command notify-send
  harness_hide osascript notify-send
  export REVAMPED_TEST_UNAME_S=Linux

  # Act
  lib_call notify revamped_notify_backend

  # Assert
  [[ "${output}" = "notify-send" ]]
}

@test "notify.sh - backend is none without a notifier" {
  # Arrange
  harness_hide osascript notify-send
  export REVAMPED_TEST_UNAME_S=Linux

  # Act
  lib_call notify revamped_notify_backend

  # Assert
  [[ "${output}" = "none" ]]
}

@test "notify.sh - enabled is false while the option is unset" {
  # Arrange
  local option=@cpu_revamped_notify

  # Act
  lib_call notify revamped_notify_enabled "${option}"

  # Assert
  [[ "${status}" -eq 1 ]]
}

@test "notify.sh - enabled is true only for 1" {
  # Arrange
  tmux set-option -gq @cpu_revamped_notify 1

  # Act
  lib_call notify revamped_notify_enabled @cpu_revamped_notify

  # Assert
  [[ "${status}" -eq 0 ]]
}

@test "notify.sh - send passes quotes and backslashes to osascript as arguments" {
  # Arrange
  stub_command osascript
  harness_hide osascript notify-send
  export REVAMPED_TEST_UNAME_S=Darwin

  # Act
  lib_call notify revamped_notify_send 'Disk "x"' 'mount /Volumes/a\b "quoted"'

  # Assert
  actual="$(awk '{ line[NR] = $0 } END { print line[NR - 1] }' "${BATS_TEST_TMPDIR}/osascript.calls")"
  [[ "${actual}" = 'Disk "x"' ]]
  actual="$(sed -n '$p' "${BATS_TEST_TMPDIR}/osascript.calls")"
  [[ "${actual}" = 'mount /Volumes/a\b "quoted"' ]]
}

@test "notify.sh - send ends notify-send options before the title" {
  # Arrange
  stub_command notify-send
  harness_hide osascript notify-send
  export REVAMPED_TEST_UNAME_S=Linux

  # Act
  lib_call notify revamped_notify_send -title body

  # Assert
  expected="$(printf '%s\n%s\n%s' -- -title body)"
  actual="$(stub_calls notify-send)"
  [[ "${actual}" == "${expected}" ]]
}

@test "notify.sh - send succeeds with no notifier" {
  # Arrange
  harness_hide osascript notify-send
  export REVAMPED_TEST_UNAME_S=Linux

  # Act
  lib_call notify revamped_notify_send title body

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
}

@test "notify.sh - if enabled sends nothing while the option is off" {
  # Arrange
  stub_command notify-send
  harness_hide osascript notify-send
  export REVAMPED_TEST_UNAME_S=Linux

  # Act
  lib_call notify revamped_notify_if_enabled @cpu_revamped_notify title body

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ ! -e "${BATS_TEST_TMPDIR}/notify-send.calls" ]]
}

@test "notify.sh - if enabled sends once the option is 1" {
  # Arrange
  stub_command notify-send
  harness_hide osascript notify-send
  export REVAMPED_TEST_UNAME_S=Linux
  tmux set-option -gq @cpu_revamped_notify 1

  # Act
  lib_call notify revamped_notify_if_enabled @cpu_revamped_notify title body

  # Assert
  expected="$(printf '%s\n%s\n%s' -- title body)"
  actual="$(stub_calls notify-send)"
  [[ "${actual}" == "${expected}" ]]
}
