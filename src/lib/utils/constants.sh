#!/usr/bin/env bash
# shellcheck disable=SC2034  # constants are sourced and read by other modules

[[ -n "${_TMUX_PLUGIN_CONSTANTS_LOADED:-}" ]] && return 0
_TMUX_PLUGIN_CONSTANTS_LOADED=1

readonly SENSIBLE_REVAMPED_VERSION="2.0.0"

readonly TMUX_PLUGIN_DEFAULT_MAX_AGE="5"

readonly TMUX_PLUGIN_PENDING="..."
