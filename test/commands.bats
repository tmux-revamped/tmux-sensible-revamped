#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/sensible_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/sensible_helpers.bash"

sends() {
  grep -vc -e '^show-option' -e '^list-keys' -e '^-V' -e '^list-clients' "${FAKE}/log" || :
}

@test "apply - every command goes to tmux in one call" {
  # Arrange
  has g @sensible_revamped_reload_key R

  # Act
  tool apply

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run sends
  [[ "${output}" == "1" ]]
  run grep -c '^set -g default-terminal screen-256color ; set -sg default-terminal screen-256color ; .* ; bind-key R source-file .* \\; display-message tmux-sensible-revamped: reloaded$' "${FAKE}/log"
  [[ "${output}" == "1" ]]
}

@test "apply - it reads tmux four times: the version, the options, the keys and the send" {
  # Arrange
  has g @sensible_revamped_keys off

  # Act
  tool apply

  # Assert
  run grep -c '' "${FAKE}/log"
  [[ "${output}" == "4" ]]
}

@test "apply - when tmux refuses the one call, it plans again and sends each command alone" {
  # Arrange
  : >"${FAKE}/refused"

  # Act
  tool apply

  # Assert
  [[ "${status}" -eq 0 ]]
  run sends
  [[ "${output}" == "36" ]]
  run sent '^show-option'
  [[ "${output}" == "2" ]]
  run sent '^set -g history-limit 50000$'
  [[ "${output}" == "1" ]]
}

@test "apply - one command tmux refuses fails the run and leaves the others sent" {
  # Arrange
  printf 'set -g history-limit 50000\n' >"${FAKE}/refused"

  # Act
  tool apply

  # Assert
  [[ "${status}" -eq 1 ]]
  run sent '^bind-key C-n next-window$'
  [[ "${output}" == "1" ]]
}

@test "apply - a setting given as an option or in the environment is used" {
  # Arrange
  export SENSIBLE_REVAMPED_LAST_WINDOW_KEY=a

  # Act
  tool --keys=on --reload-key R apply

  # Assert
  [[ "${status}" -eq 0 ]]
  run grep -c ' ; bind-key a last-window ; .* ; bind-key R source-file ' "${FAKE}/log"
  [[ "${output}" == "1" ]]
}

@test "resize-sync - a control-mode client turns aggressive-resize off in one call" {
  # Arrange
  printf '1\n' >"${FAKE}/clients"
  has w aggressive-resize on

  # Act
  tool resize-sync

  # Assert
  [[ "${status}" -eq 0 ]]
  run sent '^set -g @sensible_revamped_resize_saved on ; setw -g aggressive-resize off$'
  [[ "${output}" == "1" ]]
}

@test "resize-sync - a refused call is sent again, one command at a time" {
  # Arrange
  printf '0\n' >"${FAKE}/clients"
  has g @sensible_revamped_resize_saved on
  : >"${FAKE}/refused"

  # Act
  tool resize-sync

  # Assert
  [[ "${status}" -eq 0 ]]
  run sent '^setw -g aggressive-resize on$'
  [[ "${output}" == "1" ]]
  run sent '^set -gu @sensible_revamped_resize_saved$'
  [[ "${output}" == "1" ]]
}

@test "resize-sync - with nothing saved and no control-mode client it sends nothing" {
  # Arrange
  printf '0\n' >"${FAKE}/clients"

  # Act
  tool resize-sync

  # Assert
  [[ "${status}" -eq 0 ]]
  run sends
  [[ "${output}" == "0" ]]
}

@test "list - it prints one line per command and changes nothing" {
  # Arrange
  has g @sensible_revamped_keys off

  # Act
  tool list

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "set -g default-terminal screen-256color" ]]
  [[ "${#lines[@]}" -eq 33 ]]
  run sends
  [[ "${output}" == "0" ]]
}

@test "list - --json prints one object with every command's arguments" {
  # Arrange
  has g @sensible_revamped_keys off

  # Act
  tool --json list

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == '{"commands":[["set","-g","default-terminal","screen-256color"],'*',["bind-key","-T","copy-mode-vi","C-v","send-keys","-X","rectangle-toggle"]]}' ]]
}

@test "commands - --json with any command but list is a usage error" {
  # Arrange
  local expected="sensible-revamped: option '--json' works only with list. run 'sensible-revamped help' for usage."

  # Act
  tool --json apply

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "commands - an unknown option is a usage error, with or without a value" {
  # Arrange
  local expected="sensible-revamped: unknown option '--nope'. run 'sensible-revamped help' for usage."

  # Act
  tool --nope=1 list

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
  tool --nope
  [[ "${output}" == "${expected}" ]]
}

@test "commands - a setting option without its value is a usage error" {
  # Arrange
  local expected="sensible-revamped: option '--reload-key' needs a value. run 'sensible-revamped help' for usage."

  # Act
  tool --reload-key

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "commands - a single-dash option is a usage error" {
  # Arrange
  local expected="sensible-revamped: unknown option '-x'. run 'sensible-revamped help' for usage."

  # Act
  tool -x

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "commands - after -- a word is a command, never an option" {
  # Arrange
  local expected="sensible-revamped: unknown command '--keys'. run 'sensible-revamped help' for usage."

  # Act
  tool -- --keys

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "${expected}" ]]
}

@test "commands - --theme takes its value in both forms" {
  # Arrange
  local first

  # Act
  tool --theme nord version

  # Assert
  [[ "${status}" -eq 0 ]]
  first="${lines[0]}"
  tool --theme=nord version
  [[ "${lines[0]}" == "${first}" ]]
  [[ "${first}" == "sensible-revamped "* ]]
}

@test "doctor - it names the clipboard tool, the terminfo tool and that every key is free" {
  # Arrange
  tool_exists termux-clipboard-set
  export REVAMPED_TEST_TMUX_DIR

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ clipboard\ +ok\ +termux-clipboard-set ]]
  [[ "${output}" =~ infocmp\ +ok\ +"${BATS_TEST_TMPDIR}/stubs/infocmp" ]]
  [[ "${output}" =~ keys\ +ok\ +every\ key\ it\ binds\ is\ free\ or\ its\ own ]]
}

@test "doctor - it warns about a missing clipboard tool, a missing infocmp and each key left alone" {
  # Arrange
  rm -f "${BATS_TEST_TMPDIR}/stubs/infocmp" "${BATS_TEST_TMPDIR}/farm/infocmp"
  printf '%s\n' 'bind-key -T prefix C-p display-message mine' 'bind-key -T prefix C-n display-message mine' >"${FAKE}/keys"

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ clipboard\ +warn\ +no\ clipboard\ tool,\ so\ a\ copy\ goes\ through\ the\ terminal\ with\ OSC\ 52 ]]
  [[ "${output}" =~ infocmp\ +warn\ +without\ it\ default-terminal\ stays\ screen-256color ]]
  [[ "${output}" =~ keys\ +warn\ +already\ bound\ and\ left\ alone:\ C-p\ C-n ]]
}

@test "version - it prints the tool's version and tmux's" {
  # Arrange
  local version
  version=$(sed -n 's/^readonly SENSIBLE_REVAMPED_VERSION="\(.*\)"$/\1/p' "${REVAMPED_TESTS_DIR}/../lib/core.sh")

  # Act
  tool version

  # Assert
  [[ "${output}" == "sensible-revamped ${version}"$'\n'"tmux: 3.6" ]]
}
