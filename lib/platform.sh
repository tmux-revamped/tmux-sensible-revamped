#!/bin/sh

[ -n "${REVAMPED_PLATFORM_LOADED:-}" ] && return 0
REVAMPED_PLATFORM_LOADED=1
REVAMPED_PLATFORM_OS=""
REVAMPED_PLATFORM_ARCH=""

revamped_platform_os() {
  [ -n "${REVAMPED_PLATFORM_OS}" ] || REVAMPED_PLATFORM_OS=$(uname -s 2>/dev/null) || REVAMPED_PLATFORM_OS=unknown
  printf '%s\n' "${REVAMPED_PLATFORM_OS:-unknown}"
}

revamped_platform_arch() {
  [ -n "${REVAMPED_PLATFORM_ARCH}" ] || REVAMPED_PLATFORM_ARCH=$(uname -m 2>/dev/null) || REVAMPED_PLATFORM_ARCH=unknown
  printf '%s\n' "${REVAMPED_PLATFORM_ARCH:-unknown}"
}

revamped_platform_detect() {
  revamped_platform_os >/dev/null
  revamped_platform_arch >/dev/null
}

revamped_is_macos() {
  revamped_platform_detect
  [ "${REVAMPED_PLATFORM_OS}" = Darwin ]
}

revamped_is_linux() {
  revamped_platform_detect
  [ "${REVAMPED_PLATFORM_OS}" = Linux ]
}

revamped_is_bsd() {
  revamped_platform_detect
  case "${REVAMPED_PLATFORM_OS}" in
  *BSD | DragonFly) return 0 ;;
  *) return 1 ;;
  esac
}

revamped_is_apple_silicon() {
  revamped_platform_detect
  [ "${REVAMPED_PLATFORM_OS}" = Darwin ] && [ "${REVAMPED_PLATFORM_ARCH}" = arm64 ]
}
