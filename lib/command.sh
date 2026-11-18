#!/bin/sh

[ -n "${REVAMPED_COMMAND_LOADED:-}" ] && return 0
REVAMPED_COMMAND_LOADED=1

revamped_has_command() {
  command -v "$1" >/dev/null 2>&1 || return 1
}
