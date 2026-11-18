#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  export REVAMPED_CACHE_PREFIX=test_rev REVAMPED_CACHE_SYNC=1 REVAMPED_TEST_NOW=1000000
}

stored() {
  tmux show-option -gqv "$1"
}

store() {
  tmux set-option -gq "$1" "$2"
}

wait_until_stored() {
  local tries=0 value
  value="$(stored "$1")"
  while [[ "${value}" != "$2" ]] && [[ "${tries}" -lt 200 ]]; do
    sleep 0.01
    tries=$((tries + 1))
    value="$(stored "$1")"
  done
}

@test "cache.sh - get is empty for an unset key" {
  # Arrange
  local key=percent

  # Act
  lib_call cache revamped_cache_get "${key}"

  # Assert
  [[ "${output}" = "" ]]
}

@test "cache.sh - set stores the value and stamps the write time" {
  # Arrange
  local key=percent

  # Act
  lib_call cache revamped_cache_set "${key}" 42

  # Assert
  actual="$(stored @test_rev_percent)"
  [[ "${actual}" = "42" ]]
  actual="$(stored @test_rev_percent_ts)"
  [[ "${actual}" = "1000000" ]]
}

@test "cache.sh - age is the sentinel for a never-written key" {
  # Arrange
  local key=percent

  # Act
  lib_call cache revamped_cache_age "${key}"

  # Assert
  [[ "${output}" = "999999999" ]]
}

@test "cache.sh - age reflects elapsed time" {
  # Arrange
  store @test_rev_percent_ts 1000000
  export REVAMPED_TEST_NOW=1000010

  # Act
  lib_call cache revamped_cache_age percent

  # Assert
  [[ "${output}" = "10" ]]
}

@test "cache.sh - age is the sentinel for a non-numeric timestamp" {
  # Arrange
  store @test_rev_percent_ts garbage

  # Act
  lib_call cache revamped_cache_age percent

  # Assert
  [[ "${output}" = "999999999" ]]
}

@test "cache.sh - fresh within the max age" {
  # Arrange
  store @test_rev_percent_ts 1000000
  export REVAMPED_TEST_NOW=1000003

  # Act
  lib_call cache revamped_cache_is_fresh percent 5

  # Assert
  [[ "${status}" -eq 0 ]]
}

@test "cache.sh - stale beyond the max age" {
  # Arrange
  store @test_rev_percent_ts 1000000
  export REVAMPED_TEST_NOW=1000010

  # Act
  lib_call cache revamped_cache_is_fresh percent 5

  # Assert
  [[ "${status}" -eq 1 ]]
}

@test "cache.sh - a non-numeric max age is never fresh and never evaluated" {
  # Arrange
  store @test_rev_key_ts 1000000
  local marker="${BATS_TEST_TMPDIR}/evaluated"

  # Act
  lib_call cache revamped_cache_is_fresh key "x[\$(touch ${marker})]"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ ! -e "${marker}" ]]
}

@test "cache.sh - no refresh while fresh" {
  # Arrange
  store @test_rev_percent_ts 1000000

  # Act
  lib_call cache revamped_cache_should_refresh percent 5

  # Assert
  [[ "${status}" -eq 1 ]]
}

@test "cache.sh - refresh when stale and unlocked" {
  # Arrange
  local key=percent

  # Act
  lib_call cache revamped_cache_should_refresh "${key}" 5

  # Assert
  [[ "${status}" -eq 0 ]]
}

@test "cache.sh - no refresh while a fresh lock is held" {
  # Arrange
  store @test_rev_percent_lock 1
  store @test_rev_percent_lock_ts 1000000
  export REVAMPED_TEST_NOW=1000005

  # Act
  lib_call cache revamped_cache_should_refresh percent 1

  # Assert
  [[ "${status}" -eq 1 ]]
}

@test "cache.sh - refresh once the lock is older than the max run" {
  # Arrange
  store @test_rev_percent_lock 1
  store @test_rev_percent_lock_ts 1000000
  export REVAMPED_TEST_NOW=1000030

  # Act
  lib_call cache revamped_cache_should_refresh percent 1

  # Assert
  [[ "${status}" -eq 0 ]]
}

@test "cache.sh - a non-numeric max run falls back to the default and is never evaluated" {
  # Arrange
  local marker="${BATS_TEST_TMPDIR}/evaluated"
  store @test_rev_key_lock 1
  store @test_rev_key_lock_ts 1000000
  export REVAMPED_TEST_NOW=1000100 REVAMPED_CACHE_MAX_RUN="x[\$(touch ${marker})]"

  # Act
  lib_call cache revamped_cache_should_refresh key 10

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ ! -e "${marker}" ]]
}

@test "cache.sh - refresh runs the worker when stale and clears the lock" {
  # Arrange
  local script='worker() { revamped_cache_set percent fresh; }; revamped_cache_refresh_if_stale percent 5 worker'

  # Act
  lib_run cache "${script}"

  # Assert
  actual="$(stored @test_rev_percent)"
  [[ "${actual}" = "fresh" ]]
  actual="$(stored @test_rev_percent_lock)"
  [[ "${actual}" = "0" ]]
}

@test "cache.sh - refresh does nothing while fresh" {
  # Arrange
  store @test_rev_percent old
  store @test_rev_percent_ts 1000000

  # Act
  lib_run cache 'worker() { revamped_cache_set percent new; }; revamped_cache_refresh_if_stale percent 5 worker'

  # Assert
  actual="$(stored @test_rev_percent)"
  [[ "${actual}" = "old" ]]
}

@test "cache.sh - render refreshes a stale value and prints the new one" {
  # Arrange
  store @test_rev_percent 10
  store @test_rev_percent_ts 1000000
  export REVAMPED_TEST_NOW=1000010

  # Act
  lib_run cache 'worker() { revamped_cache_set percent 20; }; revamped_cache_render percent 5 worker'

  # Assert
  [[ "${output}" = "20" ]]
}

@test "cache.sh - render prints a fresh value without running the worker" {
  # Arrange
  store @test_rev_percent 10
  store @test_rev_percent_ts 1000000

  # Act
  lib_run cache 'worker() { revamped_cache_set percent 20; }; revamped_cache_render percent 5 worker'

  # Assert
  [[ "${output}" = "10" ]]
}

@test "cache.sh - a background refresh runs the worker and then clears its lock" {
  # Arrange
  unset REVAMPED_CACHE_SYNC

  # Act
  lib_run cache 'worker() { revamped_tmux_set @test_rev_done yes; }; revamped_cache_refresh_if_stale percent 5 worker'

  # Assert
  wait_until_stored @test_rev_percent_lock 0
  actual="$(stored @test_rev_done)"
  [[ "${actual}" = "yes" ]]
  actual="$(stored @test_rev_percent_lock)"
  [[ "${actual}" = "0" ]]
}

@test "cache.sh - set_if_stale keeps a fresh value" {
  # Arrange
  store @test_rev_percent keep
  store @test_rev_percent_ts 1000000

  # Act
  lib_run cache 'probe() { printf changed; }; revamped_cache_set_if_stale percent 5 probe'

  # Assert
  actual="$(stored @test_rev_percent)"
  [[ "${actual}" = "keep" ]]
}

@test "cache.sh - set_if_stale recomputes a stale value" {
  # Arrange
  store @test_rev_percent old
  store @test_rev_percent_ts 1000000
  export REVAMPED_TEST_NOW=1000010

  # Act
  lib_run cache 'probe() { printf new; }; revamped_cache_set_if_stale percent 5 probe'

  # Assert
  actual="$(stored @test_rev_percent)"
  [[ "${actual}" = "new" ]]
}

@test "cache.sh - set_if_stale forwards the arguments to the producer" {
  # Arrange
  local script='probe() { printf "%s-%s" "$1" "$2"; }; revamped_cache_set_if_stale percent 5 probe a b'

  # Act
  lib_run cache "${script}"

  # Assert
  actual="$(stored @test_rev_percent)"
  [[ "${actual}" = "a-b" ]]
}
