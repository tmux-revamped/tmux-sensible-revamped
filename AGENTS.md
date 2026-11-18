# tmux-sensible-revamped

Guidance for anyone, human or agent, changing tmux-sensible-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-sensible-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`sensible-revamped.tmux`](sensible-revamped.tmux) | The entry point TPM runs: it runs `bin/sensible-revamped apply` |
| [`bin/sensible-revamped`](bin/sensible-revamped) | The command: `apply`, `list`, `resize-sync`, `doctor`, `version`, `help` and the menu. `apply` and `resize-sync` run without loading the interface modules |
| [`lib/sensible.sh`](lib/sensible.sh) | Reading tmux, the terminal checks, building the list of tmux commands and sending it |
| [`lib/state.sh`](lib/state.sh) | Every global, including `SENSIBLE_REVAMPED_READS`, the list of options read from tmux, and one variable per option read |
| [`lib/core.sh`](lib/core.sh) | The version |
| [`lib/`](lib) | Every other file is the shared library, identical in every member |
| [`test/sensible.bats`](test/sensible.bats), [`test/plan.bats`](test/plan.bats), [`test/commands.bats`](test/commands.bats) | The library, the commands chosen for each tmux version and terminal, and the tool's own commands, against a stand-in tmux from [`test/sensible_helpers.bash`](test/sensible_helpers.bash) that answers a chain of commands |
| [`test/entrypoint.bats`](test/entrypoint.bats), [`test/keys.bats`](test/keys.bats) | The plugin on a private tmux server, and every key it binds pressed through a second tmux attached to it; both share [`test/server_helpers.bash`](test/server_helpers.bash) |
| [`screens/`](screens) | The tapes and the recording's tmux config, which leaves the plugin unloaded so a tape can show the values before and after `apply` |

## Names

- Settings are the tmux options `@sensible_revamped_keys`, `@sensible_revamped_last_window_key` and `@sensible_revamped_reload_key`, the long options with dashes, such as `--reload-key`, and the environment variables `SENSIBLE_REVAMPED_<SETTING>`.
- `@sensible_revamped_resize_saved` holds the `aggressive-resize` value while a control-mode client is attached; it is state, never a setting.
- It has no status placeholders.
- The version constant is `SENSIBLE_REVAMPED_VERSION`.
- The command's own functions and the library's never share a name, because the command is sourced after the library and would replace it.

## Behaviour

- `apply` makes four tmux calls: the version, one chain that prints every option in `SENSIBLE_REVAMPED_READS`, tmux's global environment and the clients, the key table, and one call that carries every command it decided on.
- The chain separates its answers with a `display-message -p` of a fixed mark. When the marks do not add up, because tmux refused the chain, each option is read alone, so a failed read never looks like an option that is unset.
- When tmux refuses the one call that sends the commands, the list is built again from a fresh read and each command is sent alone, so an entry the refused call already appended is not appended twice, and one refused command fails the run without stopping the others.
- `list` prints the same commands, one per line or as one JSON object, and sends nothing.
- It binds no key of the family's `M-` tier; it overrides the stock `C-n` and `C-p`, declared in the family key allocation, and binds two more only when their options name a key.
- The entry point clears every inherited `REVAMPED_` variable except the test switches, and every `SENSIBLE_REVAMPED_*_LOADED` guard; every other global is assigned outright in the state file.

## Domain rules

- An option is written only while it is empty or equal to tmux's own default, so a value the person set to that default cannot be told from an unset one and is replaced.
- A `terminal-features` or `terminal-overrides` entry is added only when it is absent from both the server and the global list, read as one comma-joined string, so a reload never grows the list.
- A key is bound only when the prefix table holds no binding for it. A binding whose command is the plugin's own is neither bound again nor reported; any other is left alone and named by `doctor`. Two settings that name one key bind it once, for the first action.
- The terminal is the one the tmux server started in. tmux gives a job its own `TERM`, the value of `default-terminal`, and sets `TERM_PROGRAM` to `tmux`, so both are read from `show-environment -g`; only when no server answers are the shell's own used. `COLORTERM`, `LC_TERMINAL`, `EDITOR`, `VISUAL`, `WAYLAND_DISPLAY` and `DISPLAY` reach a job unchanged.
- Truecolor is claimed when `COLORTERM` says `truecolor` or `24bit`, or when it is empty and terminfo reports `RGB` or `Tc`, and never for a `screen` or `tmux` terminal.
- Every option is gated to the tmux versions that have it: the copy tables changed in 2.4, the client hooks need 3.0, terminal features 3.2, `allow-passthrough` 3.3, sixel and hyperlinks 3.4 and `extended-keys-format` 3.5.
- The clipboard tool is `wl-copy` under Wayland, then `termux-clipboard-set`, `pbcopy` on macOS, `xclip` and `xsel` under X11, and `clip.exe` under WSL, which is read from `/proc/version`. With none, the copy keys use `copy-selection-and-cancel`.
- On tmux 3.0 and later the `client-attached` and `client-detached` hooks, at index 1000, run `resize-sync`, which reads the saved value, `aggressive-resize` and the clients in one call. The tool's path in the hook is quoted for `sh`, then escaped for a tmux double-quoted string, with `#` doubled.
- A line of the command list that is one space is an argument, the value of `word-separators`; only an empty line ends a command.

## Release

- `SENSIBLE_REVAMPED_VERSION` in [`lib/core.sh`](lib/core.sh) holds the version. Nobody edits it by hand.
- After a green `ci` run on `main`, [`release.yml`](.github/workflows/release.yml) runs semantic-release: a `feat` or `fix` since the last tag publishes a release, [`set-version.sh`](.github/scripts/set-version.sh) stamps the constant, and the notes go into [`CHANGELOG.md`](CHANGELOG.md).

## Gaps against FAMILY.md

As of 2026-11-17, none.
