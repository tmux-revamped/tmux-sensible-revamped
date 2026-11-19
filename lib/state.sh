#!/bin/sh
# shellcheck disable=SC2034

[ -n "${SENSIBLE_REVAMPED_STATE_LOADED:-}" ] && return 0
SENSIBLE_REVAMPED_STATE_LOADED=1

SENSIBLE_REVAMPED_SETTINGS='keys	on
last_window_key
reload_key	'
SENSIBLE_REVAMPED_NAMES='keys last_window_key reload_key'
SENSIBLE_REVAMPED_S_keys='on'
SENSIBLE_REVAMPED_S_last_window_key=''
SENSIBLE_REVAMPED_S_reload_key=''
SENSIBLE_REVAMPED_RESIZE_SAVED=@sensible_revamped_resize_saved
SENSIBLE_REVAMPED_HOOK_INDEX=1000
SENSIBLE_REVAMPED_MARK=sensible-revamped-next
SENSIBLE_REVAMPED_WORD_SEPARATORS='!"#$%&'\''()*+,-./:;<=>?@[\]^`{|}~'
SENSIBLE_REVAMPED_PROC_VERSION=/proc/version
SENSIBLE_REVAMPED_READS='s default-terminal
g default-terminal
s terminal-features
g terminal-features
s terminal-overrides
g terminal-overrides
s escape-time
g focus-events
g set-clipboard
g allow-passthrough
s extended-keys
s extended-keys-format
g history-limit
g display-time
g status-interval
g repeat-time
g display-panes-time
g status-keys
g set-titles
w word-separators
g base-index
w pane-base-index
g renumber-windows
w automatic-rename
w aggressive-resize
w mode-keys
g default-command
g prefix
g @sensible_revamped_keys
g @sensible_revamped_last_window_key
g @sensible_revamped_reload_key
e environment'
SENSIBLE_REVAMPED_RESIZE_READS='g @sensible_revamped_resize_saved
w aggressive-resize'
SENSIBLE_REVAMPED_O_s_default_terminal=''
SENSIBLE_REVAMPED_O_g_default_terminal=''
SENSIBLE_REVAMPED_O_s_terminal_features=''
SENSIBLE_REVAMPED_O_g_terminal_features=''
SENSIBLE_REVAMPED_O_s_terminal_overrides=''
SENSIBLE_REVAMPED_O_g_terminal_overrides=''
SENSIBLE_REVAMPED_O_s_escape_time=''
SENSIBLE_REVAMPED_O_g_focus_events=''
SENSIBLE_REVAMPED_O_g_set_clipboard=''
SENSIBLE_REVAMPED_O_g_allow_passthrough=''
SENSIBLE_REVAMPED_O_s_extended_keys=''
SENSIBLE_REVAMPED_O_s_extended_keys_format=''
SENSIBLE_REVAMPED_O_g_history_limit=''
SENSIBLE_REVAMPED_O_g_display_time=''
SENSIBLE_REVAMPED_O_g_status_interval=''
SENSIBLE_REVAMPED_O_g_repeat_time=''
SENSIBLE_REVAMPED_O_g_display_panes_time=''
SENSIBLE_REVAMPED_O_g_status_keys=''
SENSIBLE_REVAMPED_O_g_set_titles=''
SENSIBLE_REVAMPED_O_w_word_separators=''
SENSIBLE_REVAMPED_O_g_base_index=''
SENSIBLE_REVAMPED_O_w_pane_base_index=''
SENSIBLE_REVAMPED_O_g_renumber_windows=''
SENSIBLE_REVAMPED_O_w_automatic_rename=''
SENSIBLE_REVAMPED_O_w_aggressive_resize=''
SENSIBLE_REVAMPED_O_w_mode_keys=''
SENSIBLE_REVAMPED_O_g_default_command=''
SENSIBLE_REVAMPED_O_g_prefix=''
SENSIBLE_REVAMPED_O_g__sensible_revamped_keys=''
SENSIBLE_REVAMPED_O_g__sensible_revamped_last_window_key=''
SENSIBLE_REVAMPED_O_g__sensible_revamped_reload_key=''
SENSIBLE_REVAMPED_O_g__sensible_revamped_resize_saved=''
SENSIBLE_REVAMPED_O_e_term=''
SENSIBLE_REVAMPED_O_e_program=''
SENSIBLE_REVAMPED_O_e_seen=''
SENSIBLE_REVAMPED_O_clients=''
SENSIBLE_REVAMPED_O_marks=''
SENSIBLE_REVAMPED_FLAG=''
SENSIBLE_REVAMPED_TMUX=''
SENSIBLE_REVAMPED_QUOTE="'"
SENSIBLE_REVAMPED_PLAN=''
SENSIBLE_REVAMPED_HELD=''
SENSIBLE_REVAMPED_THEIRS=''
SENSIBLE_REVAMPED_TERM=''
SENSIBLE_REVAMPED_PROGRAM=''
SENSIBLE_REVAMPED_SKIPPED=''
SENSIBLE_REVAMPED_KINDS='keys	on off'
