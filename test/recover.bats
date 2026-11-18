#!/usr/bin/env bats

setup() {
  SOURCE="$(cd "${BATS_TEST_DIRNAME:-.}/.." && pwd)/.github/scripts/recover.sh"
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/recover.XXXXXX")"
  mkdir -p "${WORK}/bin" "${WORK}/scripts" "${WORK}/answers" "${WORK}/home"
  export HOME="${WORK}/home"
  export ANSWERS="${WORK}/answers"
  export GITHUB_OUTPUT="${WORK}/github-output"
  export RECOVER_POLL_SECONDS=0
  export RECOVER_POLL_LIMIT=3
  : >"${GITHUB_OUTPUT}"
  : >"${ANSWERS}/dispatched"
  cp -f "${SOURCE}" "${WORK}/scripts/recover.sh"
  recover_fakes
  PATH="${WORK}/bin:${PATH}"
  recover_repos
}

teardown() {
  rm -rf "${WORK:?}"
}

recover_fakes() {
  cat >"${WORK}/bin/answer" <<'POP'
#!/bin/sh
file="${ANSWERS}/$1"
first="$(head -n 1 "${file}")"
rest="$(tail -n +2 "${file}")"
[ -n "${rest}" ] && printf '%s\n' "${rest}" >"${file}"
printf '%s\n' "${first}"
POP
  cat >"${WORK}/scripts/ci-state.sh" <<'STATE'
#!/bin/sh
answer states
STATE
  cat >"${WORK}/bin/gh" <<'GH'
#!/bin/sh
case "$1 $2" in
"workflow run") printf '%s\n' "$*" >>"${ANSWERS}/dispatched" ;;
"api "*/workflows/ci.yml/runs*) answer counts ;;
*) exit 64 ;;
esac
GH
  chmod +x "${WORK}/bin/answer" "${WORK}/bin/gh"
}

recover_repos() {
  git init -q --bare "${WORK}/origin.git"
  git init -q -b main "${WORK}/repo"
  git -C "${WORK}/repo" config user.name "recover test"
  git -C "${WORK}/repo" config user.email ""
  git -C "${WORK}/repo" config commit.gpgsign false
  git -C "${WORK}/repo" commit -q --allow-empty -m "feat: add a command"
  git -C "${WORK}/repo" remote add origin "${WORK}/origin.git"
  git -C "${WORK}/repo" push -q origin main
  HEAD_SHA="$(git -C "${WORK}/repo" rev-parse HEAD)"
}

recover_answer() {
  printf '%s\n' "${@:2}" >"${ANSWERS}/$1"
}

recover_run() {
  cd "${WORK}/repo" || return 1
  run sh "${WORK}/scripts/recover.sh" octocat/member
  DISPATCHES=0
  while IFS= read -r _; do
    DISPATCHES=$((DISPATCHES + 1))
  done <"${ANSWERS}/dispatched"
  WRITTEN="$(<"${GITHUB_OUTPUT}")"
}

@test "a lost run is restarted and the green restart is handed to the release" {
  # Arrange
  recover_answer states lost running release
  recover_answer counts 1 1 2

  # Act
  recover_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${DISPATCHES}" -eq 1 ]]
  [[ "${WRITTEN}" == "sha=${HEAD_SHA}" ]]
}

@test "a restart that loses its runner again is restarted again" {
  # Arrange
  recover_answer states lost lost release
  recover_answer counts 1 2 2 3

  # Act
  recover_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${DISPATCHES}" -eq 2 ]]
  [[ "${WRITTEN}" == "sha=${HEAD_SHA}" ]]
}

@test "a restart that fails for real hands nothing to the release" {
  # Arrange
  recover_answer states lost failed
  recover_answer counts 1 2

  # Act
  recover_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${DISPATCHES}" -eq 1 ]]
  [[ -z "${WRITTEN}" ]]
}

@test "a run still going is left to its own completion" {
  # Arrange
  recover_answer states running

  # Act
  recover_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${DISPATCHES}" -eq 0 ]]
  [[ -z "${WRITTEN}" ]]
}

@test "a released commit with nothing new does nothing" {
  # Arrange
  recover_answer states current

  # Act
  recover_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${DISPATCHES}" -eq 0 ]]
  [[ -z "${WRITTEN}" ]]
}

@test "five restarts that never got a runner fail visibly" {
  # Arrange
  recover_answer states exhausted

  # Act
  recover_run

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"::error::five ci runs for "*" never got a runner"* ]]
  [[ "${DISPATCHES}" -eq 0 ]]
}

@test "a green commit that main has moved past is not released" {
  # Arrange
  recover_answer states release
  git -C "${WORK}/repo" commit -q --allow-empty -m "fix: newer"
  git -C "${WORK}/repo" push -q origin main
  git -C "${WORK}/repo" reset -q --hard HEAD~1

  # Act
  recover_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${WRITTEN}" ]]
  [[ "${output}" == *"main moved past"* ]]
}

@test "a restart that never shows up fails instead of waiting forever" {
  # Arrange
  recover_answer states lost
  recover_answer counts 1 1 1 1 1

  # Act
  recover_run

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"never showed up"* ]]
}

@test "a restart that keeps running past the limit fails instead of waiting forever" {
  # Arrange
  recover_answer states lost running running running running running
  recover_answer counts 1 2

  # Act
  recover_run

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"was still running after 3 polls"* ]]
}

@test "restarts stop after six rounds even if every run is lost" {
  # Arrange
  recover_answer states lost lost lost lost lost lost lost
  recover_answer counts 1 2 2 3 3 4 4 5 5 6 6 7

  # Act
  recover_run

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"6 restarted ci runs for "*" never got a runner"* ]]
  [[ "${DISPATCHES}" -eq 6 ]]
}

@test "a missing repository argument prints the usage" {
  # Arrange
  cd "${WORK}/repo" || return 1

  # Act
  run sh "${WORK}/scripts/recover.sh"

  # Assert
  [[ "${status}" -ne 0 ]]
  [[ "${output}" == *"usage: sh .github/scripts/recover.sh <owner/repo>"* ]]
}
