#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  unset KODOUGU_THEME KODOUGU_ACCENT NO_COLOR
}

fake_tool() {
  local dir="${BATS_TEST_TMPDIR}/$1"
  mkdir -p "${dir}"
  printf '#!/usr/bin/env python3\nprint("%s")\n' "$2" >"${dir}/tool"
  chmod +x "${dir}/tool"
  printf '%s\n' "${dir}/tool"
}

flavor() {
  local tool
  tool=$(fake_tool "$1" "$2")
  lib_call doctor revamped_doctor_flavor "${tool}"
}

@test "doctor - a GNU tool reads as gnu with its version" {
  # Arrange
  local text="sed (GNU sed) 4.10"

  # Act
  flavor plain "${text}"

  # Assert
  [[ "${output}" == "gnu 4.10" ]]
}

@test "doctor - a uutils tool reads as uutils" {
  # Arrange
  local text="tr (uutils coreutils) 0.10.0"

  # Act
  flavor plain "${text}"

  # Assert
  [[ "${output}" == "uutils 0.10.0" ]]
}

@test "doctor - a BusyBox banner reads as busybox with its version" {
  # Arrange
  local text="BusyBox v1.37.0 (2026-01-01) multi-call binary."

  # Act
  flavor plain "${text}"

  # Assert
  [[ "${output}" == "busybox 1.37.0" ]]
}

@test "doctor - a tool that says it is not GNU reads as busybox without a version" {
  # Arrange
  local text="date: This is not GNU date 1.2"

  # Act
  flavor plain "${text}"

  # Assert
  [[ "${output}" == "busybox" ]]
}

@test "doctor - mawk reads as mawk" {
  # Arrange
  local text="mawk 1.3.4 20250131"

  # Act
  flavor plain "${text}"

  # Assert
  [[ "${output}" == "mawk 1.3.4" ]]
}

@test "doctor - the one true awk reads as bsd" {
  # Arrange
  local text="awk version 20200816"

  # Act
  flavor plain "${text}"

  # Assert
  [[ "${output}" == "bsd 20200816" ]]
}

@test "doctor - a silent tool under a cargo folder reads as uutils" {
  # Arrange
  local text=""

  # Act
  flavor cargo "${text}"

  # Assert
  [[ "${output}" == "uutils" ]]
}

@test "doctor - a silent tool on macOS reads as bsd" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Darwin

  # Act
  flavor plain ""

  # Assert
  [[ "${output}" == "bsd" ]]
}

@test "doctor - a silent tool on Linux reads as unknown" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Linux

  # Act
  flavor plain ""

  # Assert
  [[ "${output}" == "unknown" ]]
}

@test "doctor - a warn row is drawn in the warning colour where gum draws" {
  # Arrange
  export REVAMPED_TEST_GUM=1 REVAMPED_TEST_GUM_LOG="${BATS_TEST_TMPDIR}/gum.log"
  harness_hide osascript notify-send

  # Act
  lib_run cli 'revamped_cli_start "" && . "${REVAMPED_LIB}/doctor.sh" && revamped_doctor_notifier && printf "%s" "${REVAMPED_DOCTOR_ROWS}"'

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "notifier	@warn:warn	no osascript"* ]]
}

@test "doctor - the notifier row names the backend it would use" {
  # Arrange
  stub_command osascript
  stub_command notify-send
  harness_hide osascript notify-send
  export REVAMPED_TEST_UNAME_S=Linux

  # Act
  lib_run cli 'revamped_cli_start "" && . "${REVAMPED_LIB}/doctor.sh" && revamped_doctor_notifier && printf "%s" "${REVAMPED_DOCTOR_ROWS}"'

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "notifier           ok       notify-send" ]]
}
