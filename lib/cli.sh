#!/bin/sh

[ -n "${REVAMPED_CLI_LOADED:-}" ] && return 0
REVAMPED_CLI_LOADED=1

# shellcheck source=SCRIPTDIR/ui.sh
. "${REVAMPED_LIB:?}/ui.sh"
# shellcheck source=SCRIPTDIR/tmux.sh
. "${REVAMPED_LIB:?}/tmux.sh"

revamped_cli_die() {
  if revamped_ui_err; then
    revamped_ui_log ERROR "$1"
  else
    printf '%s: %s\n' "${REVAMPED_UI_NAME}" "$1" >&2
  fi
  exit "${2:-1}"
}

revamped_cli_usage_error() {
  revamped_cli_die "$1. run '${REVAMPED_UI_NAME} help' for usage."
}

revamped_cli_interactive() {
  revamped_ui_forced && return 0
  [ -t 0 ] && [ -t 2 ]
}

revamped_cli_require_terminal() {
  revamped_cli_interactive || revamped_cli_usage_error "no command given"
}

revamped_cli_theme() {
  if [ -n "$1" ]; then
    REVAMPED_UI_THEME="$1"
  elif [ -n "${KODOUGU_THEME:-}" ]; then
    REVAMPED_UI_THEME="${KODOUGU_THEME}"
  else
    REVAMPED_UI_THEME=$(revamped_tmux_get @revamped_theme kodougu)
  fi
}

revamped_cli_start() {
  revamped_cli_theme "$1"
  revamped_ui_setup || revamped_cli_die "${REVAMPED_UI_PROBLEM}"
}

revamped_cli_menu() {
  if revamped_ui_prompts; then
    revamped_ui_header
    revamped_cli_menu_choice=$(revamped_ui_choose "What would you like to do?" "$@") || exit 1
    printf '%s\n' "${revamped_cli_menu_choice}"
    return 0
  fi
  printf '%s\n' "What would you like to do?" >&2
  revamped_cli_menu_count=0
  for revamped_cli_menu_item in "$@"; do
    revamped_cli_menu_count=$((revamped_cli_menu_count + 1))
    printf '  %s) %s\n' "${revamped_cli_menu_count}" "${revamped_cli_menu_item}" >&2
  done
  printf 'Choice [1]: ' >&2
  IFS= read -r revamped_cli_menu_answer || exit 1
  revamped_cli_menu_pick "${revamped_cli_menu_answer:-1}" "$@"
}

revamped_cli_menu_pick() {
  case "$1" in
  '' | *[!0-9]* | 0) revamped_cli_usage_error "unknown choice '$1'" ;;
  *) ;;
  esac
  [ "$1" -lt "$#" ] || revamped_cli_usage_error "unknown choice '$1'"
  shift "$1"
  printf '%s\n' "$1"
}

revamped_cli_help_page() {
  if revamped_ui_out; then
    revamped_ui_markdown | revamped_gum format --theme "${REVAMPED_UI_HELP}"
    return 0
  fi
  cat
}
