#!/bin/sh
[ -n "${ZSH_VERSION:-}" ] && emulate sh

REVAMPED_LIB="$(cd "$(dirname "$0")/../lib" && pwd)" || exit 1
revamped_call_module="${1:?usage: sh test/call.sh <module> <function> [arguments]}"
shift

# shellcheck source=/dev/null
. "${REVAMPED_LIB}/${revamped_call_module}.sh"

"$@"
