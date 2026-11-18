#!/bin/sh
set -eu

repo="${1:?usage: sh .github/scripts/recover.sh <owner/repo>}"
here="$(cd "$(dirname "$0")" && pwd)"
poll_seconds="${RECOVER_POLL_SECONDS:-60}"
poll_limit="${RECOVER_POLL_LIMIT:-330}"
round_limit=6
head="$(git rev-parse HEAD)"
short="$(git rev-parse --short HEAD)"

fail() {
  printf '::error::%s\n' "$1" >&2
  exit 1
}

main_state() {
  state="$(sh "${here}/ci-state.sh" "${repo}")"
  printf 'main at %s is %s\n' "${short}" "${state}" >&2
  printf '%s\n' "${state}"
}

run_count() {
  gh api "repos/${repo}/actions/workflows/ci.yml/runs?head_sha=${head}&per_page=30" \
    -q '[.workflow_runs[] | select(.event == "push" or .event == "workflow_dispatch")] | length'
}

wait_for_new_run() {
  polls=0
  count="$(run_count)"
  while [ "${count}" -le "$1" ]; do
    [ "${polls}" -lt "${poll_limit}" ] || fail "the ci run started for ${short} never showed up"
    sleep "${poll_seconds}"
    polls=$((polls + 1))
    count="$(run_count)"
  done
}

settled_state() {
  polls=0
  state="$(main_state)"
  while [ "${state}" = running ]; do
    [ "${polls}" -lt "${poll_limit}" ] || fail "ci for ${short} was still running after ${polls} polls"
    sleep "${poll_seconds}"
    polls=$((polls + 1))
    state="$(main_state)"
  done
  printf '%s\n' "${state}"
}

release_if_current() {
  remote="$(git ls-remote origin refs/heads/main)"
  if [ "${remote%%[[:space:]]*}" = "${head}" ]; then
    printf 'sha=%s\n' "${head}" >>"${GITHUB_OUTPUT:?GITHUB_OUTPUT is not set}"
  else
    printf 'main moved past %s, so the ci run of the new commit releases it\n' "${short}" >&2
  fi
}

state="$(main_state)"
rounds=0
while [ "${state}" = lost ]; do
  [ "${rounds}" -lt "${round_limit}" ] || fail "${round_limit} restarted ci runs for ${short} never got a runner"
  before="$(run_count)"
  gh workflow run ci.yml --repo "${repo}" --ref main
  wait_for_new_run "${before}"
  state="$(settled_state)"
  rounds=$((rounds + 1))
done
case "${state}" in
release) release_if_current ;;
exhausted) fail "five ci runs for ${short} never got a runner; run gh workflow run ci.yml --ref main" ;;
*) ;;
esac
