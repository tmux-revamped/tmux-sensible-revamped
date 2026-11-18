#!/bin/sh

[ -n "${REVAMPED_TICKER_LOADED:-}" ] && return 0
REVAMPED_TICKER_LOADED=1

# shellcheck source=SCRIPTDIR/tmux.sh
. "${REVAMPED_LIB:?}/tmux.sh"

REVAMPED_TICKER_MAX_TICKS="${REVAMPED_TICKER_MAX_TICKS:-100000}"
REVAMPED_TICKER_DEFAULT_INTERVAL=5
REVAMPED_TICKER_SEP=$(printf '\037')
REVAMPED_TICKER_RECORD=$(printf '\036')
REVAMPED_TICKER_PREFIX=""
REVAMPED_TICKER_SNAPSHOT=""
REVAMPED_TICKER_FOUND=""

revamped_ticker_is_count() {
  case "$1" in
  '' | *[!0-9]* | 0) return 1 ;;
  *) return 0 ;;
  esac
}

revamped_ticker_owns() {
  revamped_ticker_owns_pid=$(tmux show-option -gqv "@$1_ticker_pid" 2>/dev/null) || return 1
  [ "${revamped_ticker_owns_pid}" = "$2" ]
}

revamped_ticker_claim() {
  tmux set-option -gq "@$1_ticker_pid" "$2" 2>/dev/null
}

revamped_ticker_seconds_to_next_minute() {
  revamped_ticker_seconds_second=$(date +%S 2>/dev/null) || revamped_ticker_seconds_second=""
  revamped_ticker_seconds_second="${revamped_ticker_seconds_second#0}"
  case "${revamped_ticker_seconds_second}" in
  '' | *[!0-9]*) revamped_ticker_seconds_second=0 ;;
  *) ;;
  esac
  printf '%s' "$((61 - revamped_ticker_seconds_second))"
}

revamped_ticker_interval() {
  revamped_ticker_interval_value=""
  if [ -n "${1:-}" ]; then
    revamped_ticker_interval_value=$(tmux show-option -gqv "@$1_interval" 2>/dev/null) || revamped_ticker_interval_value=""
  fi
  [ -n "${revamped_ticker_interval_value}" ] || revamped_ticker_interval_value="${2:-}"
  if [ "${revamped_ticker_interval_value}" = minute ]; then
    revamped_ticker_seconds_to_next_minute
    return 0
  fi
  if ! revamped_ticker_is_count "${revamped_ticker_interval_value}"; then
    revamped_ticker_interval_value=$(tmux show-option -gqv status-interval 2>/dev/null) || revamped_ticker_interval_value=""
  fi
  revamped_ticker_is_count "${revamped_ticker_interval_value}" || revamped_ticker_interval_value="${REVAMPED_TICKER_DEFAULT_INTERVAL}"
  printf '%s' "${revamped_ticker_interval_value}"
}

revamped_ticker_find() {
  case "${REVAMPED_TICKER_SNAPSHOT}" in
  *"${REVAMPED_TICKER_RECORD}$1${REVAMPED_TICKER_SEP}"*)
    REVAMPED_TICKER_FOUND="${REVAMPED_TICKER_SNAPSHOT#*"${REVAMPED_TICKER_RECORD}$1${REVAMPED_TICKER_SEP}"}"
    REVAMPED_TICKER_FOUND="${REVAMPED_TICKER_FOUND%%"${REVAMPED_TICKER_RECORD}"*}"
    return 0
    ;;
  *) return 1 ;;
  esac
}

revamped_ticker_store() {
  case "${REVAMPED_TICKER_SNAPSHOT}" in
  *"${REVAMPED_TICKER_RECORD}$1${REVAMPED_TICKER_SEP}"*)
    revamped_ticker_store_before="${REVAMPED_TICKER_SNAPSHOT%%"${REVAMPED_TICKER_RECORD}$1${REVAMPED_TICKER_SEP}"*}"
    revamped_ticker_store_after="${REVAMPED_TICKER_SNAPSHOT#*"${REVAMPED_TICKER_RECORD}$1${REVAMPED_TICKER_SEP}"}"
    revamped_ticker_store_after="${revamped_ticker_store_after#*"${REVAMPED_TICKER_RECORD}"}"
    REVAMPED_TICKER_SNAPSHOT="${revamped_ticker_store_before}${REVAMPED_TICKER_RECORD}${revamped_ticker_store_after}"
    ;;
  *) ;;
  esac
  REVAMPED_TICKER_SNAPSHOT="${REVAMPED_TICKER_SNAPSHOT%"${REVAMPED_TICKER_RECORD}"}${REVAMPED_TICKER_RECORD}$1${REVAMPED_TICKER_SEP}$2${REVAMPED_TICKER_RECORD}"
}

revamped_ticker_get_option() {
  if ! revamped_ticker_find "$1"; then
    REVAMPED_TICKER_FOUND=$(tmux show-option -gqv "$1" 2>/dev/null) || REVAMPED_TICKER_FOUND=""
    revamped_ticker_store "$1" "${REVAMPED_TICKER_FOUND}"
    tmux set-option -gqa "@${REVAMPED_TICKER_PREFIX}_option_names" " $1" 2>/dev/null
  fi
  printf '%s\n' "${REVAMPED_TICKER_FOUND:-${2:-}}"
}

revamped_ticker_set_option() {
  revamped_ticker_store "$1" "$2"
  if [ -n "${REVAMPED_PUBLISH_LOADED:-}" ]; then
    revamped_publish_add_raw "$1" "$2"
  else
    tmux set-option -gq "$1" "$2" 2>/dev/null
  fi
}

revamped_ticker_prefetch() {
  REVAMPED_TICKER_SNAPSHOT=""
  revamped_ticker_prefetch_names=$(tmux show-option -gqv "@${REVAMPED_TICKER_PREFIX}_option_names" 2>/dev/null) || revamped_ticker_prefetch_names=""
  revamped_ticker_prefetch_seen=" "
  revamped_ticker_prefetch_format=""
  for revamped_ticker_prefetch_name in ${revamped_ticker_prefetch_names}; do
    case "${revamped_ticker_prefetch_seen}" in *" ${revamped_ticker_prefetch_name} "*) continue ;; *) ;; esac
    revamped_ticker_prefetch_seen="${revamped_ticker_prefetch_seen}${revamped_ticker_prefetch_name} "
    revamped_ticker_prefetch_format="${revamped_ticker_prefetch_format}#{${revamped_ticker_prefetch_name}}${REVAMPED_TICKER_SEP}"
  done
  [ -n "${revamped_ticker_prefetch_format}" ] || return 0
  revamped_ticker_prefetch_rest=$(tmux display-message -p "${revamped_ticker_prefetch_format}" 2>/dev/null) || return 0
  for revamped_ticker_prefetch_name in ${revamped_ticker_prefetch_seen}; do
    case "${revamped_ticker_prefetch_rest}" in
    *"${REVAMPED_TICKER_SEP}"*) ;;
    *)
      REVAMPED_TICKER_SNAPSHOT=""
      return 0
      ;;
    esac
    revamped_ticker_store "${revamped_ticker_prefetch_name}" "${revamped_ticker_prefetch_rest%%"${REVAMPED_TICKER_SEP}"*}"
    revamped_ticker_prefetch_rest="${revamped_ticker_prefetch_rest#*"${REVAMPED_TICKER_SEP}"}"
  done
}

# shellcheck disable=SC2329
revamped_ticker_install() {
  REVAMPED_TICKER_PREFIX="$1"
  revamped_tmux_get() { revamped_ticker_get_option "$@"; }
  revamped_tmux_set() { revamped_ticker_set_option "$@"; }
  if [ -n "${EPOCHSECONDS:-}" ]; then
    revamped_cache_now() { printf '%s\n' "${EPOCHSECONDS}"; }
  fi
  if [ -n "${REVAMPED_PLATFORM_LOADED:-}" ]; then
    revamped_platform_detect
  fi
}

revamped_ticker_start() {
  nohup "$1" daemon </dev/null >/dev/null 2>&1 &
}

revamped_ticker_run() {
  revamped_ticker_run_prefix="$1"
  revamped_ticker_run_tick="$2"
  revamped_ticker_run_pid="$3"
  revamped_ticker_run_fallback="${4:-}"
  revamped_ticker_run_count=0
  revamped_ticker_claim "${revamped_ticker_run_prefix}" "${revamped_ticker_run_pid}"
  revamped_ticker_install "${revamped_ticker_run_prefix}"
  while [ "${revamped_ticker_run_count}" -lt "${REVAMPED_TICKER_MAX_TICKS}" ] &&
    revamped_ticker_owns "${revamped_ticker_run_prefix}" "${revamped_ticker_run_pid}"; do
    revamped_ticker_prefetch
    "${revamped_ticker_run_tick}"
    revamped_ticker_run_sleep=$(revamped_ticker_interval "${revamped_ticker_run_prefix}" "${revamped_ticker_run_fallback}")
    sleep "${revamped_ticker_run_sleep}"
    revamped_ticker_run_count=$((revamped_ticker_run_count + 1))
  done
  [ "${revamped_ticker_run_count}" -ge "${REVAMPED_TICKER_MAX_TICKS}" ] &&
    revamped_ticker_owns "${revamped_ticker_run_prefix}" "${revamped_ticker_run_pid}"
}
