#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  export REVAMPED_LOG_NS=test-rev
  export REVAMPED_LOG_DIR="${BATS_TEST_TMPDIR}/logs"
  export REVAMPED_LOG_FILE="${REVAMPED_LOG_DIR}/test.log"
  export REVAMPED_TEST_TIMESTAMP="2026-01-15 14:30:00"
}

@test "log.sh - an empty message writes nothing" {
  # Arrange
  tmux set-option -gq @test_rev_enable_logging 1

  # Act
  lib_call log revamped_log_error comp ""

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ ! -e "${REVAMPED_LOG_FILE}" ]]
}

@test "log.sh - nothing is written while logging is off" {
  # Arrange
  local message=hello

  # Act
  lib_call log revamped_log_error comp "${message}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ ! -e "${REVAMPED_LOG_FILE}" ]]
}

@test "log.sh - an enabled log gets one stamped line" {
  # Arrange
  tmux set-option -gq @test_rev_enable_logging 1

  # Act
  lib_call log revamped_log_error startup "hello world"

  # Assert
  actual="$(cat "${REVAMPED_LOG_FILE}")"
  [[ "${actual}" = "[2026-01-15 14:30:00] [startup] hello world" ]]
}

@test "log.sh - the component keeps only letters, digits, dashes and underscores" {
  # Arrange
  tmux set-option -gq @test_rev_enable_logging 1

  # Act
  lib_call log revamped_log_error "bad;rm /" msg

  # Assert
  actual="$(cat "${REVAMPED_LOG_FILE}")"
  [[ "${actual}" = "[2026-01-15 14:30:00] [badrm] msg" ]]
}

@test "log.sh - a log past its size keeps only its newest lines" {
  # Arrange
  tmux set-option -gq @test_rev_enable_logging 1
  export REVAMPED_LOG_MAX_SIZE=10 REVAMPED_LOG_MAX_LINES=2
  mkdir -p "${REVAMPED_LOG_DIR}"
  printf 'l1\nl2\nl3\nl4\nl5\n' >"${REVAMPED_LOG_FILE}"

  # Act
  lib_call log revamped_log_error comp trigger

  # Assert
  expected="$(printf '%s\n%s' l5 '[2026-01-15 14:30:00] [comp] trigger')"
  actual="$(cat "${REVAMPED_LOG_FILE}")"
  [[ "${actual}" == "${expected}" ]]
}

@test "log.sh - a log within its size is left whole" {
  # Arrange
  tmux set-option -gq @test_rev_enable_logging 1
  mkdir -p "${REVAMPED_LOG_DIR}"
  printf 'l1\nl2\n' >"${REVAMPED_LOG_FILE}"

  # Act
  lib_call log revamped_log_error comp trigger

  # Assert
  actual="$(grep -c '' "${REVAMPED_LOG_FILE}")"
  [[ "${actual}" -eq 3 ]]
}

@test "log.sh - an unwritable log folder writes nothing and succeeds" {
  # Arrange
  tmux set-option -gq @test_rev_enable_logging 1
  export REVAMPED_LOG_DIR=/dev/null/logs REVAMPED_LOG_FILE=/dev/null/logs/test.log

  # Act
  lib_call log revamped_log_error comp msg

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
}

@test "log.sh - the option name comes from the namespace" {
  # Arrange
  unset REVAMPED_LOG_OPTION

  # Act
  lib_run log 'printf "%s\n" "${REVAMPED_LOG_OPTION}"'

  # Assert
  [[ "${output}" = "@test_rev_enable_logging" ]]
}

@test "log.sh - an unreadable size leaves the log whole" {
  # Arrange
  tmux set-option -gq @test_rev_enable_logging 1
  export REVAMPED_LOG_MAX_SIZE=1
  mkdir -p "${REVAMPED_LOG_DIR}" "${BATS_TEST_TMPDIR}/stubs"
  printf 'l1\nl2\n' >"${REVAMPED_LOG_FILE}"
  printf '#!/bin/sh\nprintf "garbage\\n"\n' >"${BATS_TEST_TMPDIR}/stubs/stat"
  chmod +x "${BATS_TEST_TMPDIR}/stubs/stat"

  # Act
  lib_call log revamped_log_error comp trigger

  # Assert
  actual="$(count_matching '' "${REVAMPED_LOG_FILE}")"
  [[ "${actual}" -eq 3 ]]
}
