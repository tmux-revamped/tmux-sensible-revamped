#!/bin/sh
set -eu

usage() {
  printf 'usage: sh .github/scripts/toolset.sh native|homebrew|gnu|uutils|busybox [farm-dir]\n' >&2
  exit 1
}

[ "$#" -ge 1 ] || usage
toolset="$1"
farm="${2:-${TMPDIR:-/tmp}/toolset-${toolset}}"
os="$(uname -s)"

darwin_dirs() {
  for formula in "$@"; do
    found=0
    for dir in "${prefix}/opt/${formula}/libexec/gnubin" "${prefix}/opt/${formula}/libexec/uubin"; do
      if [ -d "${dir}" ]; then
        printf '%s\n' "${dir}"
        found=1
      fi
    done
    if [ "${found}" -eq 0 ]; then
      printf 'toolset: %s is not installed, so the %s toolset cannot be put first. run brew bundle.\n' "${formula}" "${toolset}" >&2
      exit 1
    fi
  done
}

darwin_kegs() {
  for formula in "$@"; do
    if [ -d "${prefix}/opt/${formula}/bin" ]; then
      printf '%s\n' "${prefix}/opt/${formula}/bin"
    fi
  done
}

darwin_system() {
  printf '%s\n' /usr/bin /bin /usr/sbin /sbin
}

darwin_homebrew() {
  darwin_dirs coreutils findutils gnu-sed gawk grep
  darwin_kegs diffutils openssl@3 curl libarchive bzip2 libiconv file-formula
  printf '%s\n' "${prefix}/bin"
}

linux_gnu_farm() {
  mkdir -p "${farm}"
  for tool in /usr/bin/gnu*; do
    [ -x "${tool}" ] || continue
    ln -sf "${tool}" "${farm}/${tool#/usr/bin/gnu}"
  done
  gawk_path="$(command -v gawk)"
  ln -sf "${gawk_path}" "${farm}/awk"
  printf '%s\n' "${farm}"
}

linux_uutils_farm() {
  mkdir -p "${farm}"
  for tool in /usr/lib/cargo/bin/coreutils/*; do
    [ -x "${tool}" ] || continue
    ln -sf "${tool}" "${farm}/${tool##*/}"
  done
  printf '%s\n' "${farm}"
}

linux_busybox_farm() {
  mkdir -p "${farm}"
  busybox_path="$(command -v busybox)"
  for applet in $("${busybox_path}" --list); do
    case "${applet}" in
    sh | ash | hush | bash) continue ;;
    *) ln -sf "${busybox_path}" "${farm}/${applet}" ;;
    esac
  done
  printf '%s\n' "${farm}"
}

prefix=""
if [ "${os}" = Darwin ]; then
  prefix="$(brew --prefix)"
fi

case "${toolset}:${os}" in
native:Darwin) darwin_system ;;
native:*) ;;
homebrew:Darwin | gnu:Darwin) darwin_homebrew ;;
busybox:Linux) linux_busybox_farm ;;
gnu:Linux) linux_gnu_farm ;;
uutils:Darwin) darwin_dirs uutils-coreutils uutils-diffutils uutils-findutils ;;
uutils:Linux) linux_uutils_farm ;;
*) usage ;;
esac
