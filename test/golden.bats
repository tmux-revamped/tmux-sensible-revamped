#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  unset KODOUGU_THEME KODOUGU_ACCENT NO_COLOR SENSIBLE_REVAMPED_THEME SENSIBLE_REVAMPED_ACCENT
  export REVAMPED_TEST_TMUX_VERSION=3.8
}

transcript() {
  local flow="$1"
  shift
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/sensible-revamped" "$@"
  TRANSCRIPT="$(printf '$ sensible-revamped%s\n%s\nexit %s\n' "${*:+ $*}" "${output}" "${status}" | steady)"
  local system
  system="$(/usr/bin/uname -s)"
  case "${system}" in
  Darwin) system=darwin ;;
  *) system=linux ;;
  esac
  GOLDEN="${REVAMPED_TESTS_DIR}/golden/${flow}.${system}.txt"
  if [[ -n "${REVAMPED_TEST_RECORD:-}" ]]; then
    printf '%s\n' "${TRANSCRIPT}" >"${GOLDEN}"
  fi
}

steady() {
  sed -E \
    -e 's#/[^ ,]+#<path>#g' \
    -e 's/(gnu|bsd|uutils|busybox|mawk)( [0-9][0-9.]*)?$/<flavor>/' \
    -e 's/^sensible-revamped [0-9]+\.[0-9]+\.[0-9]+$/sensible-revamped <version>/'
}

@test "golden - help" {
  # Arrange
  local flow=help

  # Act
  transcript "${flow}" help

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - version" {
  # Arrange
  local flow=version

  # Act
  transcript "${flow}" version

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - doctor" {
  # Arrange
  local flow=doctor
  harness_hide wl-copy termux-clipboard-set pbcopy xclip xsel clip.exe

  # Act
  transcript "${flow}" doctor

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - an unknown command" {
  # Arrange
  local flow=unknown-command

  # Act
  transcript "${flow}" frobnicate

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - an unknown option" {
  # Arrange
  local flow=unknown-option

  # Act
  transcript "${flow}" --frobnicate

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - a bare run without a terminal" {
  # Arrange
  local flow=no-terminal

  # Act
  transcript "${flow}"

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}
