<div align="center">

# tmux-sensible-revamped

<strong>按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; 简体中文 &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#功能">功能</a> &nbsp;|&nbsp;
  <a href="#环境要求">环境要求</a> &nbsp;|&nbsp;
  <a href="#安装">安装</a> &nbsp;|&nbsp;
  <a href="#配置">配置</a> &nbsp;|&nbsp;
  <a href="#快捷键">快捷键</a> &nbsp;|&nbsp;
  <a href="#工作原理">工作原理</a>
</p>

</div>

**22** 个 tmux 选项，只在仍为 tmux 默认值时才设置。**11** 个终端能力条目，每个只追加一次。每个选项只在具备它的 tmux 版本上应用，范围从 **1.9** 起。

---

## 功能

本插件替你完成大多数 tmux 用户最终都会手写的默认设置：去掉 ESC 延迟、加大回滚缓冲区、窗口从 1 开始编号、启用真彩色，以及把复制内容送到系统剪贴板。每项设置在应用前都会检查正在运行的 tmux 版本和外层终端。你的 tmux 没有的选项会被跳过。

| 方面 | 设置 | 最低 tmux 版本 |
|:-----|:---------|:-------------|
| 延迟与焦点 | `escape-time 10`、`focus-events on` | 1.9 |
| 终端类型 | 若有真彩色且存在对应 terminfo，`default-terminal` 设为 `tmux-direct`；否则若存在 `tmux-256color` 的 terminfo 则用它；再否则用 `screen-256color`。当前值为 `screen` 或 `screen-256color` 时视为未设置 | 任意 |
| 真彩色 | 3.2 及以后使用终端特性 `RGB`，之前使用 `Tc` 覆盖。当 `COLORTERM` 为 `truecolor` 或 `24bit`，或 `COLORTERM` 为空且 terminfo 报告 `RGB` 或 `Tc` 时启用。`TERM` 为嵌套的 `screen` 或 `tmux` 时从不启用 | 任意 |
| 下划线 | 通过 `Smulx` 和 `Setulc` 覆盖实现波浪下划线和彩色下划线 | 3.0 |
| 剪贴板与透传 | `set-clipboard on`，3.3 上为 `allow-passthrough on`，3.4 及以后为 `all`，以及终端特性 `clipboard`、`ccolour`、`cstyle`、`focus` 和 `title` | 特性需要 3.2 |
| 旧版 tmux 的转义序列 | OSC 52 的 `Ms` 覆盖，以及光标形状的 `Ss` 和 `Se` 覆盖，仅用于已知支持的终端 | 仅 3.2 以下 |
| 图形 | 为支持的终端启用 `sixel` 和 `hyperlinks` 终端特性 | 3.4 |
| 扩展按键 | 为支持 CSI u 的终端设置 `extended-keys on` 和 `extkeys` 特性，3.5 及以后设置 `extended-keys-format csi-u` | 3.2 |
| 回滚与状态栏 | `history-limit 50000`、`display-time 4000`、`status-interval 5`、`repeat-time 1000`、`display-panes-time 2000`、`set-titles on` | 任意 |
| 窗口与窗格 | `base-index 1`、`pane-base-index 1`、`renumber-windows on`、`aggressive-resize on` | 第二项需要 1.6，第三项需要 1.7 |
| 复制模式 | `$EDITOR` 或 `$VISUAL` 含有 `vi` 时为 `mode-keys vi`，否则为 `emacs`。`word-separators` 设为单个空格，因此双击会选中整个路径或 URL | 任意 |

视为支持 CSI u 的终端有 xterm、kitty、foot、Alacritty、Contour、Rio、st、Konsole、iTerm2、WezTerm、Ghostty 和 mintty，根据 `TERM` 和 `TERM_PROGRAM` 判断。

## 环境要求

| 工具 | 版本 | 说明 |
|:-----|:--------|:------|
| tmux | 1.9 或更高 | 比正在运行的 tmux 更新的选项会被跳过 |
| bash | 3.2 或更高 | 可用 macOS 的 `/bin/bash` |
| 剪贴板工具 | 可选 | `wl-copy`、`termux-clipboard-set`、`pbcopy`、`xclip`、`xsel` 或 `clip.exe`。没有时通过 OSC 52 复制 |

CI 在 Ubuntu LTS 的 x86_64 和 arm64 上使用 GNU 和 uutils coreutils 运行测试，在 macOS 的 Apple Silicon 和 Intel 上使用系统工具、GNU 工具和 uutils 运行测试。

## 安装

使用 [TPM](https://github.com/tmux-plugins/tpm) 时，把下面这行加入 `~/.tmux.conf`，然后按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-sensible-revamped'
```

TPM 会在读完其余配置之后加载插件，所以这行放在哪里都可以。

不使用 TPM 时，克隆仓库并在配置中运行入口脚本：

```bash
git clone https://github.com/tmux-revamped/tmux-sensible-revamped ~/.tmux/plugins/tmux-sensible-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-sensible-revamped/sensible-revamped.tmux
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

## 配置

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

### 内部状态

该选项由插件自行管理，请勿设置。

| 选项 | 保存内容 |
|:-------|:------|
| `@sensible_revamped_resize_saved` | 有控制模式客户端连接期间保存的全局 `aggressive-resize` 值。最后一个控制模式客户端离开时恢复并删除 |

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

## 工作原理

[`sensible-revamped.tmux`](sensible-revamped.tmux) 在加载时运行一次 [`src/sensible.sh`](src/sensible.sh)。该脚本读取 tmux 版本、操作系统、`TERM`、`TERM_PROGRAM` 和 `COLORTERM`，然后通过以下三种保护之一写入每项设置：

| 保护 | 规则 |
|:------|:-----|
| 检查默认值的写入 | 只在选项为空或等于 tmux 默认值时写入 |
| 只追加一次 | `terminal-overrides` 或 `terminal-features` 的条目只在缺失时添加，因此重新加载不会让列表变长 |
| 空闲键检查 | 只在 `tmux list-keys` 显示该键没有绑定时才绑定便捷键 |

在 tmux 3.0 及以后，`client-attached` 和 `client-detached` 钩子会以 `--resize-sync` 调用该脚本。只要有 iTerm2 控制模式客户端连接，钩子就保存全局 `aggressive-resize` 的值并将其关闭，因为开启时控制模式会出问题。最后一个控制模式客户端离开后，恢复保存的值。普通客户端连接不会改变任何东西。

判断逻辑以纯函数形式放在 [`src/lib/sensible/sensible.sh`](src/lib/sensible/sensible.sh) 中。设置 `SENSIBLE_DRY_RUN` 后，应用程序会打印每条 tmux 命令而不执行，测试正是借此覆盖各版本组合。

## 开发

| 命令 | 运行内容 |
|:--------|:-------------|
| `make test` | bats 测试套件 |
| `make lint` | 对所有 shell 文件运行 warning 级别的 shellcheck |
| `make coverage` | kcov 行覆盖率，下限 95%，仅 Linux |
| [`family/bin/audit`](family/bin/audit) | 按系列约定检查本仓库 |

## 许可证

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 系列

本插件是 tmux-revamped 系列的成员之一。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中的同一份约定、`family/` 下的同一套工具和同一个共享库，并由校验和清单保持逐字节一致。这些成员按一起安装来设计：一个成员占用的按键或 tmux 选项，不会被另一个成员占用。

在一个成员中发现的缺陷，要在所有成员中排查之后才算修复完成。这项义务写在约定里而不是靠记忆，`family/bin/sweep` 就是履行它的方式。

| 成员 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 编辑并保存 tmux 配置后自动重新加载，无需按键或命令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在状态栏显示电池状态，不阻塞状态栏渲染 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在状态栏显示 CPU 负载、温度和频率，不阻塞渲染 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在状态栏显示磁盘用量，不阻塞状态栏渲染 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 从屏幕上选取 URL、路径、哈希或其他文本并输入到光标处，纯 shell 实现 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在弹出窗口的 fzf 选择器中切换、关闭、重命名或创建 tmux 会话、窗口和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在状态栏显示当前窗格的 git 分支、改动和托管平台计数，不阻塞状态栏 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在状态栏显示 NVIDIA、AMD、Intel 和 Apple GPU 的负载、温度、频率、功耗和显存 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在状态栏显示当前 Kubernetes 上下文和命名空间，直接解析 kubeconfig，无需 kubectl |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 以当前窗格的目录，在弹出窗口或新窗口中启动任意 TUI 应用 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 将任意窗格保存到文件：实时记录、完整回滚缓冲区或一次性截图 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在状态栏显示正在播放的音乐，不阻塞状态栏渲染 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在状态栏显示网络吞吐量，不阻塞渲染 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | 标准的 tmux 窗格和窗口管理快捷键，区分版本、兼容 vim，并且全部可配置 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 保存所有 tmux 会话、窗口和窗格，按定时器自动保存，重启后全部恢复 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起点：共享库、bats 测试框架、CI 和系列工具 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | 状态栏中的番茄钟，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在后台采样 RAM、交换区和内存压力并显示在状态栏，渲染无需等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标沿状态栏拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 把鼠标滚轮交给自行滚动的应用，其他情况进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | **本插件**，按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：八种布局，包括 BSP dwindle 和 spiral，并支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 状态栏中的本地时钟和世界时钟，按一天中的时段着色，并提供倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在后台从 wttr.in 获取天气并显示在状态栏，状态栏无需等待 |

### 检查安装

所有成员都在磁盘上时，一条命令即可报告它们之间的冲突：

```sh
family/bin/doctor --live
```

它读取每个成员和正在运行的 tmux 服务器，报告重复的按键、重复的状态占位符、不符合命名规则的选项，以及约定版本落后的成员。

<!-- family:end -->
