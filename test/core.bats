#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
}

@test "core.sh - loading twice keeps the version readable" {
  # Arrange
  local script='. "${REVAMPED_LIB}/core.sh"; printf "%s\n" "${SENSIBLE_REVAMPED_VERSION}"'

  # Act
  lib_run core "${script}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}
