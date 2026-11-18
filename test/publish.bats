#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  export REVAMPED_TEST_TMUX_ARGV="${BATS_TEST_TMPDIR}/argv"
}

sent() {
  cat "${REVAMPED_TEST_TMUX_ARGV}"
}

@test "publish.sh - pad left-pads a value to the width" {
  # Arrange
  local value=9%

  # Act
  lib_call publish revamped_publish_pad "${value}" 4

  # Assert
  [[ "${output}" = "  9%" ]]
}

@test "publish.sh - pad counts a multibyte character once" {
  # Arrange
  local value=45°C

  # Act
  lib_call publish revamped_publish_pad "${value}" 5

  # Assert
  [[ "${output}" = " 45°C" ]]
}

@test "publish.sh - pad with zero width returns the value unchanged" {
  # Arrange
  local value=9%

  # Act
  lib_call publish revamped_publish_pad "${value}" 0

  # Assert
  [[ "${output}" = "9%" ]]
}

@test "publish.sh - pad never cuts a wider value" {
  # Arrange
  local value=100%

  # Act
  lib_call publish revamped_publish_pad "${value}" 2

  # Assert
  [[ "${output}" = "100%" ]]
}

@test "publish.sh - pad treats a non-numeric width as zero" {
  # Arrange
  local value=9%

  # Act
  lib_call publish revamped_publish_pad "${value}" wide

  # Assert
  [[ "${output}" = "9%" ]]
}

@test "publish.sh - chars counts characters, not bytes" {
  # Arrange
  local value=°C

  # Act
  lib_call publish revamped_publish_chars "${value}"

  # Assert
  [[ "${output}" = "2" ]]
}

@test "publish.sh - chars counts a character whose later bytes are below 0xA0 once" {
  # Arrange
  local script='for word in "Größe" "日本" "naïve ß 日"; do revamped_publish_count "${word}"; printf "[%s]" "${revamped_publish_count_out}"; done'

  # Act
  lib_run publish "${script}"

  # Assert
  [[ "${output}" == "[5][2][9]" ]]
}

@test "publish.sh - chars keeps the caller's locale" {
  # Arrange
  export LC_ALL=POSIX

  # Act
  lib_run publish 'revamped_publish_chars ab >/dev/null; printf "%s\n" "${LC_ALL}"'

  # Assert
  [[ "${output}" = "POSIX" ]]
}

@test "publish.sh - chars leaves LC_ALL unset when the caller had none" {
  # Arrange
  unset LC_ALL

  # Act
  lib_run publish 'revamped_publish_chars ab >/dev/null; printf "%s\n" "${LC_ALL-unset}"'

  # Assert
  [[ "${output}" = "unset" ]]
}

@test "publish.sh - chars and escape need no external command" {
  # Arrange
  harness_hide tr wc awk sed cut

  # Act
  lib_run publish 'revamped_publish_chars 45°C; printf " "; revamped_publish_escape "#x"'

  # Assert
  [[ "${output}" = "4 ##x" ]]
}

@test "publish.sh - width is zero by default" {
  # Arrange
  local natural=4

  # Act
  lib_call publish revamped_publish_width cpu_revamped percentage "${natural}"

  # Assert
  [[ "${output}" = "0" ]]
}

@test "publish.sh - fixed width uses the natural maximum" {
  # Arrange
  tmux set-option -gq @cpu_revamped_fixed_width on

  # Act
  lib_call publish revamped_publish_width cpu_revamped percentage 4

  # Assert
  [[ "${output}" = "4" ]]
}

@test "publish.sh - a metric width overrides fixed width" {
  # Arrange
  tmux set-option -gq @cpu_revamped_fixed_width on
  tmux set-option -gq @cpu_revamped_percentage_width 3

  # Act
  lib_call publish revamped_publish_width cpu_revamped percentage 4

  # Assert
  [[ "${output}" = "3" ]]
}

@test "publish.sh - a non-numeric metric width falls back to fixed width" {
  # Arrange
  tmux set-option -gq @cpu_revamped_fixed_width on
  tmux set-option -gq @cpu_revamped_percentage_width wide

  # Act
  lib_call publish revamped_publish_width cpu_revamped percentage 4

  # Assert
  [[ "${output}" = "4" ]]
}

@test "publish.sh - escape doubles every hash so tmux prints it literally" {
  # Arrange
  local value='#[fg=red]#(id)#'

  # Act
  lib_call publish revamped_publish_escape "${value}"

  # Assert
  [[ "${output}" = '##[fg=red]##(id)##' ]]
}

@test "publish.sh - commit sends every option in one call" {
  # Arrange
  local script='revamped_publish_add @a 1; revamped_publish_add @b 2%; revamped_publish_commit'

  # Act
  lib_run publish "${script}"

  # Assert
  actual="$(sent)"
  [[ "${actual}" = "set-option|-gq|@a|1|;|set-option|-gq|@b|2%%" ]]
}

@test "publish.sh - a pane value targets that pane" {
  # Arrange
  local script='revamped_publish_add @a 1 %3; revamped_publish_commit'

  # Act
  lib_run publish "${script}"

  # Assert
  actual="$(sent)"
  [[ "${actual}" = "set-option|-pq|-t|%3|@a|1" ]]
}

@test "publish.sh - commit refreshes every attached client" {
  # Arrange
  printf '/dev/ttys001\n/dev/ttys002\n' >"${REVAMPED_TEST_TMUX_DIR}/clients"

  # Act
  lib_run publish 'revamped_publish_add @a 1; revamped_publish_commit'

  # Assert
  actual="$(sent)"
  [[ "${actual}" = "set-option|-gq|@a|1|;|refresh-client|-S|-t|/dev/ttys001|;|refresh-client|-S|-t|/dev/ttys002" ]]
}

@test "publish.sh - commit with nothing pending sends nothing" {
  # Arrange
  local script=revamped_publish_commit

  # Act
  lib_run publish "${script}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ ! -e "${REVAMPED_TEST_TMUX_ARGV}" ]]
}

@test "publish.sh - commit empties the batch" {
  # Arrange
  local script='revamped_publish_add @a 1; revamped_publish_commit; revamped_publish_commit'

  # Act
  lib_run publish "${script}"

  # Assert
  actual="$(sent)"
  [[ "${actual}" = "set-option|-gq|@a|1" ]]
}

@test "publish.sh - an empty value stays an argument" {
  # Arrange
  local script='revamped_publish_add @a ""; revamped_publish_add @b 2; revamped_publish_commit'

  # Act
  lib_run publish "${script}"

  # Assert
  actual="$(sent)"
  [[ "${actual}" = "set-option|-gq|@a||;|set-option|-gq|@b|2" ]]
}

@test "publish.sh - a newline inside a value becomes a space" {
  # Arrange
  local script='revamped_publish_add_raw @a "one
two"; revamped_publish_commit'

  # Act
  lib_run publish "${script}"

  # Assert
  actual="$(sent)"
  [[ "${actual}" = "set-option|-gq|@a|one two" ]]
}

@test "publish.sh - a trailing semicolon is escaped" {
  # Arrange
  local script='revamped_publish_add_raw @a "x;"; revamped_publish_commit'

  # Act
  lib_run publish "${script}"

  # Assert
  actual="$(sent)"
  [[ "${actual}" = 'set-option|-gq|@a|x\;' ]]
}

@test "publish.sh - a semicolon inside a value is kept" {
  # Arrange
  local script='revamped_publish_add_raw @a "a;b"; revamped_publish_commit'

  # Act
  lib_run publish "${script}"

  # Assert
  actual="$(sent)"
  [[ "${actual}" = "set-option|-gq|@a|a;b" ]]
}

@test "publish.sh - a displayed value doubles its percent signs" {
  # Arrange
  local script='revamped_publish_add @a "100%#[fg=red]"; revamped_publish_commit'

  # Act
  lib_run publish "${script}"

  # Assert
  actual="$(sent)"
  [[ "${actual}" = "set-option|-gq|@a|100%%#[fg=red]" ]]
}

@test "publish.sh - a raw value keeps its percent signs" {
  # Arrange
  local script='revamped_publish_add_raw @a 100%; revamped_publish_commit'

  # Act
  lib_run publish "${script}"

  # Assert
  actual="$(sent)"
  [[ "${actual}" = "set-option|-gq|@a|100%" ]]
}
