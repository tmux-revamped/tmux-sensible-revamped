#!/bin/sh

[ -n "${REVAMPED_LOG_LOADED:-}" ] && return 0
REVAMPED_LOG_LOADED=1

# shellcheck source=SCRIPTDIR/tmux.sh
. "${REVAMPED_LIB:?}/tmux.sh"

REVAMPED_LOG_NS="${REVAMPED_LOG_NS:-tmux-plugin}"
REVAMPED_LOG_DIR="${REVAMPED_LOG_DIR:-${HOME}/.tmux/${REVAMPED_LOG_NS}-logs}"
REVAMPED_LOG_FILE="${REVAMPED_LOG_FILE:-${REVAMPED_LOG_DIR}/${REVAMPED_LOG_NS}.log}"
REVAMPED_LOG_OPTION="${REVAMPED_LOG_OPTION:-@$(printf '%s' "${REVAMPED_LOG_NS}" | tr '-' '_')_enable_logging}"
REVAMPED_LOG_MAX_SIZE="${REVAMPED_LOG_MAX_SIZE:-1048576}"
REVAMPED_LOG_MAX_LINES="${REVAMPED_LOG_MAX_LINES:-1000}"

revamped_log_enabled() {
  revamped_log_enabled_value=$(revamped_tmux_get "${REVAMPED_LOG_OPTION}")
  [ "${revamped_log_enabled_value}" = 1 ]
}

revamped_log_size() {
  stat -c %s -- "$1" 2>/dev/null || stat -f %z -- "$1" 2>/dev/null || printf '0\n'
}

revamped_log_rotate() {
  [ -f "${REVAMPED_LOG_FILE}" ] || return 0
  revamped_log_rotate_size=$(revamped_log_size "${REVAMPED_LOG_FILE}")
  case "${revamped_log_rotate_size}" in
  '' | *[!0-9]*) return 0 ;;
  *) ;;
  esac
  [ "${revamped_log_rotate_size}" -gt "${REVAMPED_LOG_MAX_SIZE}" ] || return 0
  tail -n "${REVAMPED_LOG_MAX_LINES}" "${REVAMPED_LOG_FILE}" >"${REVAMPED_LOG_FILE}.rotated" 2>/dev/null &&
    mv -f "${REVAMPED_LOG_FILE}.rotated" "${REVAMPED_LOG_FILE}" 2>/dev/null
  return 0
}

revamped_log_error() {
  [ -n "${2:-}" ] || return 0
  revamped_log_enabled || return 0
  revamped_log_error_component=$(printf '%s' "${1:-unknown}" | tr -cd 'A-Za-z0-9_-')
  mkdir -p "${REVAMPED_LOG_DIR}" 2>/dev/null || return 0
  [ -w "${REVAMPED_LOG_DIR}" ] || return 0
  revamped_log_error_time=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null) || return 0
  printf '[%s] [%s] %s\n' "${revamped_log_error_time}" "${revamped_log_error_component}" "$2" >>"${REVAMPED_LOG_FILE}" 2>/dev/null || return 0
  revamped_log_rotate
}
