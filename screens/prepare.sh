#!/bin/sh
set -eu

: "${SCREENS_REPO:?}"
demo=/Users/Shared/demo
rm -rf "${demo}"
mkdir -p "${demo}/home" "${demo}/bin"
tmux_path=$(command -v tmux)
ln -s "${tmux_path}" "${demo}/bin/tmux"
printf '#!/bin/sh\ncat >%s/clipboard\n' "${demo}" >"${demo}/bin/pbcopy"
chmod +x "${demo}/bin/pbcopy"
printf '%s\n' 'set -g status-left-length 20' >"${demo}/home/.tmux.conf"
