#!/bin/sh
# shellcheck disable=SC2034

[ -n "${REVAMPED_UI_LOADED:-}" ] && return 0
REVAMPED_UI_LOADED=1

REVAMPED_UI_NAME="${REVAMPED_UI_NAME:-revamped}"
REVAMPED_UI_VERSION="${REVAMPED_UI_VERSION:-}"
REVAMPED_UI_TAGLINE="${REVAMPED_UI_TAGLINE:-}"
REVAMPED_UI_THEME="${REVAMPED_UI_THEME:-${KODOUGU_THEME:-kodougu}}"
REVAMPED_UI_ACCENT_CHOICE="${REVAMPED_UI_ACCENT_CHOICE:-${KODOUGU_ACCENT:-}}"
REVAMPED_UI_ACCENT_NAME="${REVAMPED_UI_ACCENT_NAME:-KODOUGU_ACCENT}"
REVAMPED_UI_ACCENT=""
REVAMPED_UI_OK=""
REVAMPED_UI_WARN=""
REVAMPED_UI_ERR=""
REVAMPED_UI_MUTED=""
REVAMPED_UI_TEXT=""
REVAMPED_UI_SURFACE=""
REVAMPED_UI_HELP="ascii"
REVAMPED_UI_PROBLEM=""
REVAMPED_UI_STEP=""
REVAMPED_UI_THEMES="kodougu, catppuccin-mocha, catppuccin-latte, dracula, nord, gruvbox, tokyo-night, mono"

# shellcheck disable=SC2034
revamped_ui_set() {
  REVAMPED_UI_ACCENT="$1"
  REVAMPED_UI_OK="$2"
  REVAMPED_UI_WARN="$3"
  REVAMPED_UI_ERR="$4"
  REVAMPED_UI_MUTED="$5"
  REVAMPED_UI_TEXT="$6"
  REVAMPED_UI_SURFACE="$7"
  REVAMPED_UI_HELP="$8"
}

revamped_ui_palette() {
  case "$1" in
  kodougu) revamped_ui_set "#F25D94" "#50FA7B" "#FFB86C" "#FF5555" "#6C7086" "#CDD6F4" "#313244" pink ;;
  catppuccin-mocha) revamped_ui_set "#CBA6F7" "#A6E3A1" "#FAB387" "#F38BA8" "#6C7086" "#CDD6F4" "#313244" dark ;;
  catppuccin-latte) revamped_ui_set "#8839EF" "#40A02B" "#FE640B" "#D20F39" "#8C8FA1" "#4C4F69" "#CCD0DA" light ;;
  dracula) revamped_ui_set "#BD93F9" "#50FA7B" "#FFB86C" "#FF5555" "#6272A4" "#F8F8F2" "#44475A" dracula ;;
  nord) revamped_ui_set "#88C0D0" "#A3BE8C" "#EBCB8B" "#BF616A" "#4C566A" "#D8DEE9" "#3B4252" dark ;;
  gruvbox) revamped_ui_set "#FE8019" "#B8BB26" "#FABD2F" "#FB4934" "#928374" "#EBDBB2" "#3C3836" dark ;;
  tokyo-night) revamped_ui_set "#7AA2F7" "#9ECE6A" "#E0AF68" "#F7768E" "#565F89" "#C0CAF5" "#292E42" tokyo-night ;;
  mono) revamped_ui_set "" "" "" "" "" "" "" ascii ;;
  *) return 1 ;;
  esac
}

revamped_ui_is_colour() {
  case "$1" in
  \#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]) return 0 ;;
  *) return 1 ;;
  esac
}

# shellcheck disable=SC2034
revamped_ui_setup() {
  if ! revamped_ui_palette "${REVAMPED_UI_THEME}"; then
    revamped_ui_palette mono
    REVAMPED_UI_PROBLEM="--theme must be one of ${REVAMPED_UI_THEMES}, got: ${REVAMPED_UI_THEME}"
    return 1
  fi
  if [ -n "${REVAMPED_UI_ACCENT_CHOICE}" ] && ! revamped_ui_is_colour "${REVAMPED_UI_ACCENT_CHOICE}"; then
    REVAMPED_UI_PROBLEM="${REVAMPED_UI_ACCENT_NAME} must be a colour such as #CBA6F7, got: ${REVAMPED_UI_ACCENT_CHOICE}"
    return 1
  fi
  if [ -n "${REVAMPED_UI_ACCENT_CHOICE}" ]; then
    REVAMPED_UI_ACCENT="${REVAMPED_UI_ACCENT_CHOICE}"
  fi
  if [ -n "${NO_COLOR:-}" ]; then
    revamped_ui_palette mono
  fi
}

revamped_ui_forced() {
  [ "${REVAMPED_TEST_GUM:-}" = 1 ]
}

revamped_ui_has_gum() {
  command -v gum >/dev/null 2>&1
}

revamped_ui_prompts() {
  revamped_ui_forced && return 0
  [ -t 0 ] && [ -t 2 ] && revamped_ui_has_gum
}

revamped_ui_err() {
  revamped_ui_forced && return 0
  [ "${REVAMPED_UI_STEP}" = 1 ] && return 0
  [ -t 2 ] && revamped_ui_has_gum
}

revamped_ui_out() {
  revamped_ui_forced && return 0
  [ -t 1 ] && revamped_ui_has_gum
}

revamped_gum() {
  if [ -n "${REVAMPED_UI_TEXT}" ]; then
    CLICOLOR_FORCE=1 gum "$@"
    return
  fi
  gum "$@"
}

revamped_ui_ink() {
  revamped_ui_colour="$1"
  shift
  if [ -z "${revamped_ui_colour}" ]; then
    revamped_gum style "$@"
    return
  fi
  revamped_gum style --foreground "${revamped_ui_colour}" "$@"
}

revamped_ui_header() {
  revamped_uh_name=$(revamped_ui_ink "${REVAMPED_UI_ACCENT}" --bold -- "${REVAMPED_UI_NAME}")
  revamped_uh_version=$(revamped_ui_ink "${REVAMPED_UI_MUTED}" -- "${REVAMPED_UI_VERSION}")
  revamped_uh_tagline=$(revamped_ui_ink "${REVAMPED_UI_TEXT}" -- "${REVAMPED_UI_TAGLINE}")
  revamped_uh_top=$(revamped_gum join --horizontal "${revamped_uh_name}" "  " "${revamped_uh_version}")
  revamped_uh_body=$(revamped_gum join --vertical "${revamped_uh_top}" "${revamped_uh_tagline}")
  printf '\n' >&2
  revamped_gum style --border rounded --border-foreground "${REVAMPED_UI_ACCENT}" --padding "0 2" -- "${revamped_uh_body}" >&2
  printf '\n' >&2
}

revamped_ui_title() {
  printf '\n' >&2
  revamped_ui_ink "${REVAMPED_UI_ACCENT}" --bold -- "$1" >&2
  printf '\n' >&2
}

revamped_ui_titled() {
  if revamped_ui_prompts; then
    revamped_ui_title "$1"
  fi
}

revamped_ui_lower_first() {
  printf '%s\n' "$1" | awk 'NR == 1 { a = substr($0, 1, 1); b = substr($0, 2, 1); if (a != tolower(a) && b != toupper(b)) { $0 = tolower(a) substr($0, 2) } } { print }'
}

revamped_ui_log() {
  revamped_ul_level="$1"
  revamped_ul_text=$(revamped_ui_lower_first "$2")
  case "${revamped_ul_level}" in
  ERROR) revamped_ul_colour="${REVAMPED_UI_ERR}" ;;
  WARN) revamped_ul_colour="${REVAMPED_UI_WARN}" ;;
  *) revamped_ul_colour="${REVAMPED_UI_OK}" ;;
  esac
  revamped_ul_label=$(revamped_ui_ink "${revamped_ul_colour}" --bold -- "${revamped_ul_level}")
  printf '%s %s: %s\n' "${revamped_ul_label}" "${REVAMPED_UI_NAME}" "${revamped_ul_text}" >&2
}

revamped_ui_choose() {
  revamped_uc_header="$1"
  shift
  revamped_gum choose --header "${revamped_uc_header}" --cursor "> " --height 14 \
    --cursor.foreground "${REVAMPED_UI_ACCENT}" --selected.foreground "${REVAMPED_UI_ACCENT}" \
    --header.foreground "${REVAMPED_UI_TEXT}" "$@"
}

revamped_ui_input() {
  revamped_ui_header_text="$1"
  revamped_ui_placeholder="$2"
  shift 2
  revamped_gum input --header "${revamped_ui_header_text}" --placeholder "${revamped_ui_placeholder}" --prompt "> " \
    --prompt.foreground "${REVAMPED_UI_ACCENT}" --cursor.foreground "${REVAMPED_UI_ACCENT}" \
    --header.foreground "${REVAMPED_UI_TEXT}" --placeholder.foreground "${REVAMPED_UI_MUTED}" "$@"
}

revamped_ui_write() {
  revamped_gum write --header "$1" --placeholder "$2" --width 72 --height 8 --show-line-numbers \
    --cursor.foreground "${REVAMPED_UI_ACCENT}" --header.foreground "${REVAMPED_UI_TEXT}" \
    --placeholder.foreground "${REVAMPED_UI_MUTED}"
}

revamped_ui_confirm() {
  revamped_ucf_prompt="$1"
  revamped_ucf_yes="$2"
  revamped_ucf_no="$3"
  shift 3
  revamped_gum confirm "${revamped_ucf_prompt}" --affirmative "${revamped_ucf_yes}" --negative "${revamped_ucf_no}" \
    --prompt.foreground "${REVAMPED_UI_TEXT}" --selected.background "${REVAMPED_UI_ACCENT}" \
    --unselected.background "${REVAMPED_UI_SURFACE}" "$@"
}

revamped_ui_summary() {
  revamped_us2_pairs=$(($# / 2))
  while [ "${revamped_us2_pairs}" -gt 0 ]; do
    revamped_us2_label=$(printf '%-7s' "$1")
    revamped_us2_label=$(revamped_ui_ink "${REVAMPED_UI_MUTED}" -- "${revamped_us2_label}")
    revamped_us2_value=$(revamped_ui_ink "${REVAMPED_UI_TEXT}" --bold -- "$2")
    shift 2
    set -- "$@" "${revamped_us2_label} ${revamped_us2_value}"
    revamped_us2_pairs=$((revamped_us2_pairs - 1))
  done
  printf '\n'
  revamped_gum style --border rounded --border-foreground "${REVAMPED_UI_MUTED}" --padding "0 1" -- "$@"
  printf '\n'
}

revamped_ui_spin() {
  revamped_us_title="$1"
  revamped_us_log="$2"
  shift 2
  (REVAMPED_UI_STEP=1 && "$@") 2>"${revamped_us_log}" &
  revamped_us_pid=$!
  if ! revamped_ui_spin_wait "${revamped_us_title}" "${revamped_us_pid}"; then
    kill "${revamped_us_pid}" 2>/dev/null
    exit 130
  fi
  revamped_us_status=0
  wait "${revamped_us_pid}" || revamped_us_status=$?
  cat "${revamped_us_log}" >&2
  return "${revamped_us_status}"
}

revamped_ui_spin_wait() {
  # shellcheck disable=SC2016
  revamped_uw_loop='while kill -0 "$1" 2>/dev/null; do sleep 0.1; done'
  revamped_gum spin --spinner dot --spinner.foreground "${REVAMPED_UI_ACCENT}" --title.foreground "${REVAMPED_UI_TEXT}" --title "$1" -- sh -c "${revamped_uw_loop}" _ "$2" >&2
}

revamped_ui_table() {
  revamped_ut_line="-"
  if [ -n "${REVAMPED_UI_TEXT}" ]; then
    revamped_ut_line=$(printf '\342\224\200')
  fi
  revamped_ut_body=$(revamped_ui_table_body "${revamped_ut_line}")
  revamped_gum style --border rounded --border-foreground "${REVAMPED_UI_MUTED}" --padding "0 1" -- "${revamped_ut_body}"
}

revamped_ui_table_body() {
  LC_ALL=C awk -F '\t' -v acc="${REVAMPED_UI_ACCENT}" -v ok="${REVAMPED_UI_OK}" -v warn="${REVAMPED_UI_WARN}" \
    -v bad="${REVAMPED_UI_ERR}" -v txt="${REVAMPED_UI_TEXT}" -v mut="${REVAMPED_UI_MUTED}" -v dash="$1" \
    -f "${REVAMPED_LIB:?}/table.awk"
}

revamped_ui_done() {
  printf '\n'
  revamped_ui_ink "${REVAMPED_UI_OK}" --bold -- "$1"
}

revamped_ui_badge() {
  revamped_ub_colour="$1"
  shift
  if [ -z "${revamped_ub_colour}" ]; then
    revamped_gum style --bold --underline --padding "0 1" -- "$*"
    return
  fi
  revamped_gum style --background "${revamped_ub_colour}" --foreground "#1E1E2E" --bold --padding "0 1" -- "$*"
}

revamped_ui_chip() {
  if [ -z "${REVAMPED_UI_SURFACE}" ]; then
    revamped_gum style --padding "0 1" -- "$1"
    return
  fi
  revamped_gum style --background "${REVAMPED_UI_SURFACE}" --foreground "${REVAMPED_UI_TEXT}" --padding "0 1" -- "$1"
}

revamped_ui_danger() {
  revamped_ud_title=$(revamped_ui_ink "${REVAMPED_UI_ERR}" --bold -- "$1")
  shift
  revamped_gum style --border thick --border-foreground "${REVAMPED_UI_ERR}" --padding "0 1" -- "${revamped_ud_title}" "$@" >&2
}

revamped_ui_markdown() {
  awk '
    NR == 1 {
      split($0, head, " - ")
      printf "# %s\n\n%s\n", head[1], head[2]
      next
    }
    /^[a-z][a-z ]*:$/ {
      if (open) { print "```" }
      printf "\n## %s\n\n```text\n", toupper(substr($0, 1, 1)) substr($0, 2, length($0) - 2)
      open = 1
      next
    }
    { print }
    END { if (open) { print "```" } }
  '
}
