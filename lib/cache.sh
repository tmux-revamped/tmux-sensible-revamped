#!/bin/sh

[ -n "${REVAMPED_CACHE_LOADED:-}" ] && return 0
REVAMPED_CACHE_LOADED=1

# shellcheck source=SCRIPTDIR/tmux.sh
. "${REVAMPED_LIB:?}/tmux.sh"

REVAMPED_CACHE_PREFIX="${REVAMPED_CACHE_PREFIX:-tmux_plugin}"
REVAMPED_CACHE_MAX_RUN_DEFAULT=20
REVAMPED_CACHE_MAX_RUN="${REVAMPED_CACHE_MAX_RUN:-${REVAMPED_CACHE_MAX_RUN_DEFAULT}}"
REVAMPED_CACHE_NEVER_AGE=999999999

revamped_cache_now() {
  date +%s 2>/dev/null || printf '0\n'
}

revamped_cache_is_number() {
  case "$1" in
  '' | *[!0-9]*) return 1 ;;
  *) return 0 ;;
  esac
}

revamped_cache_get() {
  revamped_tmux_get "@${REVAMPED_CACHE_PREFIX}_$1"
}

revamped_cache_set() {
  revamped_tmux_set "@${REVAMPED_CACHE_PREFIX}_$1" "$2"
  revamped_cache_set_now=$(revamped_cache_now)
  revamped_tmux_set "@${REVAMPED_CACHE_PREFIX}_$1_ts" "${revamped_cache_set_now}"
}

revamped_cache_measure() {
  revamped_cache_measure_ts=$(revamped_tmux_get "@${REVAMPED_CACHE_PREFIX}_$1_ts")
  if ! revamped_cache_is_number "${revamped_cache_measure_ts}"; then
    revamped_cache_measure_age="${REVAMPED_CACHE_NEVER_AGE}"
    return 0
  fi
  revamped_cache_measure_now=$(revamped_cache_now)
  revamped_cache_measure_age=$((revamped_cache_measure_now - revamped_cache_measure_ts))
}

revamped_cache_age() {
  revamped_cache_measure "$1"
  printf '%s\n' "${revamped_cache_measure_age}"
}

revamped_cache_is_fresh() {
  revamped_cache_is_number "${2:-}" || return 1
  revamped_cache_measure "$1"
  [ "${revamped_cache_measure_age}" -le "$2" ]
}

revamped_cache_clear_lock() {
  revamped_tmux_set "@${REVAMPED_CACHE_PREFIX}_$1_lock" 0
}

revamped_cache_should_refresh() {
  revamped_cache_is_fresh "$1" "$2" && return 1
  revamped_cache_should_refresh_lock=$(revamped_cache_get "$1_lock")
  [ "${revamped_cache_should_refresh_lock}" = 1 ] || return 0
  revamped_cache_should_refresh_limit="${REVAMPED_CACHE_MAX_RUN}"
  revamped_cache_is_number "${revamped_cache_should_refresh_limit}" || revamped_cache_should_refresh_limit="${REVAMPED_CACHE_MAX_RUN_DEFAULT}"
  revamped_cache_measure "$1_lock"
  [ "${revamped_cache_measure_age}" -ge "${revamped_cache_should_refresh_limit}" ]
}

revamped_cache_spawn_run() {
  revamped_cache_spawn_key="$1"
  trap 'revamped_cache_clear_lock "${revamped_cache_spawn_key}"' EXIT
  shift
  "$@"
}

revamped_cache_spawn() {
  (revamped_cache_spawn_run "$@") </dev/null >/dev/null 2>&1 &
}

revamped_cache_refresh_if_stale() {
  revamped_cache_refresh_if_stale_key="$1"
  revamped_cache_should_refresh "$1" "$2" || return 0
  shift 2
  revamped_cache_set "${revamped_cache_refresh_if_stale_key}_lock" 1
  if [ -n "${REVAMPED_CACHE_SYNC:-}" ]; then
    "$@"
    revamped_cache_clear_lock "${revamped_cache_refresh_if_stale_key}"
    return 0
  fi
  revamped_cache_spawn "${revamped_cache_refresh_if_stale_key}" "$@"
}

revamped_cache_render() {
  revamped_cache_render_key="$1"
  revamped_cache_refresh_if_stale "$@"
  revamped_cache_get "${revamped_cache_render_key}"
}

revamped_cache_set_if_stale() {
  revamped_cache_is_fresh "$1" "$2" && return 0
  revamped_cache_set_if_stale_key="$1"
  shift 2
  revamped_cache_set_if_stale_value=$("$@") || revamped_cache_set_if_stale_value=""
  revamped_cache_set "${revamped_cache_set_if_stale_key}" "${revamped_cache_set_if_stale_value}"
}
