#!/bin/sh
set -eu

here=$(cd "$(dirname "$0")" && pwd)
SCREENS_REPO=$(cd "${here}/.." && pwd)
export SCREENS_REPO
socket=revamped-screens

system=$(uname -s)
if [ "${system}" != Darwin ]; then
  printf 'screens: the screens are recorded on macOS.\n' >&2
  exit 1
fi
for tool in vhs tmux magick; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    printf 'screens: %s is not installed. install it with: brew install vhs tmux imagemagick\n' "${tool}" >&2
    exit 1
  fi
done

unset TMUX TMUX_PANE
cd "${here}"
status=0
for tape in *.tape; do
  [ "${tape}" != common.tape ] || continue
  sh ./prepare.sh
  tmux -L "${socket}" -f "${here}/tmux.conf" new-session -d -s demo -x 120 -y 30 \
    "bash --noprofile --rcfile '${here}/setup.sh'"
  if ! vhs "${tape}" >/dev/null 2>&1; then
    printf 'screens: %s did not record.\n' "${tape}" >&2
    status=1
  fi
  tmux -L "${socket}" kill-server 2>/dev/null || :
  rm -f scratch.gif
  sh ./cleanup.sh
done
sh ./finish.sh ./*.png
exit "${status}"
