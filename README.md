<div align="center">

# tmux-sensible-revamped

<strong>Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone.</strong>

English &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-sensible-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-sensible-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-sensible-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-sensible-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-sensible-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-sensible-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>Quick start</strong></a> &nbsp;|&nbsp;
  <a href="#usage">Usage</a> &nbsp;|&nbsp;
  <a href="#what-it-sets">What it sets</a> &nbsp;|&nbsp;
  <a href="#key-bindings">Key bindings</a> &nbsp;|&nbsp;
  <a href="#how-it-works">How it works</a> &nbsp;|&nbsp;
  <a href="#screens">Screens</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="sensible-revamped raising tmux's defaults in one command, then switching windows with prefix C-n and C-p" width="800">
</p>

```console
$ tmux show-option -gv history-limit
2000
$ sensible-revamped apply
$ tmux show-option -gv history-limit
50000
```

The plugin sets the defaults most tmux users end up writing by hand: no ESC delay, a large scrollback, windows numbered from 1, truecolor, and copy to the system clipboard. Each setting is checked against the running tmux version and the outer terminal before it is applied. An option your tmux does not have is skipped.

---

## Quick start

### Prerequisites

| Tool | Version | Used for |
|:-----|:--------|:---------|
| tmux | 3.2 or later | the family floor; an option newer than the running tmux is skipped |
| clipboard tool | optional | `wl-copy`, `termux-clipboard-set`, `pbcopy`, `xclip`, `xsel` or `clip.exe`; without one a copy goes through the terminal with OSC 52 |
| `infocmp` | optional | picks `tmux-direct` or `tmux-256color` for `default-terminal`; without it the value is `screen-256color` |
| gum | optional | the menu, tables and colours of `sensible-revamped`; without it every command prints plain text |

### Install

```tmux
set -g @plugin 'tmux-revamped/tmux-sensible-revamped'
```

Then press `prefix + I`. Without TPM, clone the repository and run its entry point from `~/.tmux.conf`:

```bash
git clone https://github.com/tmux-revamped/tmux-sensible-revamped ~/.tmux/plugins/tmux-sensible-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-sensible-revamped/sensible-revamped.tmux
```

`make install` in the clone also puts `sensible-revamped` in `~/.local/bin`, with its man page and completions under `~/.local/share`.

### Verify

```bash
~/.tmux/plugins/tmux-sensible-revamped/bin/sensible-revamped doctor
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

| Command | What it does |
|:--------|:-------------|
| `sensible-revamped apply` | Sets the defaults and binds the keys now; the entry point runs it when tmux loads the plugin |
| `sensible-revamped list` | Prints every tmux command `apply` would run and changes nothing; `--json` prints one object |
| `sensible-revamped resize-sync` | Turns `aggressive-resize` off while a control-mode client is attached and puts it back afterwards; the client hooks run it |
| `sensible-revamped doctor` | One row per dependency, the clipboard tool and any key left alone included |
| `sensible-revamped version` | The version, then the tmux version |
| `sensible-revamped help` | The help page; `man sensible-revamped` documents the same commands and settings |
| `sensible-revamped` | On a terminal, a menu |

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

Every option is also a command option with dashes, such as `--reload-key R`, and an environment variable, such as `SENSIBLE_REVAMPED_RELOAD_KEY`; the command line wins over the environment, and the environment over the tmux option. An empty tmux option means its default. `doctor` names any setting that holds a value the plugin does not know. The plugin writes `@sensible_revamped_resize_saved` itself.

<a id="what-it-sets"></a>

## What it sets

| Area | Settings | Minimum tmux |
|:-----|:---------|:-------------|
| Latency and focus | `escape-time 10`, `focus-events on` | 1.9 |
| Terminal type | `default-terminal` becomes `tmux-direct` when truecolor and that terminfo entry exist, else `tmux-256color` when its terminfo exists, else `screen-256color`. A current value of `screen` or `screen-256color` counts as unset | any |
| Truecolor | the `RGB` terminal feature on 3.2 and later, the `Tc` override before it. Enabled when `COLORTERM` says `truecolor` or `24bit`, or when `COLORTERM` is empty and terminfo reports `RGB` or `Tc`. Never enabled when `TERM` is a nested `screen` or `tmux` | any |
| Underlines | undercurl and colored underline through the `Smulx` and `Setulc` overrides | 3.0 |
| Clipboard and passthrough | `set-clipboard on`, `allow-passthrough on` on 3.3 and `all` on 3.4 and later, and the `clipboard`, `ccolour`, `cstyle`, `focus` and `title` terminal features | 3.2 for the features |
| Older tmux escapes | the OSC 52 `Ms` override and the `Ss` and `Se` cursor-shape overrides, for terminals known to honor them | below 3.2 only |
| Graphics | the `sixel` and `hyperlinks` terminal features for terminals that support them | 3.4 |
| Extended keys | `extended-keys on`, and `extended-keys-format csi-u` on 3.5 and later, whatever `TERM` the server started with: tmux sends the request only to a terminal it knows has the `extkeys` feature. The `extkeys` feature itself is claimed for terminals that speak CSI u | 3.2 |
| Scrollback and status | `history-limit 50000`, `display-time 4000`, `status-interval 5`, `repeat-time 1000`, `display-panes-time 2000`, `set-titles on` | any |
| Windows and panes | `base-index 1`, `pane-base-index 1`, `renumber-windows on`, `aggressive-resize on` | 1.6 and 1.7 for the second and third |
| Copy mode | `mode-keys vi` when `$EDITOR` or `$VISUAL` contains `vi`, else `emacs`. `word-separators` set to a single space, so a double click selects a whole path or URL | any |

The CSI u terminal list is xterm, kitty, foot, Alacritty, Contour, Rio, st, Konsole, iTerm2, WezTerm, Ghostty and mintty, matched on `TERM` and `TERM_PROGRAM`.

The terminal is the one the tmux server started in: tmux gives a plugin its own `TERM` and `TERM_PROGRAM`, so the plugin reads both from tmux's global environment.

<a id="key-bindings"></a>

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

<a id="how-it-works"></a>

## How it works

[`sensible-revamped.tmux`](sensible-revamped.tmux) runs `bin/sensible-revamped apply` once at load. It reads the tmux version, every option it may change, the key table and the terminal in three tmux calls, then sends every command in a fourth, each through one of three guards:

| Guard | Rule |
|:------|:-----|
| default-aware setter | writes the option only while it is empty or equal to the tmux default |
| append-once | adds a `terminal-overrides` or `terminal-features` entry only when the entry is absent, so a reload does not grow the list |
| free-key check | binds a convenience key only when `tmux list-keys` shows no binding for it |

On tmux 3.0 and later, `client-attached` and `client-detached` hooks run `sensible-revamped resize-sync`. While any iTerm2 control-mode client is attached, the hook saves the global `aggressive-resize` value and turns it off, because control mode breaks with it on. When the last control-mode client leaves, the saved value comes back. A normal client attaching changes nothing.

`sensible-revamped list` prints every command `apply` would run and changes nothing, which is how to see what the plugin would do on your server.

<a id="screens"></a>

## Screens

<details>
<summary>Every screen, recorded inside a real tmux with <code>make screens</code>, with each key on the status line</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/defaults.png" alt="sensible-revamped: apply raises tmux's own defaults"><br><sub><code>apply</code> raises tmux's own defaults, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/next-window.png" alt="sensible-revamped: prefix C-n goes to the next window"><br><sub><code>prefix C-n</code> goes to the next window, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu.png" alt="sensible-revamped: The menu"><br><sub>The menu, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="sensible-revamped: doctor"><br><sub><code>doctor</code>, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/reload.png" alt="sensible-revamped: The reload key sources the config again"><br><sub>The reload key sources the config again, from <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/last-window.png" alt="sensible-revamped: The last-window key goes back"><br><sub>The last-window key goes back, from <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/copy.png" alt="sensible-revamped: v selects in vi copy-mode"><br><sub><code>v</code> selects in vi copy-mode, from <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/copied.png" alt="sensible-revamped: y copies to the clipboard tool"><br><sub><code>y</code> copies to the clipboard tool, from <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/list.png" alt="sensible-revamped: list prints every command"><br><sub><code>list</code> prints every command, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="sensible-revamped: The menu without gum"><br><sub>The menu without gum, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="sensible-revamped: doctor from the menu"><br><sub><code>doctor</code> from the menu, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="sensible-revamped: The version"><br><sub>The version, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="sensible-revamped: An unknown command"><br><sub>An unknown command, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/themes.png" alt="sensible-revamped: The header in six themes"><br><sub>The header in six themes, from <code>themes.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/help.png" alt="sensible-revamped: The help page"><br><sub>The help page, from <code>help.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="sensible-revamped: An accent from SENSIBLE_REVAMPED_ACCENT"><br><sub>An accent from <code>SENSIBLE_REVAMPED_ACCENT</code>, from <code>stills.tape</code></sub></td>
</tr>
</table>

</details>

## Portability

The plugin is POSIX `sh`. CI runs every suite on each row below.

| Shell | Status |
|:------|:-------|
| `dash`, `/bin/sh` on macOS | Supported |
| `bash` 3.2 and 5.x, the system's `zsh` and Homebrew's | Supported |

| System | Status |
|:-------|:-------|
| macOS | Tahoe on Apple Silicon and Intel, with the tools it ships, Homebrew's GNU tools and Homebrew's uutils |
| Linux | Ubuntu 26.04 on x86_64 and arm64, with GNU coreutils, uutils and BusyBox |

## Development

| Command | What it runs |
|:--------|:-------------|
| `make fmt` | shfmt `-i 2` on every script |
| `make lint` | shfmt, ShellCheck, mandoc, yamllint and actionlint, at zero findings |
| `make test` | The bats suites under the system `sh` |
| `make test-all` | The suites under every installed shell, both builds of bash and zsh on macOS |
| `make test-linux` | The suites in an Ubuntu container |
| `make coverage` | bashcov on this Mac and in the Ubuntu container, merged and gated at 100 percent |
| `make screens` | The screens above, recorded from the real plugin inside tmux with VHS, on macOS |
| `make install` | The command, its man page and completions under `PREFIX` |

On macOS, `brew bundle` installs every tool these targets call, from the [`Brewfile`](Brewfile).

Commits follow the conventional commit format and go straight to `main`. After a green `ci` run on `main`, `release.yml` runs semantic-release: every `feat` or `fix` since the last tag publishes a release, stamps the version constant and adds the notes to [`CHANGELOG.md`](CHANGELOG.md).

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the same contract in [`FAMILY.md`](FAMILY.md) and the same shared library, and they are built to be installed together: no member claims a key or a tmux option that another member claims.

A defect found in one member is hunted across all of them before the fix is called done.

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
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Open any terminal app in a tmux popup, window or split from one menu, starting at the project root |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness and CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | **this plugin**, Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

<!-- family:end -->
