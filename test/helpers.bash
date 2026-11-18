#!/usr/bin/env bash

REVAMPED_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

harness_setup() {
  unset TMUX TMUX_PANE
  REVAMPED_TEST_TMUX_DIR="$(mktemp -d "${BATS_TEST_TMPDIR:-${TMPDIR:-/tmp}}/tmux-store.XXXXXX")"
  REVAMPED_TEST_TMUX_LOG="${REVAMPED_TEST_TMUX_DIR}.log"
  : >"${REVAMPED_TEST_TMUX_LOG}"
  export REVAMPED_TEST_TMUX_DIR REVAMPED_TEST_TMUX_LOG
  PATH="${BATS_TEST_TMPDIR}/stubs:${REVAMPED_TESTS_DIR}/bin:${PATH}"
  export PATH
}

lib_call() {
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/call.sh" "$@"
}

lib_run() {
  local script="${BATS_TEST_TMPDIR}/lib-run.sh"
  # shellcheck disable=SC2016
  printf '[ -n "${ZSH_VERSION:-}" ] && emulate sh\nREVAMPED_LIB=%s\n. "${REVAMPED_LIB}/%s.sh"\n%s\n' \
    "${REVAMPED_TESTS_DIR}/../lib" "$1" "$2" >"${script}"
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${script}"
}

harness_hide() {
  local farm="${BATS_TEST_TMPDIR}/farm" dir name
  mkdir -p "${farm}"
  ln -s "${REVAMPED_TESTS_DIR}/bin"/* "${farm}/"
  local IFS=:
  for dir in ${PATH}; do
    [[ -d "${dir}" ]] || continue
    [[ "${dir}" = "${REVAMPED_TESTS_DIR}/bin" ]] && continue
    ln -s "${dir}"/* "${farm}/" 2>/dev/null || :
  done
  unset IFS
  for name in "$@"; do
    rm -f "${farm:?}/${name}"
  done
  PATH="${BATS_TEST_TMPDIR}/stubs:${farm}"
}

stub_command() {
  mkdir -p "${BATS_TEST_TMPDIR}/stubs"
  # shellcheck disable=SC2016
  printf '#!/bin/sh\n{ set +x; } 2>/dev/null\nfor a in "$@"; do printf "%%s\\n" "$a"; done >>"%s"\n' "${BATS_TEST_TMPDIR}/$1.calls" >"${BATS_TEST_TMPDIR}/stubs/$1"
  chmod +x "${BATS_TEST_TMPDIR}/stubs/$1"
}

stub_calls() {
  cat "${BATS_TEST_TMPDIR}/$1.calls"
}

tmux_answer() {
  printf '%s' "$2" >"${REVAMPED_TEST_TMUX_DIR}/$(printf '%s' "display.${3:--}.$1" | tr -c 'A-Za-z0-9_.-' '_')"
}

count_matching() {
  awk -v pattern="$1" '$0 ~ pattern { n++ } END { print n + 0 }' "$2"
}

tmux_calls() {
  cat "${REVAMPED_TEST_TMUX_LOG}"
}

if [[ -f "${REVAMPED_TESTS_DIR}/helpers_local.bash" ]]; then
  # shellcheck source=/dev/null
  . "${REVAMPED_TESTS_DIR}/helpers_local.bash"
fi
