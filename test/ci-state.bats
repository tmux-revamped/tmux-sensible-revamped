#!/usr/bin/env bats

setup() {
  SCRIPT="$(cd "${BATS_TEST_DIRNAME:-.}/.." && pwd)/.github/scripts/ci-state.sh"
  WORK="$(mktemp -d "${BATS_TMPDIR:-/tmp}/ci-state.XXXXXX")"
  FAKE_GH="${WORK}/gh-answers"
  mkdir -p "${WORK}/bin" "${FAKE_GH}" "${WORK}/repo" "${WORK}/home"
  export FAKE_GH
  export HOME="${WORK}/home"
  ci_state_fake_gh
  PATH="${WORK}/bin:${PATH}"
  git -C "${WORK}/repo" init -q
  git -C "${WORK}/repo" config user.name "ci-state test"
  git -C "${WORK}/repo" config user.email ""
  git -C "${WORK}/repo" config commit.gpgsign false
  git -C "${WORK}/repo" config tag.gpgsign false
}

teardown() {
  rm -rf "${WORK:?}"
}

ci_state_fake_gh() {
  cat >"${WORK}/bin/gh" <<'GH'
#!/bin/sh
case "$2" in
*/workflows/ci.yml/runs*) answer=runs ;;
*/jobs*) answer=jobs ;;
*/annotations) answer="annotations-$(basename "$(dirname "$2")")" ;;
*) answer=unknown ;;
esac
cat "${FAKE_GH}/${answer}"
GH
  chmod +x "${WORK}/bin/gh"
}

ci_state_commit() {
  git -C "${WORK}/repo" commit -q --allow-empty -m "$1"
}

ci_state_answer() {
  printf '%s\n' "$2" >"${FAKE_GH}/$1"
}

ci_state_run() {
  cd "${WORK}/repo" || return 1
  run sh "${SCRIPT}" octocat/member
}

@test "a commit with no ci run reports none" {
  # Arrange
  ci_state_commit "feat: add a command"
  ci_state_answer runs ""

  # Act
  ci_state_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == none ]]
}

@test "a ci run still going reports running" {
  # Arrange
  ci_state_commit "feat: add a command"
  ci_state_answer runs "101 push in_progress null"

  # Act
  ci_state_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == running ]]
}

@test "a green commit with a feature since the last tag reports release" {
  # Arrange
  ci_state_commit "fix: first"
  git -C "${WORK}/repo" tag v1.0.0
  ci_state_commit "feat(cli): add a command"
  ci_state_answer runs "102 push completed success"

  # Act
  ci_state_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == release ]]
}

@test "a green commit with only docs since the last tag reports current" {
  # Arrange
  ci_state_commit "feat: first"
  git -C "${WORK}/repo" tag v1.0.0
  ci_state_commit "docs: explain the command"
  ci_state_commit "chore(deps): bump a tool"
  ci_state_answer runs "103 push completed success"

  # Act
  ci_state_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == current ]]
}

@test "a green commit with a breaking change in a body reports release" {
  # Arrange
  ci_state_commit "docs: first"
  git -C "${WORK}/repo" tag v1.0.0
  ci_state_commit "$(printf 'refactor: drop an option\n\nBREAKING CHANGE: --old is gone')"
  ci_state_answer runs "104 workflow_dispatch completed success"

  # Act
  ci_state_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == release ]]
}

@test "a green commit with no tag yet and a fix reports release" {
  # Arrange
  ci_state_commit "fixes: not a conventional type"
  ci_state_commit "fix: correct the size"
  ci_state_answer runs "105 push completed success"

  # Act
  ci_state_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == release ]]
}

@test "a run with a job that failed on a runner reports failed" {
  # Arrange
  ci_state_commit "feat: add a command"
  ci_state_answer runs "106 push completed failure"
  ci_state_answer jobs "$(printf '%s\n' "11 failure GitHub-Actions-7" "12 cancelled GitHub-Actions-8")"

  # Act
  ci_state_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == failed ]]
}

@test "a run whose job never got a runner reports lost" {
  # Arrange
  ci_state_commit "feat: add a command"
  ci_state_answer runs "107 push completed failure"
  ci_state_answer jobs "$(printf '%s\n' "21 success GitHub-Actions-1" "22 cancelled -" "23 skipped -")"
  ci_state_answer annotations-22 "The job was not acquired by Runner of type hosted even after multiple attempts"

  # Act
  ci_state_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == lost ]]
}

@test "a job cancelled before it started for another reason reports failed" {
  # Arrange
  ci_state_commit "feat: add a command"
  ci_state_answer runs "108 push completed cancelled"
  ci_state_answer jobs "31 cancelled -"
  ci_state_answer annotations-31 "The run was canceled by a user."

  # Act
  ci_state_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == failed ]]
}

@test "five restarted runs that never got a runner report exhausted" {
  # Arrange
  ci_state_commit "feat: add a command"
  ci_state_answer runs "$(printf '%s\n' \
    "115 workflow_dispatch completed failure" "114 workflow_dispatch completed failure" \
    "113 workflow_dispatch completed failure" "112 workflow_dispatch completed failure" \
    "111 workflow_dispatch completed failure" "110 push completed failure")"
  ci_state_answer jobs "41 cancelled -"
  ci_state_answer annotations-41 "The job was not acquired by Runner of type hosted even after multiple attempts"

  # Act
  ci_state_run

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == exhausted ]]
}

@test "a GitHub API error stops the script instead of guessing" {
  # Arrange
  ci_state_commit "feat: add a command"
  ci_state_answer runs "116 push completed failure"

  # Act
  ci_state_run

  # Assert
  [[ "${status}" -ne 0 ]]
  [[ "${output}" != failed ]]
}

@test "a missing repository argument prints the usage" {
  # Arrange
  cd "${WORK}/repo" || return 1

  # Act
  run sh "${SCRIPT}"

  # Assert
  [[ "${status}" -ne 0 ]]
  [[ "${output}" == *"usage: sh .github/scripts/ci-state.sh <owner/repo>"* ]]
}
