#!/bin/sh
set -eu

here=$(cd "$(dirname "$0")" && pwd)
SCREENS_REPO=$(cd "${here}/.." && pwd)
export SCREENS_REPO
socket=revamped-screens
limit=1200

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
  vhs "${tape}" >/dev/null 2>&1 &
  recorder=$!
  waited=0
  while kill -0 "${recorder}" 2>/dev/null; do
    if [ "${waited}" -ge "${limit}" ]; then
      printf 'screens: %s ran for %s seconds and was stopped.\n' "${tape}" "${limit}" >&2
      kill "${recorder}" 2>/dev/null || :
      break
    fi
    sleep 1
    waited=$((waited + 1))
  done
  if ! wait "${recorder}" 2>/dev/null; then
    printf 'screens: %s did not record.\n' "${tape}" >&2
    status=1
  fi
  tmux -L "${socket}" kill-server 2>/dev/null || :
  rm -f scratch.gif
  sh ./cleanup.sh
done
sh ./finish.sh ./*.png
exit "${status}"
