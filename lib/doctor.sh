#!/bin/sh

[ -n "${REVAMPED_DOCTOR_LOADED:-}" ] && return 0
REVAMPED_DOCTOR_LOADED=1

# shellcheck source=SCRIPTDIR/ui.sh
. "${REVAMPED_LIB:?}/ui.sh"
# shellcheck source=SCRIPTDIR/notify.sh
. "${REVAMPED_LIB:?}/notify.sh"

REVAMPED_DOCTOR_ROWS=""
REVAMPED_DOCTOR_MISSING=0

revamped_doctor_line() {
  if revamped_ui_out; then
    case "$2" in
    ok) revamped_doctor_line_state="@ok:ok" ;;
    warn) revamped_doctor_line_state="@warn:warn" ;;
    *) revamped_doctor_line_state="@bad:$2" ;;
    esac
    REVAMPED_DOCTOR_ROWS="${REVAMPED_DOCTOR_ROWS}$1	${revamped_doctor_line_state}	$3
"
    return 0
  fi
  printf '%-18s %-8s %s\n' "$1" "$2" "$3"
}

revamped_doctor_version() {
  printf '%s\n' "$1" | awk '{
    for (i = 1; i <= NF; i++) {
      t = $i
      gsub(/[,;()]/, "", t)
      sub(/^v/, "", t)
      if (t ~ /^[0-9]+(\.[0-9]+)+[a-z0-9]*$/ || t ~ /^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$/) { print t; exit }
    }
  }'
}

revamped_doctor_flavor() {
  revamped_doctor_flavor_raw=$("$1" --version 2>&1 </dev/null) || :
  revamped_doctor_flavor_text=$(printf '%s\n' "${revamped_doctor_flavor_raw}" | awk '/BusyBox|This is not GNU/ { print; found = 1; exit } NR == 1 { first = $0 } END { if (!found) print first }')
  revamped_doctor_flavor_number=$(revamped_doctor_version "${revamped_doctor_flavor_text}")
  case "${revamped_doctor_flavor_text}" in
  *uutils*) revamped_doctor_flavor_name=uutils ;;
  *BusyBox*) revamped_doctor_flavor_name=busybox ;;
  *"This is not GNU"*) revamped_doctor_flavor_name=busybox revamped_doctor_flavor_number="" ;;
  *"BSD grep"*) revamped_doctor_flavor_name=bsd revamped_doctor_flavor_number=$(revamped_doctor_version "${revamped_doctor_flavor_text%-FreeBSD}") ;;
  *GNU* | *"(coreutils)"* | *"(diffutils)"*) revamped_doctor_flavor_name=gnu ;;
  *mawk*) revamped_doctor_flavor_name=mawk ;;
  *"awk version"* | *"(Darwin)"*) revamped_doctor_flavor_name=bsd ;;
  *) revamped_doctor_flavor_guess "$1" ;;
  esac
  printf '%s%s\n' "${revamped_doctor_flavor_name}" "${revamped_doctor_flavor_number:+ ${revamped_doctor_flavor_number}}"
}

revamped_doctor_flavor_guess() {
  revamped_doctor_flavor_number=""
  revamped_platform_detect
  case "$1:${REVAMPED_PLATFORM_OS}" in
  *uutils*:* | */cargo/*:*) revamped_doctor_flavor_name=uutils ;;
  *:Darwin | *:*BSD) revamped_doctor_flavor_name=bsd ;;
  *) revamped_doctor_flavor_name=unknown ;;
  esac
}

revamped_doctor_tool() {
  revamped_doctor_tool_path=$(command -v "$1" 2>/dev/null) || revamped_doctor_tool_path=""
  if [ -n "${revamped_doctor_tool_path}" ]; then
    revamped_doctor_line "$1" ok "${revamped_doctor_tool_path}${3:+, $3}"
    return 0
  fi
  revamped_doctor_line "$1" missing "$2"
  return 1
}

revamped_doctor_required() {
  revamped_doctor_tool "$@" || REVAMPED_DOCTOR_MISSING=$((REVAMPED_DOCTOR_MISSING + 1))
}

revamped_doctor_core_tools() {
  for revamped_doctor_core_name in "$@"; do
    revamped_doctor_core_note=""
    if revamped_has_command "${revamped_doctor_core_name}"; then
      revamped_doctor_core_path=$(command -v "${revamped_doctor_core_name}")
      revamped_doctor_core_note=$(revamped_doctor_flavor "${revamped_doctor_core_path}")
    fi
    revamped_doctor_required "${revamped_doctor_core_name}" required "${revamped_doctor_core_note}"
  done
}

revamped_doctor_tmux() {
  revamped_doctor_tmux_note=""
  if revamped_has_command tmux; then
    revamped_doctor_tmux_raw=$(tmux -V 2>/dev/null) || revamped_doctor_tmux_raw=""
    revamped_doctor_tmux_note="${revamped_doctor_tmux_raw#tmux }"
  fi
  revamped_doctor_required tmux "brew install tmux, or apt install tmux" "${revamped_doctor_tmux_note}"
}

revamped_doctor_gum() {
  revamped_doctor_gum_note=""
  if revamped_has_command gum; then
    revamped_doctor_gum_raw=$(gum --version 2>/dev/null) || revamped_doctor_gum_raw=""
    revamped_doctor_gum_note=$(revamped_doctor_version "${revamped_doctor_gum_raw}")
  fi
  revamped_doctor_tool gum "brew install gum, or the gum release for Linux" "${revamped_doctor_gum_note}" || :
}

revamped_doctor_notifier() {
  revamped_doctor_notifier_backend=$(revamped_notify_backend)
  if [ "${revamped_doctor_notifier_backend}" = none ]; then
    revamped_doctor_line notifier warn "no osascript or notify-send, so notifications stay in the status line"
    return 0
  fi
  revamped_doctor_line notifier ok "${revamped_doctor_notifier_backend}"
}

revamped_doctor_settings_odd() {
  REVAMPED_DOCTOR_KINDS="$1" REVAMPED_DOCTOR_VALUES="$2" awk '
    function known(kind, value,    words, count, i) {
      count = split(kind, words, " ")
      if (words[1] == "number") {
        if (value !~ /^[0-9]+$/) { return 0 }
        if (count >= 2 && value + 0 < words[2] + 0) { return 0 }
        return count < 3 || value + 0 <= words[3] + 0
      }
      for (i = 1; i <= count; i++) { if (value == words[i]) { return 1 } }
      return 0
    }
    BEGIN {
      count = split(ENVIRON["REVAMPED_DOCTOR_KINDS"], rows, "\n")
      for (i = 1; i <= count; i++) {
        at = index(rows[i], "\t")
        if (at > 0) { kinds[substr(rows[i], 1, at - 1)] = substr(rows[i], at + 1) }
      }
      count = split(ENVIRON["REVAMPED_DOCTOR_VALUES"], rows, "\n")
      for (i = 1; i <= count; i++) {
        at = index(rows[i], "\t")
        name = substr(rows[i], 1, at - 1)
        value = substr(rows[i], at + 1)
        if (at == 0 || value == "" || !(name in kinds) || known(kinds[name], value)) { continue }
        odd = odd (odd == "" ? "" : " ") name "=" value
      }
      print odd
    }
  '
}

revamped_doctor_settings() {
  revamped_doctor_settings_found=$(revamped_doctor_settings_odd "$1" "$2")
  if [ -n "${revamped_doctor_settings_found}" ]; then
    revamped_doctor_line settings warn "unknown values: ${revamped_doctor_settings_found}"
    return 0
  fi
  revamped_doctor_line settings ok "every option holds a value it knows"
}

revamped_doctor_finish() {
  if revamped_ui_out; then
    printf 'Tool\tState\tDetail\n%s' "${REVAMPED_DOCTOR_ROWS}" | revamped_ui_table
    if [ "${REVAMPED_DOCTOR_MISSING}" -gt 0 ]; then
      revamped_ui_log ERROR "${REVAMPED_DOCTOR_MISSING} required tool(s) missing. install them and run ${REVAMPED_UI_NAME} doctor again."
    else
      revamped_ui_done "Ready. Every tool ${REVAMPED_UI_NAME} needs is here."
    fi
  fi
  return 0
}
