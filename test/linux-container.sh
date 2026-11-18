#!/bin/sh
set -eu

repo="$(cd "$(dirname "$0")/.." && pwd)"
image="${REVAMPED_TEST_IMAGE:-ubuntu:26.04}"

docker run --rm \
  -v "${repo}:/repo" \
  -w /repo \
  -e REVAMPED_TEST_SHELLS="${REVAMPED_TEST_SHELLS:-}" \
  -e REVAMPED_TEST_JOBS="${REVAMPED_TEST_JOBS:-}" \
  -e REVAMPED_TEST_RECORD="${REVAMPED_TEST_RECORD:-}" \
  "${image}" \
  sh -c '
    set -eu
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null
    apt-get install -y -qq --no-install-recommends \
      bats dash zsh tmux git python3 make ca-certificates >/dev/null
    git config --global --add safe.directory /repo
    exec "$@"
  ' sh "$@"
