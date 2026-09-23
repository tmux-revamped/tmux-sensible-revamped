<div align="center">

<h1>tmux-sensible-revamped</h1>

**Sensible tmux defaults that normalize behavior across every tmux version, OS, and terminal, without clobbering your config.**

[![Tests](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](CHANGELOG.md)

</div>

**40+** normalized settings · **tmux 1.9 to 3.5** · **Linux, macOS, WSL** · **96** tests · **95%+** coverage

One config that behaves the same regardless of the tmux version, the operating system, the terminal emulator, and what is running inside the pane. Every option is gated to the tmux versions that support it, so the same plugin runs cleanly on every tmux TPM supports, from 1.9 up. Truecolor, the system clipboard, undercurl, and extended keys are enabled per detected capability, and several long-standing terminal bugs are worked around. Your own explicit settings always win.

Built from [tmux-plugin-template](https://github.com/tmux-revamped/tmux-plugin-template).

<table>
<tr>
<td><strong>Version-aware</strong><br>Each option is applied only on the tmux versions that support it, so nothing errors from 1.9 to 3.5.</td>
<td><strong>Terminal-aware</strong><br>Truecolor, OSC 52 clipboard, undercurl, and CSI u keys are enabled per detected capability, with per-emulator fixes.</td>
</tr>
<tr>
<td><strong>Clipboard everywhere</strong><br>Copy lands in the system clipboard on Wayland, X11, macOS, and WSL, and over SSH through OSC 52.</td>
<td><strong>Non-destructive</strong><br>Preference options are set only when you have not changed them, so explicit configuration is never overwritten.</td>
</tr>
</table>

## What it normalizes

Options above your tmux version are skipped silently. The minimum is tmux 1.9, the floor TPM supports.

| Area | Settings | Min tmux |
|------|----------|----------|
| Latency and focus | `escape-time 10` (kills the vim ESC delay), `focus-events on`, both default-aware | 1.9 |
| Color | `default-terminal` resolved to `tmux-direct` when truecolor and its terminfo are present, else `tmux-256color`, with a `screen-256color` fallback. `screen-256color` is treated as unconfigured so the upgrade still fires. Truecolor via `terminal-features ,*:RGB` or the legacy `Tc` override, detected from `COLORTERM` or terminfo, never on a nested screen or tmux TERM | 3.2 for features, any for the override |
| Underlines | undercurl and colored underline overrides (`Smulx`, `Setulc`) | 3.0 |
| Clipboard and capabilities | `set-clipboard on` (default-aware), `allow-passthrough all` on 3.4+ or `on` on 3.3, and the `clipboard`, cursor color, cursor style, focus, and title terminal features | on any, 3.2, 3.3 |
| Older-tmux escapes | OSC 52 clipboard via `Ms` and cursor-shape passthrough via `Ss`/`Se`, emitted below 3.2 for known terminals where the newer features do not exist | below 3.2 |
| Graphics | sixel and OSC 8 hyperlink terminal features for capable terminals | 3.4 |
| Extended keys | `extended-keys on` on terminals that support CSI u (xterm, kitty, foot, Alacritty, Contour, Rio, st, Konsole, WezTerm, iTerm2, Ghostty, mintty), the `extkeys` feature, `extended-keys-format csi-u` | 3.2, 3.5 for the format |
| Scrollback and status | `history-limit 50000`, `display-time 4000`, `status-interval 5`, `repeat-time 1000`, `display-panes-time 2000`, `set-titles on`, all default-aware | any |
| Window and pane | `base-index 1`, `pane-base-index 1`, `renumber-windows on`, `automatic-rename on`, `aggressive-resize on` for normal clients, off under iTerm2 control mode | 1.6 and 1.7 where noted |
| Copy mode | `mode-keys` from `$EDITOR`, version-gated system-clipboard yank and mouse-drag bindings (`copy-pipe-and-cancel` on 2.4+, the `vi-copy`/`emacs-copy` tables below), vi selection keys (`v`, `C-v`, `Enter`), and path-friendly `word-separators` | any |

It also carries over every default binding from upstream tmux-sensible, each set only when the key is still free: `prefix + R` reloads the config resolving the path in XDG order, the prefix letter switches to the last window, `C-p` and `C-n` move between windows, and `send-prefix` is wired when the prefix is not `C-b`. The macOS `reattach-to-user-namespace` wrapper is installed only when that legacy helper is present.

## Install

With [TPM](https://github.com/tmux-plugins/tpm), add to `~/.tmux.conf`:

```tmux
set -g @plugin 'tmux-revamped/tmux-sensible-revamped'
```

Then press `prefix + I` to install. Place it early so your own settings, sourced later, take precedence.

Manual install:

```bash
git clone https://github.com/tmux-revamped/tmux-sensible-revamped ~/.tmux/plugins/tmux-sensible-revamped
run-shell ~/.tmux/plugins/tmux-sensible-revamped/sensible-revamped.tmux
```

## Behavior notes

- **Your config wins.** Scrollback, display time, status interval, repeat time, base index, the terminal type, focus events, clipboard, allow-passthrough, status keys, titles, display-panes time, word separators, and mode keys are applied only when still at the tmux default, so a value you set yourself is left alone.
- **Nothing noisy is forced.** It does not touch activity monitoring or the mouse, so your own choices there are never overridden.
- **Mouse stays off.** Enabling the mouse breaks terminal-native selection for many users, so this plugin does not touch it.
- **Prefix is untouched.** It keeps `C-b`, matching upstream tmux-sensible.
- **Clipboard order.** The copy command is chosen by environment: Wayland `wl-copy`, Termux `termux-clipboard-set`, macOS `pbcopy`, X11 `xclip` then `xsel`, and finally WSL `clip.exe`. `clip.exe` trails the X11 tools so a WSLg session keeps the UTF-8-safe path. With none available it relies on `set-clipboard on` and OSC 52, which also carries the clipboard back over SSH.

## Known bugs it works around

| Symptom | Fix |
|---------|-----|
| vim or neovim lag when leaving insert mode | `escape-time 10` |
| Truecolor not working inside tmux | `default-terminal tmux-256color` plus the `RGB` capability, not a non-256 terminal type |
| Italics rendering as reverse video | `tmux-256color` instead of `screen-256color` |
| Clipboard not propagating over SSH | `set-clipboard on` and the OSC 52 `clipboard` feature |
| iTerm2 native integration breaking on resize | `aggressive-resize` is off only under iTerm2 control mode (a client-attached hook on tmux 3.0+), on everywhere else |
| Apple Terminal.app | left at 256 colors, since it has neither truecolor nor OSC 52 |

## Compatibility

Works on every tmux version TPM supports, 1.9 and up, on Linux (x86_64 and arm64), macOS (Intel and Apple Silicon), and WSL. Capabilities such as truecolor, OSC 52 clipboard, undercurl, and extended keys also depend on the outer terminal supporting them. iTerm2, Alacritty, Kitty, WezTerm, Ghostty, Konsole, Windows Terminal, and recent xterm support the full set; GNOME Terminal lacks OSC 52; Apple Terminal.app lacks truecolor and OSC 52.

## Development

```bash
make test    # bats suite
make lint    # shellcheck
make coverage  # kcov line coverage on Linux
```

The decision logic lives in [`src/lib/sensible/sensible.sh`](src/lib/sensible/sensible.sh) as pure, seam-backed helpers, and the applier in [`src/sensible.sh`](src/sensible.sh) runs under a dry-run mode so the full version matrix is validated without a live tmux.

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the
same contract in [`FAMILY.md`](FAMILY.md), the same tooling under `family/`, and
the same shared library, all held byte-identical by a checksum manifest. They are
built to be installed together: no member claims a key or a tmux option that
another member claims.

A defect found in one member is hunted across all of them before the fix is
called done. That obligation is written into the contract rather than left to
memory, and `family/bin/sweep` is how it is discharged.

| Member | What it does |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | Edit your tmux config, save, and watch it reload itself, no key, no command |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | Battery status for your tmux status bar, without ever blocking the status render |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | Every connected Bluetooth device and its battery in your tmux status bar, without blocking the render |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPU load, temperature, and frequency in your tmux status bar, without ever blocking the render |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | Disk usage for your tmux status bar, without ever blocking the status render |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Fuzzy-grab any URL, path, or word off the screen and paste it, pure shell, no Python |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Jump to any session, window, or pane, or kill it, from one fzf popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Git repository status in your tmux status bar, without ever blocking the render |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, frequency, and memory for your tmux status bar |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in your tmux status bar, async, kubectl-free, never blocking |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Launch any TUI app in a popup or a window, scoped to the current pane's directory, with one configurable bindi |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Standard pane and window management bindings for tmux, version aware, vim friendly, and fully configurable |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | One plugin that captures every session, window, pane, layout, and working |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | A template for building non-blocking tmux status plugins |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in your tmux status bar, with zero temp files: all state lives in tmux options |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM usage for your tmux status bar, without ever blocking the status render |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Mouse wheel that does the right thing: scroll the app directly, copy-mode everywhere else. No app names to con |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | **this plugin**, Sensible tmux defaults that normalize behavior across every tmux version, OS, and terminal, without clobbering |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | --- |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local clock and world clocks in your tmux status bar, without ever blocking the render |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather in your tmux status bar, fetched in the background so the render never waits on the network |

### Checking an installation

With every member on disk, one command reports any conflict between them:

```sh
family/bin/doctor --live
```

It reads each member and the running tmux server, and reports duplicate keys,
duplicate status placeholders, options outside the naming grammar, and any
member whose contract version has fallen behind.

<!-- family:end -->
