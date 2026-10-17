<div align="center">

# tmux-sensible-revamped

<strong>Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone.</strong>

English &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">What it does</a> &nbsp;|&nbsp;
  <a href="#requirements">Requirements</a> &nbsp;|&nbsp;
  <a href="#installation">Installation</a> &nbsp;|&nbsp;
  <a href="#configuration">Configuration</a> &nbsp;|&nbsp;
  <a href="#key-bindings">Key bindings</a> &nbsp;|&nbsp;
  <a href="#how-it-works">How it works</a>
</p>

</div>

**22** tmux options set only while they still hold the tmux default. **11** terminal capability entries, each appended once. Every option gated to the tmux versions that have it, from **1.9** up.

---

## What it does

The plugin sets the defaults most tmux users end up writing by hand: no ESC delay, a large scrollback, windows numbered from 1, truecolor, and copy to the system clipboard. Each setting is checked against the running tmux version and the outer terminal before it is applied. An option your tmux does not have is skipped.

| Area | Settings | Minimum tmux |
|:-----|:---------|:-------------|
| Latency and focus | `escape-time 10`, `focus-events on` | 1.9 |
| Terminal type | `default-terminal` becomes `tmux-direct` when truecolor and that terminfo entry exist, else `tmux-256color` when its terminfo exists, else `screen-256color`. A current value of `screen` or `screen-256color` counts as unset | any |
| Truecolor | the `RGB` terminal feature on 3.2 and later, the `Tc` override before it. Enabled when `COLORTERM` says `truecolor` or `24bit`, or when `COLORTERM` is empty and terminfo reports `RGB` or `Tc`. Never enabled when `TERM` is a nested `screen` or `tmux` | any |
| Underlines | undercurl and colored underline through the `Smulx` and `Setulc` overrides | 3.0 |
| Clipboard and passthrough | `set-clipboard on`, `allow-passthrough on` on 3.3 and `all` on 3.4 and later, and the `clipboard`, `ccolour`, `cstyle`, `focus` and `title` terminal features | 3.2 for the features |
| Older tmux escapes | the OSC 52 `Ms` override and the `Ss` and `Se` cursor-shape overrides, for terminals known to honor them | below 3.2 only |
| Graphics | the `sixel` and `hyperlinks` terminal features for terminals that support them | 3.4 |
| Extended keys | `extended-keys on` and the `extkeys` feature for terminals that speak CSI u, and `extended-keys-format csi-u` on 3.5 and later | 3.2 |
| Scrollback and status | `history-limit 50000`, `display-time 4000`, `status-interval 5`, `repeat-time 1000`, `display-panes-time 2000`, `set-titles on` | any |
| Windows and panes | `base-index 1`, `pane-base-index 1`, `renumber-windows on`, `aggressive-resize on` | 1.6 and 1.7 for the second and third |
| Copy mode | `mode-keys vi` when `$EDITOR` or `$VISUAL` contains `vi`, else `emacs`. `word-separators` set to a single space, so a double click selects a whole path or URL | any |

The CSI u terminal list is xterm, kitty, foot, Alacritty, Contour, Rio, st, Konsole, iTerm2, WezTerm, Ghostty and mintty, matched on `TERM` and `TERM_PROGRAM`.

## Requirements

| Tool | Version | Notes |
|:-----|:--------|:------|
| tmux | 1.9 or later | Options newer than the running tmux are skipped |
| bash | 3.2 or later | macOS `/bin/bash` works |
| A clipboard tool | optional | `wl-copy`, `termux-clipboard-set`, `pbcopy`, `xclip`, `xsel` or `clip.exe`. Without one, copy goes through OSC 52 |

CI runs the test suite on Ubuntu LTS for x86_64 and arm64 with GNU and uutils coreutils, and on macOS for Apple Silicon and Intel with the system tools, GNU tools and uutils.

## Installation

With [TPM](https://github.com/tmux-plugins/tpm), add this line to `~/.tmux.conf` and press `prefix + I`:

```tmux
set -g @plugin 'tmux-revamped/tmux-sensible-revamped'
```

TPM loads plugins after the rest of your config, so the position of the line does not matter.

Without TPM, clone the repository and run the entry point from your config:

```bash
git clone https://github.com/tmux-revamped/tmux-sensible-revamped ~/.tmux/plugins/tmux-sensible-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-sensible-revamped/sensible-revamped.tmux
```

## Usage

Nothing to call. Reload tmux and check one of the values:

```bash
tmux show-option -gv history-limit
```

```text
50000
```

To keep your own value for any option in the table, set it in `~/.tmux.conf`. The plugin compares each option with the tmux default before writing, and a value that differs is left alone. A value you set equal to the tmux default cannot be told apart from an unset one, so the plugin replaces it.

## Configuration

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@sensible_revamped_keys` | `on` | `off` skips the reload, last-window, `C-p` and `C-n` bindings. The prefix wiring and the copy-mode bindings still apply |
| `@sensible_revamped_reload_key` | empty | prefix key that re-sources the config. Unbound until set |
| `@sensible_revamped_last_window_key` | empty | prefix key that switches to the last window. Unbound until set |

```tmux
set -g @sensible_revamped_reload_key 'R'
set -g @sensible_revamped_last_window_key 'a'
```

The reload key sources the first config that exists among `$XDG_CONFIG_HOME/tmux/tmux.conf`, `~/.config/tmux/tmux.conf` and `~/.tmux.conf`, then shows `tmux-sensible-revamped: reloaded`.

### Internal state

The plugin manages this option itself. Do not set it.

| Option | Holds |
|:-------|:------|
| `@sensible_revamped_resize_saved` | the global `aggressive-resize` value saved while a control-mode client is attached. It is restored and unset when the last control-mode client leaves |

## Key bindings

| Key | Table | Action | Default |
|:----|:------|:-------|:--------|
| `C-p` | prefix | previous window | bound when the key is free at load |
| `C-n` | prefix | next window | bound when the key is free at load |
| your prefix | prefix | `send-prefix` | bound when the prefix is not `C-b`, which is then unbound |
| `@sensible_revamped_reload_key` | prefix | re-source the config | unbound |
| `@sensible_revamped_last_window_key` | prefix | last window | unbound |
| `y`, `Enter`, `MouseDragEnd1Pane` | copy-mode-vi | copy and leave copy mode | always bound |
| `M-w`, `MouseDragEnd1Pane` | copy-mode | copy and leave copy mode | always bound |
| `v`, `C-v` | copy-mode-vi | begin selection, rectangle toggle | always bound |

A key counts as free when no binding for it exists at the moment the plugin loads. A plugin loaded later can still bind the same key, which is what `@sensible_revamped_keys 'off'` is for.

The copy-mode bindings replace any binding you made for those keys. To keep your own, bind it after the TPM `run` line. On tmux 2.4 and later they use `copy-pipe-and-cancel` into the clipboard tool, or `copy-selection-and-cancel` when there is none. Below 2.4 they use the old `vi-copy` and `emacs-copy` tables.

The clipboard tool is chosen in this order: `wl-copy` under Wayland, `termux-clipboard-set`, `pbcopy` on macOS, `xclip` then `xsel` under X11, and `clip.exe` on WSL. `clip.exe` comes after the X11 tools so a WSLg session keeps the UTF-8 path. On macOS, `default-command` runs your shell through `reattach-to-user-namespace` when that helper is installed.

## How it works

[`sensible-revamped.tmux`](sensible-revamped.tmux) runs [`src/sensible.sh`](src/sensible.sh) once at load. That script reads the tmux version, the operating system, `TERM`, `TERM_PROGRAM` and `COLORTERM`, then writes each setting through one of three guards:

| Guard | Rule |
|:------|:-----|
| default-aware setter | writes the option only while it is empty or equal to the tmux default |
| append-once | adds a `terminal-overrides` or `terminal-features` entry only when the entry is absent, so a reload does not grow the list |
| free-key check | binds a convenience key only when `tmux list-keys` shows no binding for it |

On tmux 3.0 and later, `client-attached` and `client-detached` hooks call the script with `--resize-sync`. While any iTerm2 control-mode client is attached, the hook saves the global `aggressive-resize` value and turns it off, because control mode breaks with it on. When the last control-mode client leaves, the saved value comes back. A normal client attaching changes nothing.

The decisions live as pure functions in [`src/lib/sensible/sensible.sh`](src/lib/sensible/sensible.sh). Setting `SENSIBLE_DRY_RUN` makes the applier print each tmux command instead of running it, which is how the tests cover the version matrix.

## Development

| Command | What it runs |
|:--------|:-------------|
| `make test` | the bats suite |
| `make lint` | shellcheck at warning level on every shell file |
| `make coverage` | kcov line coverage with a 95 percent floor, Linux only |
| [`family/bin/audit`](family/bin/audit) | this repository against the family contract |

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
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Pick a URL, path, hash or any other token off the screen with fzf and type it at the cursor, in pure shell |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Switch to, kill, rename or create tmux sessions, windows and panes from fzf pickers in a popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Show the active pane's git branch, changes and provider counts in the tmux status bar without blocking it |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, clock, power and memory in the tmux status bar, from NVIDIA, AMD, Intel and Apple GPUs |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in the tmux status bar, parsed from kubeconfig without kubectl |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Launch any TUI app in a popup or a window, scoped to the current pane's directory, with one configurable bindi |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness, CI and family tooling |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | **this plugin**, Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

### Checking an installation

With every member on disk, one command reports any conflict between them:

```sh
family/bin/doctor --live
```

It reads each member and the running tmux server, and reports duplicate keys,
duplicate status placeholders, options outside the naming grammar, and any
member whose contract version has fallen behind.

<!-- family:end -->
