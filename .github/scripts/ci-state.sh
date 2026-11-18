#!/bin/sh
set -eu

repo="${1:?usage: sh .github/scripts/ci-state.sh <owner/repo>}"
dispatch_limit=5
lost_text='was not acquired by Runner'
release_subject='^(feat|fix|perf|revert)([(][^)]*[)])?: |^BREAKING CHANGE'

releasable_commits() {
  base="$(git describe --tags --abbrev=0 HEAD 2>/dev/null || true)"
  range=HEAD
  [ -z "${base}" ] || range="${base}..HEAD"
  log="$(git log --format='%s%n%b' "${range}")"
  printf '%s\n' "${log}" | awk -v pattern="${release_subject}" '$0 ~ pattern { n++ } END { print n + 0 }'
}

ci_runs() {
  gh api "repos/${repo}/actions/workflows/ci.yml/runs?head_sha=$1&per_page=30" \
    -q '.workflow_runs[] | select(.event == "push" or .event == "workflow_dispatch") | "\(.id) \(.event) \(.status) \(.conclusion)"'
}

run_jobs() {
  gh api "repos/${repo}/actions/runs/$1/jobs?per_page=100" \
    -q '.jobs[] | "\(.id) \(.conclusion) \(.runner_name // "-" | if . == "" then "-" else . end)"'
}

never_acquired_count() {
  count=0
  for job in $1; do
    messages="$(gh api "repos/${repo}/check-runs/${job}/annotations" -q '.[].message')"
    hits="$(printf '%s\n' "${messages}" | awk -v text="${lost_text}" 'index($0, text) { n++ } END { print n + 0 }')"
    [ "${hits}" -eq 0 ] || count=$((count + 1))
  done
  echo "${count}"
}

failed_state() {
  newest="$(printf '%s\n' "$1" | awk '$3 == "completed" { print $1; exit }')"
  jobs="$(run_jobs "${newest}")"
  real="$(printf '%s\n' "${jobs}" | awk '($2 == "failure" || $2 == "timed_out") && $3 != "-" { n++ } END { print n + 0 }')"
  unassigned="$(printf '%s\n' "${jobs}" | awk '($2 == "cancelled" || $2 == "failure") && $3 == "-" { print $1 }')"
  lost="$(never_acquired_count "${unassigned}")"
  dispatched="$(printf '%s\n' "$1" | awk '$2 == "workflow_dispatch" { n++ } END { print n + 0 }')"
  if [ "${real}" -ne 0 ] || [ "${lost}" -eq 0 ]; then
    echo failed
  elif [ "${dispatched}" -ge "${dispatch_limit}" ]; then
    echo exhausted
  else
    echo lost
  fi
}

head="$(git rev-parse HEAD)"
runs="$(ci_runs "${head}")"
running="$(printf '%s\n' "${runs}" | awk 'NF && $3 != "completed" { n++ } END { print n + 0 }')"
green="$(printf '%s\n' "${runs}" | awk '$4 == "success" { n++ } END { print n + 0 }')"
if [ -z "${runs}" ]; then
  echo none
elif [ "${running}" -ne 0 ]; then
  echo running
elif [ "${green}" -eq 0 ]; then
  failed_state "${runs}"
else
  pending="$(releasable_commits)"
  if [ "${pending}" -eq 0 ]; then
    echo current
  else
    echo release
  fi
fi
