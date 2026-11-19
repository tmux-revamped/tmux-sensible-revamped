<div align="center">

# tmux-sensible-revamped

<strong>按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; 简体中文 &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-sensible-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-sensible-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-sensible-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-sensible-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-sensible-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-sensible-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速开始"><strong>快速开始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#设置的内容">设置的内容</a> &nbsp;|&nbsp;
  <a href="#快捷键">快捷键</a> &nbsp;|&nbsp;
  <a href="#工作原理">工作原理</a> &nbsp;|&nbsp;
  <a href="#界面">界面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="sensible-revamped 用一条命令调高 tmux 的默认值，再用 prefix C-n 和 C-p 切换窗口" width="800">
</p>

```console
$ tmux show-option -gv history-limit
2000
$ sensible-revamped apply
$ tmux show-option -gv history-limit
50000
```

本插件替你完成大多数 tmux 用户最终都会手写的默认设置：去掉 ESC 延迟、加大回滚缓冲区、窗口从 1 开始编号、启用真彩色，以及把复制内容送到系统剪贴板。每项设置在应用前都会检查正在运行的 tmux 版本和外层终端。你的 tmux 没有的选项会被跳过。

---

## 快速开始

### 前提条件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或更高 | 家族的最低版本；正在运行的 tmux 没有的选项会被跳过 |
| 剪贴板工具 | 可选 | `wl-copy`、`termux-clipboard-set`、`pbcopy`、`xclip`、`xsel` 或 `clip.exe`；没有时复制经由终端的 OSC 52 |
| `infocmp` | 可选 | 为 `default-terminal` 选择 `tmux-direct` 或 `tmux-256color`；没有时取 `screen-256color` |
| gum | 可选 | `sensible-revamped` 的菜单、表格和颜色；没有它，所有命令都输出纯文本 |

### 安装

```tmux
set -g @plugin 'tmux-revamped/tmux-sensible-revamped'
```

然后按 `prefix + I`。不用 TPM 时，克隆仓库，并在 `~/.tmux.conf` 中运行它的入口文件：

```bash
git clone https://github.com/tmux-revamped/tmux-sensible-revamped ~/.tmux/plugins/tmux-sensible-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-sensible-revamped/sensible-revamped.tmux
```

在克隆的目录中运行 `make install`，还会把 `sensible-revamped` 放进 `~/.local/bin`，把它的 man 手册和补全放在 `~/.local/share` 下。

### 验证

```bash
~/.tmux/plugins/tmux-sensible-revamped/bin/sensible-revamped doctor
```

## 用法

无需调用任何东西。重新加载 tmux 后检查其中一个值：

```bash
tmux show-option -gv history-limit
```

```text
50000
```

若想对表中某个选项使用自己的值，在 `~/.tmux.conf` 中设置即可。插件写入前会把每个选项与 tmux 默认值比较，不同的值保持不动。你设置的值若恰好等于 tmux 默认值，就无法与未设置区分，插件会将其替换。

| 命令 | 作用 |
|:--------|:-------------|
| `sensible-revamped apply` | 立即设置默认值并绑定按键；插件加载时入口点会运行它 |
| `sensible-revamped list` | 打印 `apply` 会运行的每条 tmux 命令，不做任何修改；`--json` 输出一个对象 |
| `sensible-revamped resize-sync` | 有控制模式客户端连接时关闭 `aggressive-resize`，之后再恢复；由客户端钩子运行 |
| `sensible-revamped doctor` | 每个依赖一行，包括剪贴板工具和保持不动的按键 |
| `sensible-revamped version` | 版本，然后是 tmux 版本 |
| `sensible-revamped help` | 帮助页；`man sensible-revamped` 记录相同的命令和设置 |
| `sensible-revamped` | 在终端上显示菜单 |

| 选项 | 默认值 | 含义 |
|:-------|:--------|:--------|
| `@sensible_revamped_keys` | `on` | 设为 `off` 时跳过重新加载、上一个窗口、`C-p` 和 `C-n` 的绑定。前缀键设置和复制模式的绑定仍会应用 |
| `@sensible_revamped_reload_key` | 空 | 重新加载配置的前缀键。设置之前不绑定 |
| `@sensible_revamped_last_window_key` | 空 | 切换到上一个窗口的前缀键。设置之前不绑定 |

```tmux
set -g @sensible_revamped_reload_key 'R'
set -g @sensible_revamped_last_window_key 'a'
```

重新加载键会加载 `$XDG_CONFIG_HOME/tmux/tmux.conf`、`~/.config/tmux/tmux.conf` 和 `~/.tmux.conf` 中第一个存在的文件，然后显示 `tmux-sensible-revamped: reloaded`。

每个选项也可以用带连字符的命令选项（例如 `--reload-key R`）和环境变量（例如 `SENSIBLE_REVAMPED_RELOAD_KEY`）设置；命令行优先于环境变量，环境变量优先于 tmux 选项。空的 tmux 选项表示使用默认值。`doctor` 会指出值无法识别的设置。`@sensible_revamped_resize_saved` 由插件自己写入。

<a id="设置的内容"></a>

## 设置的内容

| 方面 | 设置 | 最低 tmux 版本 |
|:-----|:---------|:-------------|
| 延迟与焦点 | `escape-time 10`、`focus-events on` | 1.9 |
| 终端类型 | 若有真彩色且存在对应 terminfo，`default-terminal` 设为 `tmux-direct`；否则若存在 `tmux-256color` 的 terminfo 则用它；再否则用 `screen-256color`。当前值为 `screen` 或 `screen-256color` 时视为未设置 | 任意 |
| 真彩色 | 3.2 及以后使用终端特性 `RGB`，之前使用 `Tc` 覆盖。当 `COLORTERM` 为 `truecolor` 或 `24bit`，或 `COLORTERM` 为空且 terminfo 报告 `RGB` 或 `Tc` 时启用。`TERM` 为嵌套的 `screen` 或 `tmux` 时从不启用 | 任意 |
| 下划线 | 通过 `Smulx` 和 `Setulc` 覆盖实现波浪下划线和彩色下划线 | 3.0 |
| 剪贴板与透传 | `set-clipboard on`，3.3 上为 `allow-passthrough on`，3.4 及以后为 `all`，以及终端特性 `clipboard`、`ccolour`、`cstyle`、`focus` 和 `title` | 特性需要 3.2 |
| 旧版 tmux 的转义序列 | OSC 52 的 `Ms` 覆盖，以及光标形状的 `Ss` 和 `Se` 覆盖，仅用于已知支持的终端 | 仅 3.2 以下 |
| 图形 | 为支持的终端启用 `sixel` 和 `hyperlinks` 终端特性 | 3.4 |
| 扩展按键 | 无论服务器以哪个 `TERM` 启动，都设置 `extended-keys on`，3.5 及以后设置 `extended-keys-format csi-u`：tmux 只向已知具备 `extkeys` 特性的终端发送请求。`extkeys` 特性本身只为支持 CSI u 的终端声明 | 3.2 |
| 回滚与状态栏 | `history-limit 50000`、`display-time 4000`、`status-interval 5`、`repeat-time 1000`、`display-panes-time 2000`、`set-titles on` | 任意 |
| 窗口与窗格 | `base-index 1`、`pane-base-index 1`、`renumber-windows on`、`aggressive-resize on` | 第二项需要 1.6，第三项需要 1.7 |
| 复制模式 | `$EDITOR` 或 `$VISUAL` 含有 `vi` 时为 `mode-keys vi`，否则为 `emacs`。`word-separators` 设为单个空格，因此双击会选中整个路径或 URL | 任意 |

视为支持 CSI u 的终端有 xterm、kitty、foot、Alacritty、Contour、Rio、st、Konsole、iTerm2、WezTerm、Ghostty 和 mintty，根据 `TERM` 和 `TERM_PROGRAM` 判断。

这里的终端是 tmux 服务器启动时所在的终端：tmux 交给插件的是它自己的 `TERM` 和 `TERM_PROGRAM`，所以插件从 tmux 的全局环境读取这两个值。

<a id="快捷键"></a>

## 快捷键

| 按键 | 键表 | 动作 | 默认 |
|:----|:------|:-------|:--------|
| `C-p` | prefix | 上一个窗口 | 加载时该键空闲则绑定 |
| `C-n` | prefix | 下一个窗口 | 加载时该键空闲则绑定 |
| 你的前缀键 | prefix | `send-prefix` | 前缀键不是 `C-b` 时绑定，并解除 `C-b` |
| `@sensible_revamped_reload_key` | prefix | 重新加载配置 | 不绑定 |
| `@sensible_revamped_last_window_key` | prefix | 上一个窗口 | 不绑定 |
| `y`、`Enter`、`MouseDragEnd1Pane` | copy-mode-vi | 复制并退出复制模式 | 始终绑定 |
| `M-w`、`MouseDragEnd1Pane` | copy-mode | 复制并退出复制模式 | 始终绑定 |
| `v`、`C-v` | copy-mode-vi | 开始选择、切换矩形选择 | 始终绑定 |

插件加载时某个键没有任何绑定，就视为空闲。之后加载的插件仍可绑定同一个键，`@sensible_revamped_keys 'off'` 就是为此准备的。

复制模式的绑定会替换你为这些键设置的绑定。若要保留自己的绑定，请在 TPM 的 `run` 行之后绑定。tmux 2.4 及以后使用 `copy-pipe-and-cancel` 送到剪贴板工具，没有工具时使用 `copy-selection-and-cancel`。2.4 以下使用旧的 `vi-copy` 和 `emacs-copy` 键表。

剪贴板工具按以下顺序选择：Wayland 下的 `wl-copy`、`termux-clipboard-set`、macOS 上的 `pbcopy`、X11 下先 `xclip` 后 `xsel`，以及 WSL 上的 `clip.exe`。`clip.exe` 排在 X11 工具之后，使 WSLg 会话保持 UTF-8 正确。在 macOS 上，若安装了 `reattach-to-user-namespace`，`default-command` 会通过它启动你的 shell。

<a id="工作原理"></a>

## 工作原理

[`sensible-revamped.tmux`](sensible-revamped.tmux) 在加载时运行一次 `bin/sensible-revamped apply`。它用三次 tmux 调用读取 tmux 版本、可能修改的每个选项、按键表和终端，再用第四次调用发送所有命令，每条命令都经过以下三种保护之一：

| 保护 | 规则 |
|:------|:-----|
| 检查默认值的写入 | 只在选项为空或等于 tmux 默认值时写入 |
| 只追加一次 | `terminal-overrides` 或 `terminal-features` 的条目只在缺失时添加，因此重新加载不会让列表变长 |
| 空闲键检查 | 只在 `tmux list-keys` 显示该键没有绑定时才绑定便捷键 |

在 tmux 3.0 及以后，`client-attached` 和 `client-detached` 钩子会运行 `sensible-revamped resize-sync`。只要有 iTerm2 控制模式客户端连接，钩子就保存全局 `aggressive-resize` 的值并将其关闭，因为开启时控制模式会出问题。最后一个控制模式客户端离开后，恢复保存的值。普通客户端连接不会改变任何东西。

`sensible-revamped list` 打印 `apply` 会运行的每条命令而不做任何修改，可以用它查看插件在你的服务器上会做什么。

<a id="界面"></a>

## 界面

<details>
<summary>所有界面，在真实的 tmux 中用 <code>make screens</code> 录制，每个按键显示在状态栏上</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/defaults.png" alt="sensible-revamped：apply 调高 tmux 自带的默认值"><br><sub><code>apply</code> 调高 tmux 自带的默认值，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/next-window.png" alt="sensible-revamped：prefix C-n 切换到下一个窗口"><br><sub><code>prefix C-n</code> 切换到下一个窗口，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu.png" alt="sensible-revamped：菜单"><br><sub>菜单，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="sensible-revamped：doctor"><br><sub><code>doctor</code>，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/reload.png" alt="sensible-revamped：重新加载键再次加载配置"><br><sub>重新加载键再次加载配置，来自 <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/last-window.png" alt="sensible-revamped：回到上一个窗口的按键"><br><sub>回到上一个窗口的按键，来自 <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/copy.png" alt="sensible-revamped：在 vi 复制模式中用 v 选择"><br><sub>在 vi 复制模式中用 <code>v</code> 选择，来自 <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/copied.png" alt="sensible-revamped：y 复制到剪贴板工具"><br><sub><code>y</code> 复制到剪贴板工具，来自 <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/list.png" alt="sensible-revamped：list 打印每条命令"><br><sub><code>list</code> 打印每条命令，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="sensible-revamped：没有 gum 的菜单"><br><sub>没有 gum 的菜单，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="sensible-revamped：从菜单运行 doctor"><br><sub>从菜单运行 <code>doctor</code>，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="sensible-revamped：版本"><br><sub>版本，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="sensible-revamped：未知命令"><br><sub>未知命令，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/themes.png" alt="sensible-revamped：六种主题下的标题"><br><sub>六种主题下的标题，来自 <code>themes.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/help.png" alt="sensible-revamped：帮助页"><br><sub>帮助页，来自 <code>help.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="sensible-revamped：来自 SENSIBLE_REVAMPED_ACCENT 的强调色"><br><sub>来自 <code>SENSIBLE_REVAMPED_ACCENT</code> 的强调色，来自 <code>stills.tape</code></sub></td>
</tr>
</table>

</details>

## 可移植性

插件是 POSIX `sh`。CI 在下面每一行上运行全部测试。

| Shell | 状态 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支持 |
| `bash` 3.2 和 5.x、系统自带的 `zsh` 和 Homebrew 的 `zsh` | 支持 |

| 系统 | 状态 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用系统自带的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |

## 开发

| 命令 | 运行内容 |
|:--------|:-------------|
| `make fmt` | 对每个脚本运行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零告警 |
| `make test` | 在系统 `sh` 下运行 bats 测试 |
| `make test-all` | 在每个已安装的 shell 下运行测试，macOS 上包括 bash 和 zsh 的两种构建 |
| `make test-linux` | 在 Ubuntu 容器中运行测试 |
| `make coverage` | 在这台 Mac 和 Ubuntu 容器中运行 bashcov，合并后以 100% 为门槛 |
| `make screens` | 用 VHS 在 tmux 中从真实插件录制上面的界面，在 macOS 上运行 |
| `make install` | 把命令、man 手册和补全安装到 `PREFIX` 下 |

在 macOS 上，运行 `brew bundle` 会根据 [`Brewfile`](Brewfile) 安装这些目标用到的所有工具。

提交遵循 Conventional Commits 格式，直接进入 `main`。`main` 上的 `ci` 通过后，`release.yml` 运行 semantic-release：自上一个标签以来的每个 `feat` 或 `fix` 都会发布新版本，更新版本常量，并把说明写进 [`CHANGELOG.md`](CHANGELOG.md)。

## 许可证

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

这个插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中相同的约定和相同的共享库，并且设计为一起安装：没有成员占用另一个成员占用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。

| 成员 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 编辑并保存 tmux 配置后，它会自动重新加载，无需按键，也无需命令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 状态栏显示电池状态，从不阻塞状态栏渲染 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 状态栏显示 CPU 负载、温度和频率，从不阻塞渲染 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 状态栏显示磁盘用量，从不阻塞状态栏渲染 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 从屏幕上挑选 URL、路径、哈希或任意其他词元，并输入到光标处，全部用纯 shell 实现 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在弹出窗口中的 fzf 选择器里切换、关闭、重命名或创建 tmux 会话、窗口和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 状态栏中显示活动窗格的 git 分支、改动和托管平台计数，且不阻塞渲染 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 状态栏中显示 NVIDIA、AMD、Intel 和 Apple GPU 的负载、温度、频率、功耗和显存 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 状态栏中显示当前的 Kubernetes 上下文和命名空间，不依赖 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在弹出窗口或新窗口中启动任意 TUI 应用，从当前窗格的目录开始，每个应用可配置一个按键 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 将任意窗格保存到文件：实时日志、完整回滚缓冲区或一次性截图 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 状态栏显示正在播放的曲目，从不阻塞状态栏渲染 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 状态栏显示网络吞吐量，从不阻塞渲染 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和窗口管理按键，适配 tmux 版本，兼容 vim，每个 prefix 按键都可禁用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 保存 tmux 的所有会话、窗口和窗格，按定时器自动保存，并在重启后全部恢复 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起点：共享库、bats 测试框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟计时器，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标在 tmux 状态栏上拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 将鼠标滚轮交给能自行滚动的应用，其他情况下进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | **本插件**，按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：八种布局，包括 BSP dwindle 和 spiral，并支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 状态栏中的本地时钟和世界时钟，按一天中的时段着色，并提供倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在后台从 wttr.in 获取天气并显示在状态栏，状态栏无需等待 |

<!-- family:end -->
