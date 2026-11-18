#!/bin/sh

[ -n "${REVAMPED_PUBLISH_LOADED:-}" ] && return 0
REVAMPED_PUBLISH_LOADED=1

# shellcheck source=SCRIPTDIR/tmux.sh
. "${REVAMPED_LIB:?}/tmux.sh"

REVAMPED_PUBLISH_BATCH=""
REVAMPED_PUBLISH_PENDING=0
REVAMPED_PUBLISH_NEWLINE="
"
REVAMPED_PUBLISH_CONTINUATION=$(printf '\200\201\202\203\204\205\206\207\210\211\212\213\214\215\216\217\220\221\222\223\224\225\226\227\230\231\232\233\234\235\236\237\240\241\242\243\244\245\246\247\250\251\252\253\254\255\256\257\260\261\262\263\264\265\266\267\270\271\272\273\274\275\276\277')

revamped_publish_replace() {
  revamped_publish_replace_rest="$3"
  revamped_publish_replace_out=""
  while :; do
    case "${revamped_publish_replace_rest}" in
    *"$1"*)
      revamped_publish_replace_out="${revamped_publish_replace_out}${revamped_publish_replace_rest%%"$1"*}$2"
      revamped_publish_replace_rest="${revamped_publish_replace_rest#*"$1"}"
      ;;
    *) break ;;
    esac
  done
  revamped_publish_replace_out="${revamped_publish_replace_out}${revamped_publish_replace_rest}"
}

revamped_publish_escape() {
  revamped_publish_replace '#' '##' "$1"
  printf '%s' "${revamped_publish_replace_out}"
}

revamped_publish_count() {
  revamped_publish_count_locale="${LC_ALL-}"
  revamped_publish_count_locale_set="${LC_ALL+set}"
  LC_ALL=C
  revamped_publish_count_rest="$1"
  revamped_publish_count_out=0
  while [ -n "${revamped_publish_count_rest}" ]; do
    revamped_publish_count_tail="${revamped_publish_count_rest#?}"
    case "${REVAMPED_PUBLISH_CONTINUATION}" in
    *"${revamped_publish_count_rest%"${revamped_publish_count_tail}"}"*) : ;;
    *) revamped_publish_count_out=$((revamped_publish_count_out + 1)) ;;
    esac
    revamped_publish_count_rest="${revamped_publish_count_tail}"
  done
  if [ "${revamped_publish_count_locale_set}" = set ]; then
    LC_ALL="${revamped_publish_count_locale}"
  else
    unset LC_ALL
  fi
}

revamped_publish_chars() {
  revamped_publish_count "$1"
  printf '%s' "${revamped_publish_count_out}"
}

revamped_publish_pad() {
  revamped_publish_pad_width="${2:-0}"
  case "${revamped_publish_pad_width}" in
  '' | *[!0-9]*) revamped_publish_pad_width=0 ;;
  *) ;;
  esac
  revamped_publish_count "$1"
  if [ "${revamped_publish_count_out}" -lt "${revamped_publish_pad_width}" ]; then
    printf "%$((revamped_publish_pad_width - revamped_publish_count_out))s" ''
  fi
  printf '%s' "$1"
}

revamped_publish_width() {
  revamped_publish_width_own=$(revamped_tmux_get "@$1_$2_width")
  case "${revamped_publish_width_own}" in
  '' | *[!0-9]*) : ;;
  *)
    printf '%s' "${revamped_publish_width_own}"
    return 0
    ;;
  esac
  revamped_publish_width_fixed=$(revamped_tmux_get "@$1_fixed_width" off)
  if [ "${revamped_publish_width_fixed}" = on ]; then
    printf '%s' "${3:-0}"
  else
    printf '0'
  fi
}

revamped_publish_push() {
  for revamped_publish_push_word in "$@"; do
    REVAMPED_PUBLISH_BATCH="${REVAMPED_PUBLISH_BATCH}${revamped_publish_push_word}
"
  done
}

revamped_publish_add_raw() {
  revamped_publish_replace "${REVAMPED_PUBLISH_NEWLINE}" ' ' "$2"
  revamped_publish_add_raw_value="${revamped_publish_replace_out}"
  case "${revamped_publish_add_raw_value}" in
  *';') revamped_publish_add_raw_value="${revamped_publish_add_raw_value%;}\;" ;;
  *) ;;
  esac
  [ "${REVAMPED_PUBLISH_PENDING}" -gt 0 ] && revamped_publish_push ';'
  if [ -n "${3:-}" ]; then
    revamped_publish_push set-option -pq -t "$3" "$1" "${revamped_publish_add_raw_value}"
  else
    revamped_publish_push set-option -gq "$1" "${revamped_publish_add_raw_value}"
  fi
  REVAMPED_PUBLISH_PENDING=$((REVAMPED_PUBLISH_PENDING + 1))
}

revamped_publish_add() {
  revamped_publish_replace % %% "$2"
  revamped_publish_add_raw "$1" "${revamped_publish_replace_out}" "${3:-}"
}

revamped_publish_commit() {
  [ "${REVAMPED_PUBLISH_PENDING}" -gt 0 ] || return 0
  revamped_publish_commit_clients=$(tmux list-clients -F '#{client_name}' 2>/dev/null) || revamped_publish_commit_clients=""
  while IFS= read -r revamped_publish_commit_client; do
    [ -n "${revamped_publish_commit_client}" ] && revamped_publish_push ';' refresh-client -S -t "${revamped_publish_commit_client}"
  done <<EOF
${revamped_publish_commit_clients}
EOF
  set --
  while IFS= read -r revamped_publish_commit_word; do
    set -- "$@" "${revamped_publish_commit_word}"
  done <<EOF
${REVAMPED_PUBLISH_BATCH%?}
EOF
  REVAMPED_PUBLISH_BATCH=""
  REVAMPED_PUBLISH_PENDING=0
  tmux "$@" >/dev/null 2>&1
}
