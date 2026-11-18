#!/bin/sh

[ -n "${REVAMPED_NOTIFY_LOADED:-}" ] && return 0
REVAMPED_NOTIFY_LOADED=1

# shellcheck source=SCRIPTDIR/platform.sh
. "${REVAMPED_LIB:?}/platform.sh"
# shellcheck source=SCRIPTDIR/command.sh
. "${REVAMPED_LIB:?}/command.sh"
# shellcheck source=SCRIPTDIR/tmux.sh
. "${REVAMPED_LIB:?}/tmux.sh"

revamped_notify_backend() {
  if revamped_is_macos && revamped_has_command osascript; then
    printf 'osascript\n'
  elif revamped_has_command notify-send; then
    printf 'notify-send\n'
  else
    printf 'none\n'
  fi
}

revamped_notify_enabled() {
  revamped_notify_enabled_value=$(revamped_tmux_get "$1" 0)
  [ "${revamped_notify_enabled_value}" = 1 ]
}

revamped_notify_send() {
  revamped_notify_send_backend=$(revamped_notify_backend)
  case "${revamped_notify_send_backend}" in
  osascript)
    osascript -e 'on run argv' -e 'display notification (item 2 of argv) with title (item 1 of argv)' -e 'end run' "$1" "$2" >/dev/null 2>&1
    ;;
  notify-send) notify-send -- "$1" "$2" >/dev/null 2>&1 ;;
  *) : ;;
  esac
  return 0
}

revamped_notify_if_enabled() {
  revamped_notify_enabled "$1" || return 0
  revamped_notify_send "$2" "$3"
}
