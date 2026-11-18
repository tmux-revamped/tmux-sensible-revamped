#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  export REVAMPED_TEST_UNAME_LOG="${BATS_TEST_TMPDIR}/uname.log"
}

@test "platform.sh - os reports what uname -s says" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Linux

  # Act
  lib_call platform revamped_platform_os

  # Assert
  [[ "${output}" = "Linux" ]]
}

@test "platform.sh - arch reports what uname -m says" {
  # Arrange
  export REVAMPED_TEST_UNAME_M=aarch64

  # Act
  lib_call platform revamped_platform_arch

  # Assert
  [[ "${output}" = "aarch64" ]]
}

@test "platform.sh - os reports unknown when uname fails" {
  # Arrange
  export REVAMPED_TEST_UNAME_FAIL=1

  # Act
  lib_call platform revamped_platform_os

  # Assert
  [[ "${output}" = "unknown" ]]
}

@test "platform.sh - macOS is Darwin and nothing else" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Darwin

  # Act
  lib_run platform 'revamped_is_macos && ! revamped_is_linux && ! revamped_is_bsd'

  # Assert
  [[ "${status}" -eq 0 ]]
}

@test "platform.sh - Linux is Linux and nothing else" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Linux

  # Act
  lib_run platform 'revamped_is_linux && ! revamped_is_macos && ! revamped_is_bsd'

  # Assert
  [[ "${status}" -eq 0 ]]
}

@test "platform.sh - FreeBSD counts as BSD" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=FreeBSD

  # Act
  lib_call platform revamped_is_bsd

  # Assert
  [[ "${status}" -eq 0 ]]
}

@test "platform.sh - DragonFly counts as BSD" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=DragonFly

  # Act
  lib_call platform revamped_is_bsd

  # Assert
  [[ "${status}" -eq 0 ]]
}

@test "platform.sh - Apple Silicon is Darwin on arm64" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Darwin REVAMPED_TEST_UNAME_M=arm64

  # Act
  lib_call platform revamped_is_apple_silicon

  # Assert
  [[ "${status}" -eq 0 ]]
}

@test "platform.sh - Intel Darwin is not Apple Silicon" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Darwin REVAMPED_TEST_UNAME_M=x86_64

  # Act
  lib_call platform revamped_is_apple_silicon

  # Assert
  [[ "${status}" -eq 1 ]]
}

@test "platform.sh - Linux on arm64 is not Apple Silicon" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Linux REVAMPED_TEST_UNAME_M=aarch64

  # Act
  lib_call platform revamped_is_apple_silicon

  # Assert
  [[ "${status}" -eq 1 ]]
}

@test "platform.sh - repeated checks run uname once per field" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Linux REVAMPED_TEST_UNAME_M=x86_64

  # Act
  lib_run platform 'revamped_is_macos; revamped_is_linux; revamped_is_bsd; revamped_is_apple_silicon; revamped_platform_os'

  # Assert
  actual="$(count_matching '^-s$' "${REVAMPED_TEST_UNAME_LOG}")"
  [[ "${actual}" -eq 1 ]]
  actual="$(count_matching '^-m$' "${REVAMPED_TEST_UNAME_LOG}")"
  [[ "${actual}" -eq 1 ]]
}
