#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  REAL_SLEEP="$(command -v sleep)"
  stub_command sleep
  TICK_LOG="${BATS_TEST_TMPDIR}/ticks"
  export TICK_LOG
}

ticks() {
  if [[ -f "${TICK_LOG}" ]]; then
    grep -c '^tick$' "${TICK_LOG}"
  else
    printf '0'
  fi
}

stored() {
  tmux show-option -gqv "$1"
}

store() {
  tmux set-option -gq "$1" "$2"
}

tick_snippet() {
  printf 'tick() { printf "tick\\n" >>"${TICK_LOG}"; }\n%s' "$1"
}

wait_for_file() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2 2 2 2 2; do
    [[ -s "$1" ]] && return 0
    "${REAL_SLEEP}" "${delay}"
  done
  [[ -s "$1" ]]
}

@test "ticker.sh - run claims ownership for its pid" {
  # Arrange
  export REVAMPED_TICKER_MAX_TICKS=1
  script="$(tick_snippet 'revamped_ticker_run demo tick 4242')"

  # Act
  lib_run ticker "${script}"

  # Assert
  actual="$(stored @demo_ticker_pid)"
  [[ "${actual}" = "4242" ]]
}

@test "ticker.sh - run stops at the tick limit and reports it still owns the ticker" {
  # Arrange
  export REVAMPED_TICKER_MAX_TICKS=3
  script="$(tick_snippet 'revamped_ticker_run demo tick 4242')"

  # Act
  lib_run ticker "${script}"

  # Assert
  [[ "${status}" -eq 0 ]]
  actual="$(ticks)"
  [[ "${actual}" = "3" ]]
}

@test "ticker.sh - run stops when another ticker takes over" {
  # Arrange
  export REVAMPED_TICKER_MAX_TICKS=10
  local script='hand_over() { tick; [ "$(grep -c tick "${TICK_LOG}")" -ge 2 ] && tmux set-option -gq @demo_ticker_pid other; return 0; }; revamped_ticker_run demo hand_over 4242'
  script="$(tick_snippet "${script}")"

  # Act
  lib_run ticker "${script}"

  # Assert
  [[ "${status}" -eq 1 ]]
  actual="$(ticks)"
  [[ "${actual}" = "2" ]]
}

@test "ticker.sh - run stops when the server is gone" {
  # Arrange
  export REVAMPED_TICKER_MAX_TICKS=10 REVAMPED_TEST_TMUX_FAIL=1
  script="$(tick_snippet 'revamped_ticker_run demo tick 4242')"

  # Act
  lib_run ticker "${script}"

  # Assert
  [[ "${status}" -eq 1 ]]
  actual="$(ticks)"
  [[ "${actual}" = "0" ]]
}

@test "ticker.sh - each tick sleeps for the interval" {
  # Arrange
  export REVAMPED_TICKER_MAX_TICKS=2
  store status-interval 3
  script="$(tick_snippet 'revamped_ticker_run demo tick 4242')"

  # Act
  lib_run ticker "${script}"

  # Assert
  expected="$(printf '3\n3')"
  actual="$(stub_calls sleep)"
  [[ "${actual}" == "${expected}" ]]
}

@test "ticker.sh - run sleeps for the plugin fallback interval" {
  # Arrange
  export REVAMPED_TICKER_MAX_TICKS=1
  script="$(tick_snippet 'revamped_ticker_run demo tick 4242 9')"

  # Act
  lib_run ticker "${script}"

  # Assert
  actual="$(stub_calls sleep)"
  [[ "${actual}" = "9" ]]
}

@test "ticker.sh - the interval follows status-interval" {
  # Arrange
  store status-interval 7

  # Act
  lib_call ticker revamped_ticker_interval

  # Assert
  [[ "${output}" = "7" ]]
}

@test "ticker.sh - a missing interval falls back to the default" {
  # Arrange
  local prefix=demo

  # Act
  lib_call ticker revamped_ticker_interval "${prefix}"

  # Assert
  [[ "${output}" = "5" ]]
}

@test "ticker.sh - a zero interval falls back to the default" {
  # Arrange
  store status-interval 0

  # Act
  lib_call ticker revamped_ticker_interval

  # Assert
  [[ "${output}" = "5" ]]
}

@test "ticker.sh - a plugin interval option wins over the fallback" {
  # Arrange
  store @demo_interval 11

  # Act
  lib_call ticker revamped_ticker_interval demo 9

  # Assert
  [[ "${output}" = "11" ]]
}

@test "ticker.sh - the fallback applies when the plugin sets no interval" {
  # Arrange
  local fallback=9

  # Act
  lib_call ticker revamped_ticker_interval demo "${fallback}"

  # Assert
  [[ "${output}" = "9" ]]
}

@test "ticker.sh - an invalid plugin interval falls back to status-interval" {
  # Arrange
  store @demo_interval soon
  store status-interval 4

  # Act
  lib_call ticker revamped_ticker_interval demo

  # Assert
  [[ "${output}" = "4" ]]
}

@test "ticker.sh - minute wakes one second after the next minute starts" {
  # Arrange
  store @demo_interval minute
  export REVAMPED_TEST_SECOND=45

  # Act
  lib_call ticker revamped_ticker_interval demo

  # Assert
  [[ "${output}" = "16" ]]
}

@test "ticker.sh - a leading zero second reads as decimal" {
  # Arrange
  store @demo_interval minute
  export REVAMPED_TEST_SECOND=08

  # Act
  lib_call ticker revamped_ticker_interval demo

  # Assert
  [[ "${output}" = "53" ]]
}

@test "ticker.sh - an unreadable second still yields a full minute" {
  # Arrange
  store @demo_interval minute
  export REVAMPED_TEST_SECOND=garbage

  # Act
  lib_call ticker revamped_ticker_interval demo

  # Assert
  [[ "${output}" = "61" ]]
}

@test "ticker.sh - start runs the script's daemon subcommand in the background" {
  # Arrange
  local script="${BATS_TEST_TMPDIR}/demo.sh" seen="${BATS_TEST_TMPDIR}/seen"
  printf '#!/bin/sh\nprintf "%%s" "$1" >"%s"\n' "${seen}" >"${script}"
  chmod +x "${script}"

  # Act
  lib_call ticker revamped_ticker_start "${script}"

  # Assert
  wait_for_file "${seen}"
  actual="$(cat "${seen}")"
  [[ "${actual}" = "daemon" ]]
}

@test "ticker.sh - start detaches the daemon from the caller's stdin" {
  # Arrange
  local script="${BATS_TEST_TMPDIR}/reader.sh" done_marker="${BATS_TEST_TMPDIR}/read"
  printf '#!/bin/sh\ncat >/dev/null\nprintf done >"%s"\n' "${done_marker}" >"${script}"
  chmod +x "${script}"

  # Act
  lib_call ticker revamped_ticker_start "${script}"

  # Assert
  wait_for_file "${done_marker}"
  actual="$(cat "${done_marker}")"
  [[ "${actual}" = "done" ]]
}

@test "ticker.sh - an option is read from tmux once and its name is learned" {
  # Arrange
  store @alpha one

  # Act
  lib_run ticker 'REVAMPED_TICKER_PREFIX=demo; revamped_ticker_get_option @alpha fallback; revamped_ticker_get_option @alpha fallback'

  # Assert
  [[ "${output}" = "$(printf 'one\none')" ]]
  actual="$(count_matching '^show-option -gqv @alpha$' "${REVAMPED_TEST_TMUX_LOG}")"
  [[ "${actual}" = "1" ]]
  actual="$(stored @demo_option_names)"
  [[ "${actual}" = " @alpha" ]]
}

@test "ticker.sh - an empty option returns the default" {
  # Arrange
  local default=fallback

  # Act
  lib_run ticker "REVAMPED_TICKER_PREFIX=demo; revamped_ticker_get_option @empty ${default}"

  # Assert
  [[ "${output}" = "fallback" ]]
}

@test "ticker.sh - a write reaches tmux and the memory copy" {
  # Arrange
  local script='revamped_ticker_set_option @beta two; revamped_ticker_get_option @beta ""'

  # Act
  lib_run ticker "${script}"

  # Assert
  [[ "${output}" = "two" ]]
  actual="$(count_matching '^show-option -gqv @beta$' "${REVAMPED_TEST_TMUX_LOG}")"
  [[ "${actual}" = "0" ]]
  actual="$(stored @beta)"
  [[ "${actual}" = "two" ]]
}

@test "ticker.sh - a write joins the publish batch once the publisher is loaded" {
  # Arrange
  export REVAMPED_TEST_TMUX_ARGV="${BATS_TEST_TMPDIR}/argv"
  local script='. "${REVAMPED_LIB}/publish.sh"; revamped_ticker_set_option @gamma 3; revamped_publish_commit'

  # Act
  lib_run ticker "${script}"

  # Assert
  [[ "${status}" -eq 0 ]]
  actual="$(cat "${REVAMPED_TEST_TMUX_ARGV}")"
  [[ "${actual}" = "set-option|-gq|@gamma|3" ]]
}

@test "ticker.sh - prefetch reads every learned option in one call" {
  # Arrange
  store @demo_option_names " @a @b @a"
  tmux_answer "$(printf '#{@a}\037#{@b}\037')" "$(printf '1\0372 two\037')"

  # Act
  lib_run ticker 'REVAMPED_TICKER_PREFIX=demo; revamped_ticker_prefetch; revamped_ticker_get_option @a ""; revamped_ticker_get_option @b ""'

  # Assert
  [[ "${output}" = "$(printf '1\n2 two')" ]]
  actual="$(count_matching '^display-message' "${REVAMPED_TEST_TMUX_LOG}")"
  [[ "${actual}" = "1" ]]
  actual="$(count_matching '^show-option -gqv @a$' "${REVAMPED_TEST_TMUX_LOG}")"
  [[ "${actual}" = "0" ]]
}

@test "ticker.sh - prefetch drops the snapshot when fields are missing" {
  # Arrange
  store @demo_option_names " @a @b"
  tmux_answer "$(printf '#{@a}\037#{@b}\037')" "$(printf '1\037')"
  store @a live

  # Act
  lib_run ticker 'REVAMPED_TICKER_PREFIX=demo; revamped_ticker_prefetch; revamped_ticker_get_option @a ""'

  # Assert
  [[ "${output}" = "live" ]]
}

@test "ticker.sh - prefetch with no learned names makes no display call" {
  # Arrange
  local script='REVAMPED_TICKER_PREFIX=demo; revamped_ticker_prefetch'

  # Act
  lib_run ticker "${script}"

  # Assert
  actual="$(count_matching '^display-message' "${REVAMPED_TEST_TMUX_LOG}")"
  [[ "${actual}" = "0" ]]
}

@test "ticker.sh - install routes option reads through the snapshot" {
  # Arrange
  store @alpha one

  # Act
  lib_run ticker 'revamped_ticker_install demo; revamped_tmux_get @alpha ""; revamped_tmux_get @alpha ""'

  # Assert
  [[ "${output}" = "$(printf 'one\none')" ]]
  actual="$(count_matching '^show-option -gqv @alpha$' "${REVAMPED_TEST_TMUX_LOG}")"
  [[ "${actual}" = "1" ]]
}

@test "ticker.sh - install keeps the date clock where the shell has no EPOCHSECONDS" {
  # Arrange
  export REVAMPED_TEST_NOW=42

  # Act
  lib_run ticker '. "${REVAMPED_LIB}/cache.sh"; unset EPOCHSECONDS; revamped_ticker_install demo; revamped_cache_now'

  # Assert
  [[ "${output}" = "42" ]]
}

@test "ticker.sh - install reads the clock from EPOCHSECONDS where the shell has it" {
  # Arrange
  export REVAMPED_TEST_NOW=42

  # Act
  lib_run ticker '. "${REVAMPED_LIB}/cache.sh"; EPOCHSECONDS="${EPOCHSECONDS:-1700000000}"; revamped_ticker_install demo; revamped_cache_now'

  # Assert
  [[ "${output}" != "42" ]]
  [[ "${output}" =~ ^[0-9]+$ ]]
}

@test "ticker.sh - a second write to an option replaces the first" {
  # Arrange
  local script='revamped_ticker_set_option @beta one; revamped_ticker_set_option @beta two; revamped_ticker_get_option @beta ""'

  # Act
  lib_run ticker "${script}"

  # Assert
  [[ "${output}" == "two" ]]
}

@test "ticker.sh - install reads the platform once the platform module is loaded" {
  # Arrange
  export REVAMPED_TEST_UNAME_LOG="${BATS_TEST_TMPDIR}/uname.log"

  # Act
  lib_run ticker '. "${REVAMPED_LIB}/platform.sh"; revamped_ticker_install demo'

  # Assert
  actual="$(count_matching '^-s$' "${REVAMPED_TEST_UNAME_LOG}")"
  [[ "${actual}" -eq 1 ]]
}
