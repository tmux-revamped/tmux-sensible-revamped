#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031

@test "docs - every relative README link points at an existing path" {
  # Arrange
  local repo="${BATS_TEST_DIRNAME:-.}/.."
  local target missing=""

  local links
  links="$(grep -oE '\]\([^)]+\)' "${repo}/README.md")"

  # Act
  while IFS= read -r target; do
    target="${target#](}"
    target="${target%)}"
    case "${target}" in
    '' | http://* | https://* | mailto:* | '#'*) continue ;;
    *) ;;
    esac
    [[ -e "${repo}/${target%%#*}" ]] || missing="${missing} ${target}"
  done <<<"${links}"

  # Assert
  [[ -z "${missing}" ]]
}
