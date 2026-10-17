#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _SENSIBLE_REVAMPED_LOADED
  export SENSIBLE_DRY_RUN=1
  source "${BATS_TEST_DIRNAME}/../../../src/sensible.sh"
  _tmux_version_string() { echo "tmux 3.5"; }
  _get_option() { echo ""; }
  _have() { return 1; }
  _uname() { echo "Linux"; }
  _proc_version() { echo "generic"; }
  _has_terminfo() { return 0; }
  _terminfo_rgb() { return 1; }
  _prefix() { echo "C-b"; }
  _key_unbound() { return 0; }
  _get_server_option() { echo ""; }
  _get_window_option() { echo ""; }
  _control_client_count() { echo 0; }
  export EDITOR="" VISUAL="" COLORTERM="truecolor" TERM_PROGRAM="" LC_TERMINAL="" TERM="xterm-256color"
  export WAYLAND_DISPLAY="" DISPLAY="" XDG_CONFIG_HOME=""
  export HOME="${TEST_TMPDIR}"
}

teardown() {
  cleanup_test_environment
}

@test "applier - modern tmux 3.5 enables the full feature set" {
  run apply_sensible
  [[ "${output}" == *"set -as terminal-features ,*:RGB"* ]] || false
  [[ "${output}" == *"set -as terminal-features ,*:clipboard:ccolour:cstyle:focus:title"* ]] || false
  [[ "${output}" == *"set -as terminal-features ,rxvt*:ignorefkeys"* ]] || false
  [[ "${output}" == *"set -g allow-passthrough all"* ]] || false
  [[ "${output}" == *"set -as terminal-features ,*:sixel"* ]] || false
  [[ "${output}" == *"set -sg extended-keys on"* ]] || false
  [[ "${output}" == *"set -sg extended-keys-format csi-u"* ]] || false
  [[ "${output}" == *"set -sg escape-time 10"* ]] || false
  [[ "${output}" == *"set -g focus-events on"* ]] || false
  [[ "${output}" == *"set -g set-clipboard on"* ]] || false
  [[ "${output}" == *"set -g set-titles on"* ]] || false
  [[ "${output}" == *"set -g display-panes-time 2000"* ]] || false
  [[ "${output}" == *"setw -g pane-base-index 1"* ]] || false
  [[ "${output}" == *"set -g renumber-windows on"* ]]
}

@test "applier - tmux 1.9 skips features above its version" {
  _tmux_version_string() { echo "tmux 1.9"; }
  run apply_sensible
  [[ "${output}" != *"terminal-features"* ]] || false
  [[ "${output}" != *"allow-passthrough"* ]] || false
  [[ "${output}" != *"extended-keys"* ]] || false
  [[ "${output}" != *"Smulx"* ]] || false
  [[ "${output}" != *":sixel"* ]] || false
  [[ "${output}" == *"set -sg escape-time 10"* ]] || false
  [[ "${output}" == *"set -g focus-events on"* ]] || false
  [[ "${output}" == *"setw -g pane-base-index 1"* ]] || false
  [[ "${output}" == *"set -g renumber-windows on"* ]]
}

@test "applier - legacy truecolor override on old tmux with a truecolor terminal" {
  _tmux_version_string() { echo "tmux 2.8"; }
  export COLORTERM="truecolor"
  run apply_sensible
  [[ "${output}" == *"set -ga terminal-overrides ,*:Tc"* ]] || false
  [[ "${output}" != *"terminal-features ,*:RGB"* ]]
}

@test "applier - truecolor is not forced without COLORTERM or terminfo" {
  export COLORTERM=""
  _terminfo_rgb() { return 1; }
  run apply_sensible
  [[ "${output}" != *":RGB"* ]] || false
  [[ "${output}" != *":Tc"* ]]
}

@test "applier - truecolor falls back to terminfo when COLORTERM is unset" {
  export COLORTERM=""
  _terminfo_rgb() { return 0; }
  run apply_sensible
  [[ "${output}" == *"set -as terminal-features ,*:RGB"* ]]
}

@test "applier - nested screen TERM is never tagged truecolor" {
  export COLORTERM="truecolor" TERM="screen-256color"
  run apply_sensible
  [[ "${output}" != *":RGB"* ]] || false
  [[ "${output}" != *":Tc"* ]]
}

@test "applier - a terminal feature already present is not appended again" {
  # Arrange
  _get_server_option() { case "$1" in terminal-features) printf '%s\n' 'xterm*:clipboard' '*:RGB' ;; *) echo "" ;; esac; }

  # Act
  run apply_sensible

  # Assert
  [[ "${output}" != *"terminal-features ,*:RGB"* ]] || false
  [[ "${output}" == *"set -as terminal-features ,*:clipboard:ccolour:cstyle:focus:title"* ]]
}

@test "applier - a terminal override already present is not appended again" {
  # Arrange
  _get_server_option() { case "$1" in terminal-overrides) printf '%s\n' '*:Smulx=\E[4::%p1%dm' ;; *) echo "" ;; esac; }

  # Act
  run apply_sensible

  # Assert
  [[ "${output}" != *"Smulx"* ]] || false
  [[ "${output}" == *"Setulc"* ]]
}

@test "applier - a legacy comma-joined override string is matched per entry" {
  # Arrange
  _tmux_version_string() { echo "tmux 2.8"; }
  _get_option() { case "$1" in terminal-overrides) echo 'xterm*:XT,*:Tc' ;; *) echo "" ;; esac; }

  # Act
  run apply_sensible

  # Assert
  [[ "${output}" != *":Tc"* ]]
}

@test "applier - undercurl override appears on tmux 3.0 and up" {
  _tmux_version_string() { echo "tmux 3.0"; }
  run apply_sensible
  [[ "${output}" == *"Smulx"* ]]
}

@test "applier - OSC 52 and cursor-shape overrides appear below tmux 3.2" {
  _tmux_version_string() { echo "tmux 3.0"; }
  export TERM="xterm-256color"
  run apply_sensible
  [[ "${output}" == *"Ms=\\E]52"* ]] || false
  [[ "${output}" == *"Ss=\\E["* ]]
}

@test "applier - OSC 52 override is skipped on tmux 3.2 and up" {
  run apply_sensible
  [[ "${output}" != *"Ms=\\E]52"* ]] || false
  [[ "${output}" != *"Ss=\\E["* ]]
}

@test "applier - OSC 52 override is skipped on incapable terminals below 3.2" {
  _tmux_version_string() { echo "tmux 3.0"; }
  export TERM="dumb" TERM_PROGRAM=""
  run apply_sensible
  [[ "${output}" != *"Ms="* ]] || false
  [[ "${output}" != *"Ss="* ]]
}

@test "applier - allow-passthrough is on (not all) on tmux 3.3" {
  _tmux_version_string() { echo "tmux 3.3" ; }
  run apply_sensible
  [[ "${output}" == *"set -g allow-passthrough on"* ]] || false
  [[ "${output}" != *"allow-passthrough all"* ]]
}

@test "applier - allow-passthrough respects an explicit user value" {
  _get_option() { case "$1" in allow-passthrough) echo "on" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"allow-passthrough all"* ]]
}

@test "applier - hyperlinks feature appears on a capable terminal on 3.4+" {
  export TERM="xterm-kitty"
  run apply_sensible
  [[ "${output}" == *"set -as terminal-features ,*:hyperlinks"* ]]
}

@test "applier - default-terminal prefers tmux-direct with truecolor and terminfo" {
  run apply_sensible
  [[ "${output}" == *"set -g default-terminal tmux-direct"* ]]
}

@test "applier - default-terminal falls back to tmux-256color without direct terminfo" {
  _has_terminfo() { [[ "$1" == "tmux-256color" ]]; }
  run apply_sensible
  [[ "${output}" == *"set -g default-terminal tmux-256color"* ]]
}

@test "applier - default-terminal falls back to screen-256color without terminfo" {
  _has_terminfo() { return 1; }
  run apply_sensible
  [[ "${output}" == *"set -g default-terminal screen-256color"* ]]
}

@test "applier - default-terminal upgrades a screen-256color value" {
  _get_option() { case "$1" in default-terminal) echo "screen-256color" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" == *"set -g default-terminal tmux-direct"* ]]
}

@test "applier - default-terminal respects an explicit non-default value" {
  _get_option() { case "$1" in default-terminal) echo "rxvt-unicode-256color" ;; *) echo "" ;; esac; }
  _get_server_option() { case "$1" in default-terminal) echo "rxvt-unicode-256color" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"set -g default-terminal"* ]] || false
  [[ "${output}" != *"set -sg default-terminal"* ]]
}

@test "applier - extended-keys is skipped on unsupporting terminals" {
  export TERM="dumb" TERM_PROGRAM=""
  run apply_sensible
  [[ "${output}" != *"extended-keys"* ]]
}

@test "applier - extended-keys is enabled on a broadened terminal" {
  export TERM="alacritty" TERM_PROGRAM=""
  run apply_sensible
  [[ "${output}" == *"set -sg extended-keys on"* ]]
}

@test "applier - aggressive-resize on tmux 3.0+ syncs through attach and detach hooks" {
  # Arrange
  export TERM_PROGRAM="iTerm.app"

  # Act
  run apply_sensible

  # Assert
  [[ "${output}" == *"set-hook -g client-attached[1000] run-shell -b "* ]] || false
  [[ "${output}" == *"set-hook -g client-detached[1000] run-shell -b "* ]] || false
  [[ "${output}" == *"--resize-sync"* ]] || false
  [[ "${output}" == *"setw -g aggressive-resize on"* ]]
}

@test "applier - the resize hook never forces aggressive-resize on a normal client" {
  # Arrange
  local hook_lines

  # Act
  run apply_sensible

  # Assert
  hook_lines="$(printf '%s\n' "${output}" | grep 'set-hook')"
  [[ "${hook_lines}" != *"aggressive-resize on"* ]]
}

@test "applier - aggressive-resize is not turned on at load under a control-mode client" {
  # Arrange
  _control_client_count() { echo 1; }

  # Act
  run apply_sensible

  # Assert
  [[ "${output}" != *"setw -g aggressive-resize on"* ]] || false
  [[ "${output}" == *"client-attached[1000]"* ]]
}

@test "applier - the resize hook quotes a plugin path with a space, a quote, and a hash" {
  # Arrange
  local expected
  IFS= read -r expected <<'EXPECTED'
run-shell -b 'bash /tmp/x\ y\'"'"'z##w/src/sensible.sh --resize-sync'
EXPECTED
  export PLUGIN_DIR="/tmp/x y'z#w"

  # Act
  run _resize_sync_hook

  # Assert
  [ "${output}" = "${expected}" ]
}

@test "applier - resize_sync saves the value and turns it off for a control-mode client" {
  # Arrange
  _control_client_count() { echo 1; }
  _get_window_option() { case "$1" in aggressive-resize) echo "on" ;; *) echo "" ;; esac; }

  # Act
  run resize_sync

  # Assert
  [[ "${output}" == *"set -g @sensible_revamped_resize_saved on"* ]] || false
  [[ "${output}" == *"setw -g aggressive-resize off"* ]]
}

@test "applier - resize_sync keeps the first saved value while control clients remain" {
  # Arrange
  _control_client_count() { echo 2; }
  _get_option() { case "$1" in @sensible_revamped_resize_saved) echo "on" ;; *) echo "" ;; esac; }
  _get_window_option() { case "$1" in aggressive-resize) echo "off" ;; *) echo "" ;; esac; }

  # Act
  run resize_sync

  # Assert
  [[ "${output}" != *"@sensible_revamped_resize_saved"* ]] || false
  [[ "${output}" == *"setw -g aggressive-resize off"* ]]
}

@test "applier - resize_sync restores the saved value once no control-mode client remains" {
  # Arrange
  _get_option() { case "$1" in @sensible_revamped_resize_saved) echo "on" ;; *) echo "" ;; esac; }

  # Act
  run resize_sync

  # Assert
  [[ "${output}" == *"setw -g aggressive-resize on"* ]] || false
  [[ "${output}" == *"set -gu @sensible_revamped_resize_saved"* ]]
}

@test "applier - resize_sync is a no-op for a normal client with nothing saved" {
  # Arrange
  _get_option() { echo ""; }

  # Act
  run resize_sync

  # Assert
  [ -z "${output}" ]
}

@test "applier - older tmux sets aggressive-resize on outside iTerm2" {
  _tmux_version_string() { echo "tmux 2.9"; }
  run apply_sensible
  [[ "${output}" == *"aggressive-resize on"* ]] || false
  [[ "${output}" != *"client-attached"* ]]
}

@test "applier - explicit user configuration is respected" {
  _get_option() { case "$1" in history-limit) echo "9999" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"set -g history-limit 50000"* ]] || false
  [[ "${output}" == *"set -g status-interval 5"* ]]
}

@test "applier - set-clipboard respects an explicit user value" {
  _get_option() { case "$1" in set-clipboard) echo "off" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"set -g set-clipboard on"* ]]
}

@test "applier - focus-events respects an explicit user value" {
  _get_option() { case "$1" in focus-events) echo "off" ;; *) echo "" ;; esac; }
  _get_option() { case "$1" in focus-events) echo "on" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"set -g focus-events on"* ]]
}

@test "applier - status-keys respects an explicit vi value" {
  _get_option() { case "$1" in status-keys) echo "vi" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"set -g status-keys"* ]]
}

@test "applier - set-titles respects an explicit user value" {
  _get_option() { case "$1" in set-titles) echo "off" ;; *) echo "" ;; esac; }
  _get_option() { case "$1" in set-titles) echo "off-but-changed" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"set -g set-titles on"* ]]
}

@test "applier - word-separators is narrowed for clean path selection" {
  run apply_sensible
  [[ "${output}" == *"setw -g word-separators"* ]]
}

@test "applier - copy bindings use the resolved clipboard command" {
  _uname() { echo "Darwin"; }
  _have() { [[ "$1" == "pbcopy" ]]; }
  run apply_sensible
  [[ "${output}" == *"copy-pipe-and-cancel pbcopy"* ]]
}

@test "applier - copy bindings fall back to OSC52 without a tool" {
  _have() { return 1; }
  run apply_sensible
  [[ "${output}" == *"copy-selection-and-cancel"* ]] || false
  [[ "${output}" != *"copy-pipe-and-cancel"* ]]
}

@test "applier - vi selection keys are bound on tmux 2.4+" {
  run apply_sensible
  [[ "${output}" == *"bind-key -T copy-mode-vi v send-keys -X begin-selection"* ]] || false
  [[ "${output}" == *"bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle"* ]] || false
  [[ "${output}" == *"bind-key -T copy-mode-vi Enter send-keys -X copy-selection-and-cancel"* ]]
}

@test "applier - copy bindings use legacy tables below tmux 2.4" {
  _tmux_version_string() { echo "tmux 2.3"; }
  _uname() { echo "Darwin"; }
  _have() { [[ "$1" == "pbcopy" ]]; }
  run apply_sensible
  [[ "${output}" == *"bind-key -t vi-copy y copy-pipe pbcopy"* ]] || false
  [[ "${output}" == *"bind-key -t emacs-copy M-w copy-pipe pbcopy"* ]] || false
  [[ "${output}" == *"bind-key -t vi-copy v begin-selection"* ]] || false
  [[ "${output}" != *"copy-pipe-and-cancel"* ]]
}

@test "applier - legacy copy bindings fall back without a tool below 2.4" {
  _tmux_version_string() { echo "tmux 2.3"; }
  _have() { return 1; }
  run apply_sensible
  [[ "${output}" == *"bind-key -t vi-copy y copy-selection"* ]] || false
  [[ "${output}" == *"bind-key -t emacs-copy M-w copy-selection"* ]]
}

@test "applier - mode-keys follows the editor" {
  export EDITOR="nvim"
  run apply_sensible
  [[ "${output}" == *"mode-keys vi"* ]]
}

@test "applier - mode-keys respects an explicit user choice" {
  export EDITOR=""
  _get_window_option() { case "$1" in mode-keys) echo "vi" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"mode-keys"* ]]
}

@test "applier - opinionated noisy options are not forced" {
  run apply_sensible
  [[ "${output}" != *"monitor-activity"* ]] || false
  [[ "${output}" != *"set -g mouse"* ]]
}

@test "applier - macos reattach wrapper only when the helper is present" {
  _uname() { echo "Darwin"; }
  _have() { [[ "$1" == "reattach-to-user-namespace" ]]; }
  run apply_sensible
  [[ "${output}" == *"reattach-to-user-namespace -l \$SHELL"* ]]
}

@test "applier - reload binding is emitted on the reload key when it is free" {
  # Arrange
  local expected="bind-key R source-file ${TEST_TMPDIR}/.tmux.conf \\; display-message tmux-sensible-revamped: reloaded"
  _get_option() { [[ "${1}" == "@sensible_revamped_reload_key" ]] && echo "R"; }

  # Act
  run apply_sensible

  # Assert
  [[ "${output}" == *"${expected}"* ]]
}

@test "applier - binds window navigation when unbound" {
  run apply_sensible
  [[ "${output}" == *"bind-key C-p previous-window"* ]] || false
  [[ "${output}" == *"bind-key C-n next-window"* ]]
}

@test "applier - reload and last-window are unbound by default" {
  # Arrange
  _prefix() { echo "C-a"; }

  # Act
  run apply_sensible

  # Assert
  [[ "${output}" != *"last-window"* ]] || false
  [[ "${output}" != *"bind-key R source-file"* ]]
}

@test "applier - binds last-window on the last-window key when it is free" {
  # Arrange
  _get_option() { [[ "${1}" == "@sensible_revamped_last_window_key" ]] && echo "a"; }

  # Act
  run apply_sensible

  # Assert
  [[ "${output}" == *"bind-key a last-window"* ]]
}

@test "applier - binds send-prefix for a custom prefix" {
  _prefix() { echo "C-a"; }
  run apply_sensible
  [[ "${output}" == *"unbind-key C-b"* ]] || false
  [[ "${output}" == *"bind-key C-a send-prefix"* ]]
}

@test "applier - existing user bindings are respected" {
  _key_unbound() { return 1; }
  _get_option() { [[ "${1}" == "@sensible_revamped_reload_key" ]] && echo "R"; }
  run apply_sensible
  [[ "${output}" != *"bind-key C-p"* ]] || false
  [[ "${output}" != *"bind-key C-n"* ]] || false
  [[ "${output}" != *"bind-key R source-file"* ]]
}

@test "applier - keys off skips every convenience binding" {
  _get_option() { case "${1}" in @sensible_revamped_keys) echo "off" ;; @sensible_revamped_reload_key) echo "R" ;; @sensible_revamped_last_window_key) echo "b" ;; esac; }

  run apply_sensible

  [[ "${output}" != *"last-window"* ]] || false
  [[ "${output}" != *"bind-key C-p"* ]] || false
  [[ "${output}" != *"bind-key C-n"* ]] || false
  [[ "${output}" != *"bind-key R source-file"* ]]
}

@test "applier - keys off still wires a custom prefix" {
  _get_option() { [[ "${1}" == "@sensible_revamped_keys" ]] && echo "off"; }
  _prefix() { echo "C-a"; }

  run apply_sensible

  [[ "${output}" == *"unbind-key C-b"* ]] || false
  [[ "${output}" == *"bind-key C-a send-prefix"* ]] || false
  [[ "${output}" != *"bind-key a last-window"* ]]
}

@test "applier - keys off still applies the copy bindings" {
  _get_option() { [[ "${1}" == "@sensible_revamped_keys" ]] && echo "off"; }
  _have() { [[ "$1" == "xclip" ]]; }
  export DISPLAY=":0"

  run apply_sensible

  [[ "${output}" == *"bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel"* ]]
}

@test "applier - keys on binds the convenience keys" {
  _get_option() { case "${1}" in @sensible_revamped_keys) echo "on" ;; @sensible_revamped_reload_key) echo "R" ;; esac; }

  run apply_sensible

  [[ "${output}" == *"bind-key C-n next-window"* ]] || false
  [[ "${output}" == *"bind-key R source-file"* ]]
}

@test "applier - window and pane options respect explicit user values" {
  # Arrange
  _get_window_option() { case "$1" in pane-base-index) echo "5" ;; automatic-rename) echo "off" ;; *) echo "" ;; esac; }
  _get_option() { case "$1" in renumber-windows) echo "on" ;; *) echo "" ;; esac; }

  # Act
  run apply_sensible

  # Assert
  [[ "${output}" != *"pane-base-index"* ]] || false
  [[ "${output}" != *"automatic-rename"* ]] || false
  [[ "${output}" != *"renumber-windows"* ]]
}

@test "applier - default-command respects an explicit user value" {
  # Arrange
  _uname() { echo "Darwin"; }
  _have() { [[ "$1" == "reattach-to-user-namespace" ]]; }
  _get_option() { case "$1" in default-command) echo "/bin/zsh" ;; *) echo "" ;; esac; }

  # Act
  run apply_sensible

  # Assert
  [[ "${output}" != *"default-command"* ]]
}

@test "applier - extended-keys respects an explicit user value" {
  # Arrange
  _get_server_option() { case "$1" in extended-keys) echo "always" ;; extended-keys-format) echo "csi-u" ;; *) echo "" ;; esac; }

  # Act
  run apply_sensible

  # Assert
  [[ "${output}" != *"set -sg extended-keys on"* ]] || false
  [[ "${output}" != *"extended-keys-format"* ]]
}

@test "applier - older tmux aggressive-resize respects an explicit user value" {
  # Arrange
  _tmux_version_string() { echo "tmux 2.9"; }
  _get_window_option() { case "$1" in aggressive-resize) echo "on" ;; *) echo "" ;; esac; }

  # Act
  run apply_sensible

  # Assert
  [[ "${output}" != *"aggressive-resize"* ]]
}

@test "applier - escape-time respects an explicit user value" {
  _get_server_option() { case "$1" in escape-time) echo "100" ;; *) echo "" ;; esac; }
  run apply_sensible
  [[ "${output}" != *"escape-time 10"* ]]
}

@test "applier - older tmux skips aggressive-resize under iTerm2 via LC_TERMINAL" {
  _tmux_version_string() { echo "tmux 2.9"; }
  export LC_TERMINAL="iTerm2"
  run apply_sensible
  [[ "${output}" != *"aggressive-resize"* ]]
}

@test "applier - _emit runs tmux outside dry-run mode" {
  unset SENSIBLE_DRY_RUN
  tmux set-option -gq "@probe" "value123"
  run _emit show-option -gqv "@probe"
  [[ "${output}" == "value123" ]]
}

@test "applier - config path honors XDG_CONFIG_HOME" {
  mkdir -p "${TEST_TMPDIR}/xdg/tmux"
  : > "${TEST_TMPDIR}/xdg/tmux/tmux.conf"
  export XDG_CONFIG_HOME="${TEST_TMPDIR}/xdg"
  [[ "$(_config_path)" == "${TEST_TMPDIR}/xdg/tmux/tmux.conf" ]]
}

@test "applier - config path falls back to ~/.config then ~/.tmux.conf" {
  export XDG_CONFIG_HOME=""
  export HOME="${TEST_TMPDIR}"
  mkdir -p "${TEST_TMPDIR}/.config/tmux"
  : > "${TEST_TMPDIR}/.config/tmux/tmux.conf"
  [[ "$(_config_path)" == "${TEST_TMPDIR}/.config/tmux/tmux.conf" ]] || false
  rm -f "${TEST_TMPDIR}/.config/tmux/tmux.conf"
  [[ "$(_config_path)" == "${TEST_TMPDIR}/.tmux.conf" ]]
}

@test "applier - helper functions are defined" {
  function_exists apply_sensible
  function_exists _emit
  function_exists _set_default
  function_exists _set_default_terminal
  function_exists _apply_copy_bindings
  function_exists _config_path
}
