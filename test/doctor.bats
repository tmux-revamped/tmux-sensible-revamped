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

@test "doctor - the grep of macOS, which calls itself GNU compatible, reads as bsd with its version" {
  # Arrange
  local text="grep (BSD grep, GNU compatible) 2.6.0-FreeBSD"

  # Act
  flavor plain "${text}"

  # Assert
  [[ "${output}" == "bsd 2.6.0" ]]
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

@test "doctor - the settings row names each value outside what its kind lists" {
  # Arrange
  local script='kinds=$(printf "edges\ton off\nmode\tswap insert\ntimeout\tnumber\nwidth\tnumber 1 200"); values=$(printf "edges\tyes\nmode\tswap\ntimeout\t10s\nwidth\t0\nmenu_key\tM-x\nlive\t"); revamped_doctor_settings "${kinds}" "${values}"'

  # Act
  lib_run doctor "${script}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "settings           warn     unknown values: edges=yes timeout=10s width=0" ]]
}

@test "doctor - the settings row is ok for known words, numbers in range with leading zeros, empty values and settings of no kind" {
  # Arrange
  local script='kinds=$(printf "edges\ton off\nmode\tswap insert\ntimeout\tnumber\nwidth\tnumber 1 200"); values=$(printf "edges\toff\nmode\tinsert\ntimeout\t007\nwidth\t0200\nmenu_key\tanything at all\nlive\t\nno-separator"); revamped_doctor_settings "${kinds}" "${values}"'

  # Act
  lib_run doctor "${script}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "settings           ok       every option holds a value it knows" ]]
}

@test "doctor - a number above its range, or under a lower bound given alone, is named" {
  # Arrange
  local script='revamped_doctor_settings "$(printf "width\tnumber 1 200\nspeed\tnumber 1\nlines\tnumber 1")" "$(printf "width\t201\nspeed\t0\nlines\t90000")"'

  # Act
  lib_run doctor "${script}"

  # Assert
  [[ "${output}" == "settings           warn     unknown values: width=201 speed=0" ]]
}
