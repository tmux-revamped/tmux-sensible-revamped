#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/../.." && pwd)
minimum=${1:-100}
bash_bin=$(command -v bash)
# shellcheck disable=SC2016
if ! "${bash_bin}" -c '[ "${BASH_VERSINFO[0]}" -ge 4 ]' 2>/dev/null; then
  printf 'coverage: bashcov needs bash 4 or later, and %s is older. Install a newer bash first.\n' "${bash_bin}" >&2
  exit 1
fi
ruby_bin=$(command -v ruby)
bashcov_bin="${root}/.github/scripts/bashcov-run.rb"
hashbang=$(printf '\043\041')

rm -rf "${root}/coverage"
mkdir -p "${root}/coverage"

wrapper_dir=$(mktemp -d "${TMPDIR:-/tmp}/revamped-coverage-XXXXXX")
trap 'rm -rf "${wrapper_dir}"' EXIT
wrapper="${wrapper_dir}/bashcov-shell"
{
  printf '%s%s\n' "${hashbang}" "${bash_bin}"
  printf 'export BUNDLE_GEMFILE="%s/Gemfile"\n' "${root}"
  # shellcheck disable=SC2016
  printf 'exec "%s" -rbundler/setup "%s" --root "%s" --bash-path "%s" --command-name "run-$$-${RANDOM}" -- "$@"\n' \
    "${ruby_bin}" "${bashcov_bin}" "${root}" "${bash_bin}"
} >"${wrapper}"
chmod 0755 "${wrapper}"

if ! BUNDLE_GEMFILE="${root}/Gemfile" "${ruby_bin}" -rbundler/setup -e '' 2>"${wrapper_dir}/bundle.err"; then
  printf 'coverage: the gems in %s/Gemfile.lock are not all installed. Run bundle install first.\n' "${root}" >&2
  head -n 1 "${wrapper_dir}/bundle.err" >&2
  exit 1
fi

if ! BUNDLE_GEMFILE="${root}/Gemfile" "${ruby_bin}" -rbundler/setup "${root}/.github/scripts/bashcov-lexer.test.rb" \
  >/dev/null 2>"${wrapper_dir}/lexer.err"; then
  printf 'coverage: bashcov miscounts the lines after a quoted string, so .github/scripts/bashcov-lexer.rb needs updating.\n' >&2
  cat "${wrapper_dir}/lexer.err" >&2
  exit 1
fi

probe_root="${wrapper_dir}/probe"
mkdir -p "${probe_root}/coverage"
probe="${probe_root}/probe.sh"
{
  printf '%s%s\n' "${hashbang}" "${bash_bin}"
  # shellcheck disable=SC2016
  printf '%s\n' 'delimiter="${PS4:9:36}"' ': "+BASHCOV>${delimiter}broken${delimiter}"' \
    'count=0' 'while [ "${count}" -lt 20000 ]; do count=$((count + 1)); done'
} >"${probe}"
BUNDLE_GEMFILE="${root}/Gemfile" "${ruby_bin}" -rbundler/setup "${bashcov_bin}" --root "${probe_root}" \
  --bash-path "${bash_bin}" --command-name probe -- "${probe}" >/dev/null 2>&1 &
probe_pid=$!
probe_ticks=0
while kill -0 "${probe_pid}" 2>/dev/null; do
  if [ "${probe_ticks}" -ge 600 ]; then
    printf 'coverage: bashcov stopped reading the trace after a damaged record, so a traced test would hang.\n' >&2
    kill "${probe_pid}" 2>/dev/null
    exit 1
  fi
  sleep 0.1
  probe_ticks=$((probe_ticks + 1))
done
if ! wait "${probe_pid}"; then
  printf 'coverage: bashcov failed on a damaged trace record instead of skipping it.\n' >&2
  exit 1
fi

test_jobs="${REVAMPED_TEST_JOBS:-1}"
case "${test_jobs}" in
'' | *[!0-9]*)
  printf 'REVAMPED_TEST_JOBS must be a whole number, got: %s\n' "${test_jobs}" >&2
  exit 2
  ;;
*) ;;
esac
set --
if [ "${test_jobs}" -gt 1 ]; then
  set -- --jobs "${test_jobs}" --no-parallelize-within-files
fi
REVAMPED_COVERAGE=1 REVAMPED_TEST_SHELL="${wrapper}" bats "$@" "${root}/test"

cd "${root}"
python3 .github/scripts/coverage-gate.py '/(lib/[a-z]+\.sh|bin/[a-z-]+)\Z' "${minimum}" coverage/.resultset.json
