#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/sensible_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/sensible_helpers.bash"

@test "sensible - the tmux version is read past a prefix and a suffix" {
  # Arrange
  local script='for raw in "tmux 3.5a" "tmux next-3.6" "tmux 2.9" "tmux openbsd-7.5" "tmux master" ""; do printf "[%s]" "$(sensible_revamped_parse_version "${raw}")"; done'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "[3.5][3.6][2.9][7.5][][]" ]]
}

@test "sensible - versions compare by number, never as text" {
  # Arrange
  local script='for pair in "3.5 3.2" "3.2 3.2" "3.10 3.9" "2.9 3.0" "3.1 3.2" "10.0 9.9" " 3.2" "3.2 " "x 3.2"; do set -- ${pair}; if sensible_revamped_version_ge "${1:-}" "${2:-}"; then printf y; else printf n; fi; done'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "yyynnynnn" ]]
}

@test "sensible - truecolor follows COLORTERM, then terminfo, and never a nested terminal" {
  # Arrange
  terminfo "" "xterm-direct"
  local script='probe() { if sensible_revamped_truecolor; then printf y; else printf n; fi; }
    SENSIBLE_REVAMPED_TERM=xterm COLORTERM=truecolor probe
    SENSIBLE_REVAMPED_TERM=xterm COLORTERM=24bit probe
    SENSIBLE_REVAMPED_TERM=xterm COLORTERM=other probe
    SENSIBLE_REVAMPED_TERM=xterm-direct COLORTERM= probe
    SENSIBLE_REVAMPED_TERM=xterm COLORTERM= probe
    SENSIBLE_REVAMPED_TERM=screen-256color COLORTERM=truecolor probe
    SENSIBLE_REVAMPED_TERM=tmux-256color COLORTERM=truecolor probe'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "yynynnn" ]]
}

@test "sensible - each terminal capability is known by program or by TERM" {
  # Arrange
  local script='row() { for check in extended_keys osc52 cursor sixel hyperlink; do if "sensible_revamped_${check}_terminal"; then printf y; else printf n; fi; done; printf " "; }
    SENSIBLE_REVAMPED_TERM=dumb SENSIBLE_REVAMPED_PROGRAM=ghostty row
    SENSIBLE_REVAMPED_TERM=dumb SENSIBLE_REVAMPED_PROGRAM=mintty row
    SENSIBLE_REVAMPED_TERM=xterm-256color SENSIBLE_REVAMPED_PROGRAM= row
    SENSIBLE_REVAMPED_TERM=xterm-kitty SENSIBLE_REVAMPED_PROGRAM= row
    SENSIBLE_REVAMPED_TERM=tmux-256color SENSIBLE_REVAMPED_PROGRAM= row
    SENSIBLE_REVAMPED_TERM=vte-256color SENSIBLE_REVAMPED_PROGRAM= row
    SENSIBLE_REVAMPED_TERM=mlterm SENSIBLE_REVAMPED_PROGRAM= row
    SENSIBLE_REVAMPED_TERM=alacritty SENSIBLE_REVAMPED_PROGRAM= row
    SENSIBLE_REVAMPED_TERM=dumb SENSIBLE_REVAMPED_PROGRAM= row'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "yyyyy yyyny yyyyn yyyyy nynnn nnyny nnnyn yyyny nnnnn " ]]
}

@test "sensible - iTerm2 is known by either variable" {
  # Arrange
  local script='probe() { if sensible_revamped_iterm; then printf y; else printf n; fi; }
    SENSIBLE_REVAMPED_PROGRAM=iTerm.app LC_TERMINAL= probe
    SENSIBLE_REVAMPED_PROGRAM= LC_TERMINAL=iTerm2 probe
    SENSIBLE_REVAMPED_PROGRAM=ghostty LC_TERMINAL= probe'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "yyn" ]]
}

@test "sensible - the default terminal is tmux-direct, then tmux-256color, then screen-256color" {
  # Arrange
  terminfo "tmux-direct tmux-256color"
  local script='sensible_revamped_terminal_name 1; sensible_revamped_terminal_name 0'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == $'tmux-direct\ntmux-256color' ]]
}

@test "sensible - without terminfo entries the default terminal is screen-256color" {
  # Arrange
  local script='sensible_revamped_terminal_name 1'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "screen-256color" ]]
}

@test "sensible - only an empty or screen default terminal counts as unset" {
  # Arrange
  local script='for value in "" screen screen-256color xterm-256color tmux-256color; do if sensible_revamped_terminal_unset "${value}"; then printf y; else printf n; fi; done'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "yyynn" ]]
}

@test "sensible - a vi editor in EDITOR or VISUAL means vi copy-mode keys" {
  # Arrange
  local script='EDITOR=nvim VISUAL= sensible_revamped_mode_keys; EDITOR= VISUAL=vim sensible_revamped_mode_keys; EDITOR=nano VISUAL= sensible_revamped_mode_keys; EDITOR= VISUAL= sensible_revamped_mode_keys'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == $'vi\nvi\nemacs\nemacs' ]]
}

@test "sensible - the clipboard tool is picked by priority" {
  # Arrange
  tool_exists wl-copy
  tool_exists termux-clipboard-set
  tool_exists pbcopy
  tool_exists xclip
  tool_exists xsel
  local stubs="${BATS_TEST_TMPDIR}/stubs"
  local script='REVAMPED_PLATFORM_OS=Darwin
    WAYLAND_DISPLAY=w DISPLAY=:0 sensible_revamped_clipboard
    WAYLAND_DISPLAY= DISPLAY=:0 sensible_revamped_clipboard
    rm -f "'"${stubs}"'/termux-clipboard-set"; hash -r
    WAYLAND_DISPLAY= DISPLAY=:0 sensible_revamped_clipboard
    rm -f "'"${stubs}"'/pbcopy"; hash -r
    WAYLAND_DISPLAY= DISPLAY=:0 sensible_revamped_clipboard
    rm -f "'"${stubs}"'/xclip"; hash -r
    WAYLAND_DISPLAY= DISPLAY=:0 sensible_revamped_clipboard
    WAYLAND_DISPLAY= DISPLAY= sensible_revamped_clipboard
    printf "[end]"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == $'wl-copy\ntermux-clipboard-set\npbcopy\nxclip -selection clipboard\nxsel -ib\n[end]' ]]
}

@test "sensible - pbcopy is ignored off macOS, and clip.exe is used only under WSL" {
  # Arrange
  tool_exists pbcopy
  tool_exists clip.exe
  printf 'Linux version 6.6 (Microsoft@Microsoft.com) WSL2\n' >"${BATS_TEST_TMPDIR}/wsl"
  printf 'Linux version 6.8 (buildd@lcy02)\n' >"${BATS_TEST_TMPDIR}/linux"
  local script='REVAMPED_PLATFORM_OS=Linux
    SENSIBLE_REVAMPED_PROC_VERSION="'"${BATS_TEST_TMPDIR}"'/wsl"; sensible_revamped_clipboard
    SENSIBLE_REVAMPED_PROC_VERSION="'"${BATS_TEST_TMPDIR}"'/linux"; sensible_revamped_clipboard
    SENSIBLE_REVAMPED_PROC_VERSION="'"${BATS_TEST_TMPDIR}"'/none"; sensible_revamped_clipboard
    REVAMPED_PLATFORM_OS=Darwin; rm -f "'"${BATS_TEST_TMPDIR}"'/stubs/pbcopy"; hash -r; SENSIBLE_REVAMPED_PROC_VERSION="'"${BATS_TEST_TMPDIR}"'/wsl"; sensible_revamped_clipboard
    printf "[end]"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == $'clip.exe\n[end]' ]]
}

@test "sensible - the config file is the XDG one, then ~/.config, then ~/.tmux.conf" {
  # Arrange
  mkdir -p "${BATS_TEST_TMPDIR}/xdg/tmux" "${HOME}/.config/tmux"
  : >"${BATS_TEST_TMPDIR}/xdg/tmux/tmux.conf"
  : >"${HOME}/.config/tmux/tmux.conf"
  local script='XDG_CONFIG_HOME="'"${BATS_TEST_TMPDIR}"'/xdg" sensible_revamped_config; XDG_CONFIG_HOME="'"${BATS_TEST_TMPDIR}"'/empty" sensible_revamped_config; XDG_CONFIG_HOME= sensible_revamped_config; rm -f "${HOME}/.config/tmux/tmux.conf"; sensible_revamped_config'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "${BATS_TEST_TMPDIR}/xdg/tmux/tmux.conf"$'\n'"${HOME}/.config/tmux/tmux.conf"$'\n'"${HOME}/.config/tmux/tmux.conf"$'\n'"${HOME}/.tmux.conf" ]]
}

@test "sensible - the tool path is quoted for sh, then for a tmux string, with hashes doubled" {
  # Arrange
  local script='REVAMPED_LIB="/a b/it'"'"'s #1 \"x\" \$y/lib"; sensible_revamped_tool'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "'/a b/it'\\\\''s ##1 \\\"x\\\" \\\$y/bin/sensible-revamped'" ]]
}

@test "sensible - every option is read in one tmux call, a list joined by commas" {
  # Arrange
  has g history-limit 9000
  has s escape-time 0
  has w mode-keys vi
  printf '%s\n' ',*:RGB' ',xterm*:extkeys' >"${FAKE}/opt/s.terminal-features"
  printf '0\n1\n' >"${FAKE}/clients"
  local script='sensible_revamped_read "${SENSIBLE_REVAMPED_READS}"; printf "[%s]" "${SENSIBLE_REVAMPED_O_g_history_limit}" "${SENSIBLE_REVAMPED_O_s_escape_time}" "${SENSIBLE_REVAMPED_O_w_mode_keys}" "${SENSIBLE_REVAMPED_O_s_terminal_features}" "${SENSIBLE_REVAMPED_O_g_base_index}" "${SENSIBLE_REVAMPED_O_clients}" "${SENSIBLE_REVAMPED_O_marks}"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "[9000][0][vi][,*:RGB,,xterm*:extkeys][][0,1][ok]" ]]
  run sent '^show-option'
  [[ "${output}" == "1" ]]
}

@test "sensible - when tmux refuses the one call, each option is read alone" {
  # Arrange
  has g history-limit 9000
  has w word-separators ' '
  : >"${FAKE}/unchained"
  local script='sensible_revamped_read "${SENSIBLE_REVAMPED_READS}"; printf "[%s]" "${SENSIBLE_REVAMPED_O_g_history_limit}" "${SENSIBLE_REVAMPED_O_w_word_separators}" "${SENSIBLE_REVAMPED_O_marks}"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "[9000][ ][ok]" ]]
  run sent '^show-option'
  [[ "${output}" == "32" ]]
}

@test "sensible - the terminal is the one tmux started in, since tmux hands a plugin its own TERM" {
  # Arrange
  printf '%s\n' 'COLORTERM=truecolor' 'TERM=xterm-kitty' 'TERM_PROGRAM=ghostty' 'TERM_PROGRAM_VERSION=1.2' >"${FAKE}/environment"
  export TERM=tmux-256color TERM_PROGRAM=tmux
  local script='sensible_revamped_read "${SENSIBLE_REVAMPED_READS}"; sensible_revamped_terminal; printf "[%s]" "${SENSIBLE_REVAMPED_TERM}" "${SENSIBLE_REVAMPED_PROGRAM}" "${SENSIBLE_REVAMPED_O_marks}"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "[xterm-kitty][ghostty][ok]" ]]
}

@test "sensible - a server with no TERM of its own means no terminal is known, and no server means this shell's" {
  # Arrange
  printf '%s\n' 'HOME=/home/user' >"${FAKE}/environment"
  export TERM=xterm-256color TERM_PROGRAM=WezTerm
  local script='sensible_revamped_read "${SENSIBLE_REVAMPED_READS}"; sensible_revamped_terminal; printf "[%s]" "${SENSIBLE_REVAMPED_TERM}" "${SENSIBLE_REVAMPED_PROGRAM}"; rm -f "'"${FAKE}"'/environment"; sensible_revamped_read "${SENSIBLE_REVAMPED_READS}"; sensible_revamped_terminal; printf "[%s]" "${SENSIBLE_REVAMPED_TERM}" "${SENSIBLE_REVAMPED_PROGRAM}"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "[][][xterm-256color][WezTerm]" ]]
}

@test "sensible - a setting comes from the environment before the tmux option, and keys default to on" {
  # Arrange
  has g @sensible_revamped_reload_key R
  has g @sensible_revamped_last_window_key a
  export SENSIBLE_REVAMPED_LAST_WINDOW_KEY=b SENSIBLE_REVAMPED_KEYS=off
  local script='sensible_revamped_read "${SENSIBLE_REVAMPED_READS}"; sensible_revamped_settings; printf "[%s]" "${SENSIBLE_REVAMPED_S_keys}" "${SENSIBLE_REVAMPED_S_last_window_key}" "${SENSIBLE_REVAMPED_S_reload_key}"; unset SENSIBLE_REVAMPED_KEYS; sensible_revamped_settings; printf "[%s]" "${SENSIBLE_REVAMPED_S_keys}"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "[off][b][R][on]" ]]
}

@test "sensible - a key counts as held only in the prefix table, however tmux quotes it" {
  # Arrange
  cat >"${FAKE}/keys" <<'KEYS'
bind-key    -T copy-mode    C-n               send-keys -X cursor-down
bind-key    -T prefix       C-p               previous-window
bind-key -r -T prefix       Up                select-pane -U
bind-key    -T prefix       \\                split-window -h
bind-key    -T prefix       \#                list-buffers
bind-key    -T prefix       '"'               split-window
bind-key    -T root         R                 display-message root
bind-key -n F5 display-message old-root
bind-key a last-window
KEYS
  local want=$'C-n\tnext-window\nC-p\tprevious-window\nUp\tselect-pane -U\n\\\tmine\n#\tmine\n"\tsplit-window\nR\tx\nF5\tx\n\tskipped\na\tlast-window\nzz\tx'
  export WANT="${want}"
  local script='sensible_revamped_held "${WANT}" | tr "\t" "|"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == 'C-p Up \ # " a |\ # ' ]]
}

@test "sensible - a plan prints as lines, as JSON and as a count, and keeps an argument that is one space" {
  # Arrange
  local script='SENSIBLE_REVAMPED_PLAN=""; sensible_revamped_emit setw -g word-separators " "; sensible_revamped_emit set -g status-left "a \"b\" \\c"; sensible_revamped_lines; sensible_revamped_json; sensible_revamped_count'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${lines[0]}" == "setw -g word-separators  " ]]
  [[ "${lines[1]}" == 'set -g status-left a "b" \c' ]]
  [[ "${lines[2]}" == '{"commands":[["setw","-g","word-separators"," "],["set","-g","status-left","a \"b\" \\c"]]}' ]]
  [[ "${lines[3]}" == "2" ]]
}

@test "sensible - an empty plan prints nothing and sends nothing" {
  # Arrange
  local script='SENSIBLE_REVAMPED_PLAN=""; sensible_revamped_lines; sensible_revamped_json; sensible_revamped_count; sensible_revamped_send; sensible_revamped_send_each; printf "[%s]" "$?"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == '{"commands":[]}'$'\n''0'$'\n''[0]' ]]
  [[ ! -s "${FAKE}/log" ]]
}

@test "sensible - a setting name comes from its long option" {
  # Arrange
  local script='printf "[%s]" "$(sensible_revamped_setting_name --last-window-key)" "$(sensible_revamped_setting_name --keys)" "$(sensible_revamped_setting_name --nope)"'

  # Act
  lib_run sensible "${script}"

  # Assert
  [[ "${output}" == "[last_window_key][keys][]" ]]
}
