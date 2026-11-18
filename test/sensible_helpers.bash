#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  for name in $(compgen -v SENSIBLE_REVAMPED_); do
    unset "${name}"
  done
  unset TERM_PROGRAM COLORTERM LC_TERMINAL EDITOR VISUAL WAYLAND_DISPLAY DISPLAY XDG_CONFIG_HOME
  FAKE="${BATS_TEST_TMPDIR}/fake"
  export HOME="${BATS_TEST_TMPDIR}/home" TERM=dumb FAKE
  mkdir -p "${HOME}" "${FAKE}/opt" "${BATS_TEST_TMPDIR}/stubs"
  UNTRACED='{ set +x; } 2>/dev/null'
  printf '3.6\n' >"${FAKE}/version"
  fake_tmux
  quiet infocmp 'exit 1'
  harness_hide wl-copy termux-clipboard-set pbcopy xclip xsel clip.exe reattach-to-user-namespace
}

quiet() {
  printf '#!/bin/sh\n%s\n%s\n' "${UNTRACED}" "$2" >"${BATS_TEST_TMPDIR}/stubs/$1"
  chmod +x "${BATS_TEST_TMPDIR}/stubs/$1"
}

fake_tmux() {
  cat >"${BATS_TEST_TMPDIR}/stubs/tmux" <<EOF
#!/bin/sh
${UNTRACED}
printf '%s\n' "\$*" >>"${FAKE}/log"
if [ "\$1" = -V ]; then
  IFS= read -r version <"${FAKE}/version"
  printf 'tmux %s\n' "\${version}"
  exit 0
fi
case "\$1:\$*" in
show-option:*" ; "*) [ ! -f "${FAKE}/unchained" ] || exit 1 ;;
show-option:* | list-keys:* | list-clients:* | show-environment:*) ;;
*" ; "*)
  [ ! -f "${FAKE}/refused" ] || exit 1
  exit 0
  ;;
*)
  [ ! -f "${FAKE}/refused" ] || ! grep -qF -- "\$*" "${FAKE}/refused" || exit 1
  exit 0
  ;;
esac
while [ "\$#" -gt 0 ]; do
  case "\$1" in
  show-option)
    case "\$2" in -sqv) scope=s ;; -wgqv) scope=w ;; *) scope=g ;; esac
    [ ! -f "${FAKE}/opt/\${scope}.\$3" ] || cat "${FAKE}/opt/\${scope}.\$3"
    shift 3
    ;;
  display-message)
    printf '%s\n' "\$3"
    shift 3
    ;;
  list-clients)
    [ ! -f "${FAKE}/clients" ] || cat "${FAKE}/clients"
    shift 3
    ;;
  list-keys)
    [ ! -f "${FAKE}/keys" ] || cat "${FAKE}/keys"
    shift
    ;;
  show-environment)
    [ ! -f "${FAKE}/environment" ] || cat "${FAKE}/environment"
    shift 2
    ;;
  *) shift ;;
  esac
done
EOF
  chmod +x "${BATS_TEST_TMPDIR}/stubs/tmux"
}

tmux_is() {
  printf '%s\n' "$1" >"${FAKE}/version"
}

has() {
  printf '%s\n' "$3" >"${FAKE}/opt/$1.$2"
}

terminfo() {
  quiet infocmp "name=\"\${2:-\$1}\"
if [ \"\$1\" = -x ]; then
  case \" ${2:-} \" in *\" \${name} \"*) printf 'RGB\\n' ;; *) ;; esac
  exit 0
fi
case \" $1 \" in *\" \${name} \"*) exit 0 ;; *) exit 1 ;; esac"
}

tool_exists() {
  quiet "$1" 'exit 0'
}

planned() {
  lib_run sensible "${1:-}"'sensible_revamped_plan; sensible_revamped_lines'
}

sent() {
  grep -c -- "$1" "${FAKE}/log" || :
}

tool() {
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/sensible-revamped" "$@"
}

has_line() {
  local line
  for line in "${lines[@]}"; do
    [[ "${line}" == "$1" ]] && return 0
  done
  return 1
}
