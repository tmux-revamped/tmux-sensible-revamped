#!/bin/sh
set -u

tests_dir="$(cd "$(dirname "$0")" && pwd)"
os="$(uname -s)"
failed=0

if [ -n "${REVAMPED_TEST_SHELLS:-}" ]; then
  shells="${REVAMPED_TEST_SHELLS}"
elif [ "${os}" = "Darwin" ]; then
  brew_bin="$(brew --prefix 2>/dev/null || printf /opt/homebrew)/bin"
  shells="/bin/sh|dash|/bin/bash|/bin/bash --posix|${brew_bin}/bash|${brew_bin}/bash --posix|/bin/zsh|${brew_bin}/zsh"
else
  shells="dash|bash|bash --posix|zsh|/bin/sh"
fi

if [ "$#" -eq 0 ]; then
  set -- "${tests_dir}"
fi

test_jobs="${REVAMPED_TEST_JOBS:-1}"
case "${test_jobs}" in
'' | *[!0-9]*)
  printf 'REVAMPED_TEST_JOBS must be a whole number, got: %s\n' "${test_jobs}" >&2
  exit 2
  ;;
*) ;;
esac
if [ "${test_jobs}" -gt 1 ]; then
  set -- --jobs "${test_jobs}" --no-parallelize-within-files "$@"
fi

old_ifs="${IFS}"
IFS='|'
for shell in ${shells}; do
  IFS="${old_ifs}"
  printf '== %s ==\n' "${shell}"
  if ! REVAMPED_TEST_SHELL="${shell}" bats --print-output-on-failure "$@"; then
    failed=$((failed + 1))
  fi
  IFS='|'
done
IFS="${old_ifs}"

if [ "${failed}" -ne 0 ]; then
  printf '%s shell(s) failed\n' "${failed}"
  exit 1
fi
printf 'every shell passed\n'
