#!/bin/sh

sensible_revamped_dir=$(cd "$(dirname "$0")" && pwd)
"${sensible_revamped_dir}/bin/sensible-revamped" apply
