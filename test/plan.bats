#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/sensible_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/sensible_helpers.bash"

lacks() {
  local line
  for line in "${lines[@]}"; do
    [[ "${line}" != *"$1"* ]] || return 1
  done
}

@test "plan - tmux 3.6 on a plain terminal gets every default, in order" {
  # Arrange
  local tool="'${REVAMPED_TESTS_DIR}/../bin/sensible-revamped'"

  # Act
  planned 'REVAMPED_PLATFORM_OS=Linux; '

  # Assert
  [[ "${lines[0]}" == "set -g default-terminal screen-256color" ]]
  [[ "${lines[1]}" == "set -sg default-terminal screen-256color" ]]
  [[ "${lines[2]}" == 'set -ga terminal-overrides ,*:Smulx=\E[4::%p1%dm' ]]
  [[ "${lines[3]}" == 'set -ga terminal-overrides ,*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m' ]]
  [[ "${lines[4]}" == "set -sg escape-time 10" ]]
  [[ "${lines[5]}" == "set -g focus-events on" ]]
  [[ "${lines[6]}" == "set -g set-clipboard on" ]]
  [[ "${lines[7]}" == "set -as terminal-features ,*:clipboard:ccolour:cstyle:focus:title" ]]
  [[ "${lines[8]}" == "set -as terminal-features ,rxvt*:ignorefkeys" ]]
  [[ "${lines[9]}" == "set -g allow-passthrough all" ]]
  [[ "${lines[10]}" == "set -sg extended-keys on" ]]
  [[ "${lines[11]}" == "set -sg extended-keys-format csi-u" ]]
  [[ "${lines[12]}" == "set -g history-limit 50000" ]]
  [[ "${lines[13]}" == "set -g display-time 4000" ]]
  [[ "${lines[14]}" == "set -g status-interval 5" ]]
  [[ "${lines[15]}" == "set -g repeat-time 1000" ]]
  [[ "${lines[16]}" == "set -g display-panes-time 2000" ]]
  [[ "${lines[17]}" == "set -g status-keys emacs" ]]
  [[ "${lines[18]}" == "set -g set-titles on" ]]
  [[ "${lines[19]}" == "setw -g word-separators  " ]]
  [[ "${lines[20]}" == "set -g base-index 1" ]]
  [[ "${lines[21]}" == "setw -g pane-base-index 1" ]]
  [[ "${lines[22]}" == "set -g renumber-windows on" ]]
  [[ "${lines[23]}" == "setw -g automatic-rename on" ]]
  [[ "${lines[24]}" == "setw -g aggressive-resize on" ]]
  [[ "${lines[25]}" == "set-hook -g client-attached[1000] run-shell -b \"${tool} resize-sync\"" ]]
  [[ "${lines[26]}" == "set-hook -g client-detached[1000] run-shell -b \"${tool} resize-sync\"" ]]
  [[ "${lines[27]}" == "setw -g mode-keys emacs" ]]
  [[ "${lines[28]}" == "bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel" ]]
  [[ "${lines[29]}" == "bind-key -T copy-mode-vi Enter send-keys -X copy-selection-and-cancel" ]]
  [[ "${lines[30]}" == "bind-key -T copy-mode M-w send-keys -X copy-selection-and-cancel" ]]
  [[ "${lines[31]}" == "bind-key -T copy-mode-vi v send-keys -X begin-selection" ]]
  [[ "${lines[32]}" == "bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle" ]]
  [[ "${lines[33]}" == "bind-key C-p previous-window" ]]
  [[ "${lines[34]}" == "bind-key C-n next-window" ]]
  [[ "${#lines[@]}" -eq 35 ]]
}

@test "plan - tmux 1.9 skips everything above its version and uses the old copy tables" {
  # Arrange
  tmux_is 1.9

  # Act
  planned 'REVAMPED_PLATFORM_OS=Linux; '

  # Assert
  has_line "set -g focus-events on"
  has_line "setw -g pane-base-index 1"
  has_line "set -g renumber-windows on"
  has_line "setw -g aggressive-resize on"
  has_line "bind-key -t vi-copy y copy-selection"
  has_line "bind-key -t emacs-copy M-w copy-selection"
  has_line "bind-key -t vi-copy v begin-selection"
  has_line "bind-key -t vi-copy C-v rectangle-toggle"
  lacks "terminal-features"
  lacks "Smulx"
  lacks "allow-passthrough"
  lacks "extended-keys"
  lacks "set-hook"
  lacks "copy-mode-vi"
}

@test "plan - tmux 1.5 has no pane-base-index, renumber-windows or focus-events" {
  # Arrange
  tmux_is 1.5

  # Act
  planned 'REVAMPED_PLATFORM_OS=Linux; '

  # Assert
  has_line "set -g base-index 1"
  lacks "pane-base-index"
  lacks "renumber-windows"
  lacks "focus-events"
}

@test "plan - truecolor is a terminal feature on tmux 3.2 and an override before it" {
  # Arrange
  export COLORTERM=truecolor TERM=xterm-256color
  terminfo "tmux-direct tmux-256color"
  local script='REVAMPED_PLATFORM_OS=Linux; sensible_revamped_plan; sensible_revamped_lines; printf "%s\n" 3.1 >"'"${FAKE}"'/version"; sensible_revamped_plan; sensible_revamped_lines'

  # Act
  lib_run sensible "${script}"

  # Assert
  has_line "set -g default-terminal tmux-direct"
  has_line "set -as terminal-features ,*:RGB"
  has_line "set -ga terminal-overrides ,*:Tc"
  has_line "set -as terminal-features xterm*:extkeys"
}

@test "plan - without COLORTERM and without terminfo no truecolor is claimed" {
  # Arrange
  export TERM=xterm-256color
  terminfo "tmux-256color"

  # Act
  planned 'REVAMPED_PLATFORM_OS=Linux; '

  # Assert
  has_line "set -g default-terminal tmux-256color"
  lacks ":RGB"
  lacks ":Tc"
}

@test "plan - a nested terminal is never claimed truecolor" {
  # Arrange
  export COLORTERM=truecolor TERM=screen-256color

  # Act
  planned 'REVAMPED_PLATFORM_OS=Linux; '

  # Assert
  lacks ":RGB"
}

@test "plan - a feature or override already present is not added again, in a list or one joined string" {
  # Arrange
  export COLORTERM=truecolor TERM=xterm-256color
  printf '%s\n' '*:RGB' '*:clipboard:ccolour:cstyle:focus:title' >"${FAKE}/opt/s.terminal-features"
  has g terminal-overrides 'xterm*:XT,*:Smulx=\E[4::%p1%dm'

  # Act
  planned 'REVAMPED_PLATFORM_OS=Linux; '

  # Assert
  lacks ":RGB"
  lacks "clipboard:ccolour"
  lacks "Smulx"
  has_line "set -as terminal-features ,rxvt*:ignorefkeys"
  has_line 'set -ga terminal-overrides ,*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'
}

@test "plan - below tmux 3.2 a capable terminal gets the OSC 52 and cursor shape overrides" {
  # Arrange
  tmux_is 3.1
  export TERM=xterm-256color
  local script='REVAMPED_PLATFORM_OS=Linux; sensible_revamped_plan; sensible_revamped_lines; TERM=dumb; sensible_revamped_plan; sensible_revamped_lines | grep -c "Ms=\|Ss="'

  # Act
  lib_run sensible "${script}"

  # Assert
  has_line 'set -ga terminal-overrides ,*:Ms=\E]52;%p1%s;%p2%s\007'
  has_line 'set -ga terminal-overrides ,*:Ss=\E[%p1%d q:Se=\E[2 q'
  [[ "${lines[${#lines[@]} - 1]}" == "0" ]]
}

@test "plan - allow-passthrough is on for tmux 3.3 and all from 3.4, where sixel and hyperlinks join" {
  # Arrange
  tmux_is 3.3
  export TERM=xterm-kitty
  local script='REVAMPED_PLATFORM_OS=Linux; sensible_revamped_plan; sensible_revamped_lines; printf "%s\n" 3.4 >"'"${FAKE}"'/version"; sensible_revamped_plan; sensible_revamped_lines'

  # Act
  lib_run sensible "${script}"

  # Assert
  has_line "set -g allow-passthrough on"
  has_line "set -g allow-passthrough all"
  has_line "set -as terminal-features ,*:sixel"
  has_line "set -as terminal-features ,*:hyperlinks"
  lacks "extended-keys-format"
}

@test "plan - every option the person set is left alone" {
  # Arrange
  has g default-terminal xterm-256color
  has s default-terminal xterm-256color
  has s escape-time 0
  has g focus-events on
  has g set-clipboard off
  has g allow-passthrough on
  has s extended-keys always
  has s extended-keys-format csi-u
  has g history-limit 9000
  has g display-time 1000
  has g status-interval 1
  has g repeat-time 300
  has g display-panes-time 500
  has g status-keys vi
  has g set-titles on
  has w word-separators ' -_@'
  has g base-index 1
  has w pane-base-index 1
  has g renumber-windows on
  has w automatic-rename off
  has w aggressive-resize on
  has w mode-keys vi

  # Act
  planned 'REVAMPED_PLATFORM_OS=Linux; '

  # Assert
  lacks "set -g default-terminal"
  lacks "set -sg default-terminal"
  lacks "escape-time"
  lacks "focus-events"
  lacks "set-clipboard"
  lacks "allow-passthrough"
  lacks "set -sg extended-keys"
  lacks "history-limit"
  lacks "display-time"
  lacks "status-interval"
  lacks "repeat-time"
  lacks "display-panes-time"
  lacks "status-keys"
  lacks "set-titles"
  lacks "word-separators"
  lacks "base-index"
  lacks "renumber-windows"
  lacks "automatic-rename"
  lacks "setw -g aggressive-resize"
  lacks "mode-keys"
}

@test "plan - an option still at tmux's own default is replaced" {
  # Arrange
  has g default-terminal screen-256color
  has s escape-time 500
  has g history-limit 2000
  has w word-separators '!"#$%&'"'"'()*+,-./:;<=>?@[\]^`{|}~'
  has w mode-keys emacs
  export EDITOR=vim

  # Act
  planned 'REVAMPED_PLATFORM_OS=Linux; '

  # Assert
  has_line "set -g default-terminal screen-256color"
  has_line "set -sg escape-time 10"
  has_line "set -g history-limit 50000"
  has_line "setw -g word-separators  "
  has_line "setw -g mode-keys vi"
}

@test "plan - a clipboard tool is piped to by the copy keys of both tables" {
  # Arrange
  tool_exists pbcopy

  # Act
  planned 'REVAMPED_PLATFORM_OS=Darwin; '

  # Assert
  has_line "bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel pbcopy"
  has_line "bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel pbcopy"
  has_line "bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel pbcopy"
  has_line "bind-key -T copy-mode M-w send-keys -X copy-pipe-and-cancel pbcopy"
  has_line "bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel pbcopy"
  lacks "copy-selection-and-cancel"
}

@test "plan - before tmux 2.4 a clipboard tool is piped to from the old tables" {
  # Arrange
  tmux_is 2.3
  tool_exists xclip
  export DISPLAY=:0

  # Act
  planned 'REVAMPED_PLATFORM_OS=Linux; '

  # Assert
  has_line "bind-key -t vi-copy y copy-pipe xclip -selection clipboard"
  has_line "bind-key -t emacs-copy M-w copy-pipe xclip -selection clipboard"
}

@test "plan - on macOS the reattach helper becomes the default command, only when it exists and none is set" {
  # Arrange
  tool_exists reattach-to-user-namespace
  local script='REVAMPED_PLATFORM_OS=Darwin; sensible_revamped_plan; sensible_revamped_lines | grep -c "default-command reattach-to-user-namespace -l \$SHELL"; REVAMPED_PLATFORM_OS=Linux; sensible_revamped_plan; sensible_revamped_lines | grep -c default-command; REVAMPED_PLATFORM_OS=Darwin; printf "zsh\n" >"'"${FAKE}"'/opt/g.default-command"; sensible_revamped_plan; sensible_revamped_lines | grep -c default-command; printf "[end]"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == $'1\n0\n0\n[end]' ]]
}

@test "plan - on macOS without the reattach helper no default command is set" {
  # Arrange
  local script='REVAMPED_PLATFORM_OS=Darwin; '

  # Act
  planned "${script}"

  # Assert
  lacks "default-command"
}

@test "plan - with a control-mode client attached, aggressive-resize is left off at load" {
  # Arrange
  printf '0\n1\n' >"${FAKE}/clients"

  # Act
  planned 'REVAMPED_PLATFORM_OS=Linux; '

  # Assert
  lacks "setw -g aggressive-resize"
  has_line "set-hook -g client-attached[1000] run-shell -b \"'${REVAMPED_TESTS_DIR}/../bin/sensible-revamped' resize-sync\""
}

@test "plan - before tmux 3.0 aggressive-resize is turned on, except under iTerm2" {
  # Arrange
  tmux_is 2.9
  local script='REVAMPED_PLATFORM_OS=Linux; sensible_revamped_plan; sensible_revamped_lines | grep -c "aggressive-resize on"; LC_TERMINAL=iTerm2; sensible_revamped_plan; sensible_revamped_lines | grep -c "aggressive-resize"; printf "[end]"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == $'1\n0\n[end]' ]]
}

@test "plan - a custom prefix unbinds C-b and sends itself, unless the key is bound already" {
  # Arrange
  has g prefix C-a
  local script='REVAMPED_PLATFORM_OS=Linux; sensible_revamped_plan; sensible_revamped_lines | grep "C-b\|send-prefix"; printf "bind-key -T prefix C-a send-prefix\n" >"'"${FAKE}"'/keys"; sensible_revamped_plan; sensible_revamped_lines | grep -c "send-prefix"; printf "[%s]" "${SENSIBLE_REVAMPED_SKIPPED}"; printf "bind-key -T prefix C-a display-message mine\n" >"'"${FAKE}"'/keys"; sensible_revamped_plan; sensible_revamped_lines | grep -c "send-prefix"; printf "[%s]" "${SENSIBLE_REVAMPED_SKIPPED}"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == $'unbind-key C-b\nbind-key C-a send-prefix\n0\n[]0\n[C-a]' ]]
}

@test "plan - a key this plugin bound on an earlier load is neither bound again nor named as skipped" {
  # Arrange
  has g @sensible_revamped_reload_key R
  printf '%s\n' 'bind-key -T prefix C-p previous-window' 'bind-key -T prefix C-n next-window' 'bind-key -T prefix R source-file /home/user/.tmux.conf \; display-message "tmux-sensible-revamped: reloaded"' >"${FAKE}/keys"
  local script='REVAMPED_PLATFORM_OS=Linux; sensible_revamped_plan; sensible_revamped_lines | grep -c "^bind-key [^-]"; printf "[%s]" "${SENSIBLE_REVAMPED_SKIPPED}"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == $'0\n[]' ]]
}

@test "plan - the last-window and reload keys are bound only when set" {
  # Arrange
  has g @sensible_revamped_last_window_key a
  has g @sensible_revamped_reload_key R

  # Act
  planned 'REVAMPED_PLATFORM_OS=Linux; '

  # Assert
  has_line "bind-key a last-window"
  has_line "bind-key C-p previous-window"
  has_line "bind-key C-n next-window"
  has_line "bind-key R source-file ${HOME}/.tmux.conf \\; display-message tmux-sensible-revamped: reloaded"
}

@test "plan - a key the person bound is left alone and named as skipped" {
  # Arrange
  has g @sensible_revamped_last_window_key a
  has g @sensible_revamped_reload_key R
  printf '%s\n' 'bind-key -T prefix C-p display-message mine' 'bind-key -T prefix R display-message mine' >"${FAKE}/keys"
  local script='REVAMPED_PLATFORM_OS=Linux; sensible_revamped_plan; sensible_revamped_lines | grep "^bind-key [^-]"; printf "[%s]" "${SENSIBLE_REVAMPED_SKIPPED}"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == $'bind-key a last-window\nbind-key C-n next-window\n[C-p R]' ]]
}

@test "plan - two settings naming one key bind it once, for the first action" {
  # Arrange
  has g @sensible_revamped_last_window_key R
  has g @sensible_revamped_reload_key R
  local script='REVAMPED_PLATFORM_OS=Linux; sensible_revamped_plan; sensible_revamped_lines | grep "^bind-key R"; printf "[%s]" "${SENSIBLE_REVAMPED_SKIPPED}"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == $'bind-key R last-window\n[R]' ]]
}

@test "plan - keys off skips the window keys and keeps the prefix and the copy keys" {
  # Arrange
  has g @sensible_revamped_keys off
  has g @sensible_revamped_reload_key R
  has g prefix C-Space

  # Act
  planned 'REVAMPED_PLATFORM_OS=Linux; '

  # Assert
  has_line "unbind-key C-b"
  has_line "bind-key C-Space send-prefix"
  has_line "bind-key -T copy-mode-vi v send-keys -X begin-selection"
  lacks "previous-window"
  lacks "next-window"
  lacks "source-file"
}

@test "sync - a control-mode client saves the value once and turns aggressive-resize off" {
  # Arrange
  printf '1\n' >"${FAKE}/clients"
  has w aggressive-resize on
  local script='sensible_revamped_plan_sync; sensible_revamped_lines; printf "off\n" >"'"${FAKE}"'/opt/w.aggressive-resize"; printf "on\n" >"'"${FAKE}"'/opt/g.@sensible_revamped_resize_saved"; sensible_revamped_plan_sync; sensible_revamped_lines'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == $'set -g @sensible_revamped_resize_saved on\nsetw -g aggressive-resize off\nsetw -g aggressive-resize off' ]]
}

@test "sync - with no value to read, off is what gets saved" {
  # Arrange
  printf '1\n' >"${FAKE}/clients"
  local script='sensible_revamped_plan_sync; sensible_revamped_lines'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${lines[0]}" == "set -g @sensible_revamped_resize_saved off" ]]
}

@test "sync - once no control-mode client is left the saved value comes back, and with none saved nothing happens" {
  # Arrange
  printf '0\n' >"${FAKE}/clients"
  has g @sensible_revamped_resize_saved on
  local script='sensible_revamped_plan_sync; sensible_revamped_lines; rm -f "'"${FAKE}"'/opt/g.@sensible_revamped_resize_saved"; sensible_revamped_plan_sync; sensible_revamped_lines; printf "[end]"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == $'setw -g aggressive-resize on\nset -gu @sensible_revamped_resize_saved\n[end]' ]]
}
