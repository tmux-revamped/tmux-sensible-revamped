<div align="center">

# tmux-sensible-revamped

<strong>按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; 繁體中文（香港）

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-sensible-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-sensible-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-sensible-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-sensible-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-sensible-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-sensible-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速開始"><strong>快速開始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#設定的內容">設定的內容</a> &nbsp;|&nbsp;
  <a href="#快捷鍵">快捷鍵</a> &nbsp;|&nbsp;
  <a href="#運作原理">運作原理</a> &nbsp;|&nbsp;
  <a href="#畫面">畫面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="sensible-revamped 用一個指令調高 tmux 的預設值，再用 prefix C-n 和 C-p 切換視窗" width="800">
</p>

```console
$ tmux show-option -gv history-limit
2000
$ sensible-revamped apply
$ tmux show-option -gv history-limit
50000
```

本插件替你完成大部分 tmux 用戶最終都會親手寫的預設設定：去除 ESC 延遲、加大回捲緩衝區、視窗由 1 開始編號、啟用真彩色，以及把複製內容送到系統剪貼簿。每項設定在套用前都會檢查正在運行的 tmux 版本和外層終端機。你的 tmux 沒有的選項會被略過。

---

## 快速開始

### 前提條件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或以上 | 系列的最低版本；正在運行的 tmux 沒有的選項會被略過 |
| 剪貼簿工具 | 可選 | `wl-copy`、`termux-clipboard-set`、`pbcopy`、`xclip`、`xsel` 或 `clip.exe`；沒有時複製經由終端機的 OSC 52 |
| `infocmp` | 可選 | 為 `default-terminal` 選擇 `tmux-direct` 或 `tmux-256color`；沒有時取 `screen-256color` |
| gum | 可選 | `sensible-revamped` 的選單、表格和顏色；沒有它，所有命令都輸出純文字 |

### 安裝

```tmux
set -g @plugin 'tmux-revamped/tmux-sensible-revamped'
```

然後按 `prefix + I`。不使用 TPM 時，複製儲存庫，並在 `~/.tmux.conf` 中執行它的入口腳本：

```bash
git clone https://github.com/tmux-revamped/tmux-sensible-revamped ~/.tmux/plugins/tmux-sensible-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-sensible-revamped/sensible-revamped.tmux
```

在複製的目錄中執行 `make install`，亦會把 `sensible-revamped` 放入 `~/.local/bin`，並把它的 man 手冊和自動完成放在 `~/.local/share` 下。

### 驗證

```bash
~/.tmux/plugins/tmux-sensible-revamped/bin/sensible-revamped doctor
```

## 用法

毋須呼叫任何東西。重新載入 tmux 後檢查其中一個值：

```bash
tmux show-option -gv history-limit
```

```text
50000
```

如想為表中某個選項使用自己的值，在 `~/.tmux.conf` 中設定即可。插件寫入前會把每個選項與 tmux 預設值比較，不同的值保持不變。你設定的值如剛好等於 tmux 預設值，便無法與未設定區分，插件會把它取代。

| 命令 | 作用 |
|:--------|:-------------|
| `sensible-revamped apply` | 立即設定預設值並綁定按鍵；插件載入時入口點會執行它 |
| `sensible-revamped list` | 列出 `apply` 會執行的每個 tmux 指令，不作任何修改；`--json` 輸出一個物件 |
| `sensible-revamped resize-sync` | 有控制模式用戶端連接時關閉 `aggressive-resize`，之後再還原；由用戶端鉤子執行 |
| `sensible-revamped doctor` | 每個依賴一行，包括剪貼簿工具和保持不變的按鍵 |
| `sensible-revamped version` | 版本，然後是 tmux 版本 |
| `sensible-revamped help` | 說明頁；`man sensible-revamped` 記錄相同的命令和設定 |
| `sensible-revamped` | 在終端機上顯示選單 |

| 選項 | 預設值 | 意思 |
|:-------|:--------|:--------|
| `@sensible_revamped_keys` | `on` | 設為 `off` 時略過重新載入、上一個視窗、`C-p` 和 `C-n` 的綁定。前綴鍵設定和複製模式的綁定仍會套用 |
| `@sensible_revamped_reload_key` | 空 | 重新載入設定的前綴鍵。設定之前不綁定 |
| `@sensible_revamped_last_window_key` | 空 | 切換到上一個視窗的前綴鍵。設定之前不綁定 |

```tmux
set -g @sensible_revamped_reload_key 'R'
set -g @sensible_revamped_last_window_key 'a'
```

重新載入鍵會載入 `$XDG_CONFIG_HOME/tmux/tmux.conf`、`~/.config/tmux/tmux.conf` 和 `~/.tmux.conf` 中第一個存在的檔案，然後顯示 `tmux-sensible-revamped: reloaded`。

每個選項亦可以用帶連字號的命令選項（例如 `--reload-key R`）和環境變數（例如 `SENSIBLE_REVAMPED_RELOAD_KEY`）設定；命令列優先於環境變數，環境變數優先於 tmux 選項。空的 tmux 選項表示使用預設值。`doctor` 會指出數值無法識別的設定。`@sensible_revamped_resize_saved` 由插件自己寫入。

<a id="設定的內容"></a>

## 設定的內容

| 範疇 | 設定 | 最低 tmux 版本 |
|:-----|:---------|:-------------|
| 延遲與焦點 | `escape-time 10`、`focus-events on` | 1.9 |
| 終端機類型 | 若有真彩色且有對應的 terminfo，`default-terminal` 設為 `tmux-direct`；否則若有 `tmux-256color` 的 terminfo 便使用它；再否則使用 `screen-256color`。目前值為 `screen` 或 `screen-256color` 時視為未設定 | 任何 |
| 真彩色 | 3.2 或以後使用終端機功能 `RGB`，之前使用 `Tc` 覆寫。當 `COLORTERM` 為 `truecolor` 或 `24bit`，或 `COLORTERM` 為空而 terminfo 報告 `RGB` 或 `Tc` 時啟用。`TERM` 為巢狀的 `screen` 或 `tmux` 時一律不啟用 | 任何 |
| 底線 | 透過 `Smulx` 和 `Setulc` 覆寫實現波浪底線和彩色底線 | 3.0 |
| 剪貼簿與穿透 | `set-clipboard on`，3.3 上為 `allow-passthrough on`，3.4 或以後為 `all`，以及終端機功能 `clipboard`、`ccolour`、`cstyle`、`focus` 和 `title` | 功能需要 3.2 |
| 舊版 tmux 的跳脫序列 | OSC 52 的 `Ms` 覆寫，以及游標形狀的 `Ss` 和 `Se` 覆寫，只用於已知支援的終端機 | 只限 3.2 以下 |
| 圖形 | 為支援的終端機啟用 `sixel` 和 `hyperlinks` 終端機功能 | 3.4 |
| 擴展按鍵 | 無論伺服器以哪個 `TERM` 啟動，都設定 `extended-keys on`，3.5 或以後設定 `extended-keys-format csi-u`：tmux 只向已知具備 `extkeys` 功能的終端機發送請求。`extkeys` 功能本身只為支援 CSI u 的終端機宣告 | 3.2 |
| 回捲與狀態列 | `history-limit 50000`、`display-time 4000`、`status-interval 5`、`repeat-time 1000`、`display-panes-time 2000`、`set-titles on` | 任何 |
| 視窗與窗格 | `base-index 1`、`pane-base-index 1`、`renumber-windows on`、`aggressive-resize on` | 第二項需要 1.6，第三項需要 1.7 |
| 複製模式 | `$EDITOR` 或 `$VISUAL` 含有 `vi` 時為 `mode-keys vi`，否則為 `emacs`。`word-separators` 設為單一空格，因此按兩下會選取整個路徑或 URL | 任何 |

視為支援 CSI u 的終端機有 xterm、kitty、foot、Alacritty、Contour、Rio、st、Konsole、iTerm2、WezTerm、Ghostty 和 mintty，根據 `TERM` 和 `TERM_PROGRAM` 判斷。

這裏的終端機是 tmux 伺服器啟動時所在的終端機：tmux 交給插件的是它自己的 `TERM` 和 `TERM_PROGRAM`，所以插件從 tmux 的全域環境讀取這兩個值。

<a id="快捷鍵"></a>

## 快捷鍵

| 按鍵 | 鍵表 | 動作 | 預設 |
|:----|:------|:-------|:--------|
| `C-p` | prefix | 上一個視窗 | 載入時該鍵空閒便綁定 |
| `C-n` | prefix | 下一個視窗 | 載入時該鍵空閒便綁定 |
| 你的前綴鍵 | prefix | `send-prefix` | 前綴鍵不是 `C-b` 時綁定，並解除 `C-b` |
| `@sensible_revamped_reload_key` | prefix | 重新載入設定 | 不綁定 |
| `@sensible_revamped_last_window_key` | prefix | 上一個視窗 | 不綁定 |
| `y`、`Enter`、`MouseDragEnd1Pane` | copy-mode-vi | 複製並離開複製模式 | 一律綁定 |
| `M-w`、`MouseDragEnd1Pane` | copy-mode | 複製並離開複製模式 | 一律綁定 |
| `v`、`C-v` | copy-mode-vi | 開始選取、切換矩形選取 | 一律綁定 |

插件載入時某個鍵沒有任何綁定，便視為空閒。之後載入的插件仍可綁定同一個鍵，`@sensible_revamped_keys 'off'` 正是為此而設。

複製模式的綁定會取代你為這些鍵設定的綁定。如要保留自己的綁定，請在 TPM 的 `run` 行之後綁定。tmux 2.4 或以後使用 `copy-pipe-and-cancel` 送到剪貼簿工具，沒有工具時使用 `copy-selection-and-cancel`。2.4 以下使用舊的 `vi-copy` 和 `emacs-copy` 鍵表。

剪貼簿工具按以下次序選擇：Wayland 下的 `wl-copy`、`termux-clipboard-set`、macOS 上的 `pbcopy`、X11 下先 `xclip` 後 `xsel`，以及 WSL 上的 `clip.exe`。`clip.exe` 排在 X11 工具之後，令 WSLg 工作階段保持 UTF-8 正確。在 macOS 上，如已安裝 `reattach-to-user-namespace`，`default-command` 會透過它啟動你的 shell。

<a id="運作原理"></a>

## 運作原理

[`sensible-revamped.tmux`](sensible-revamped.tmux) 在載入時執行一次 `bin/sensible-revamped apply`。它用三次 tmux 呼叫讀取 tmux 版本、可能修改的每個選項、按鍵表和終端機，再用第四次呼叫發送所有指令，每個指令都經過以下三種保護之一：

| 保護 | 規則 |
|:------|:-----|
| 檢查預設值的寫入 | 只在選項為空或等於 tmux 預設值時寫入 |
| 只附加一次 | `terminal-overrides` 或 `terminal-features` 的項目只在缺少時加入，因此重新載入不會令清單變長 |
| 空閒鍵檢查 | 只在 `tmux list-keys` 顯示該鍵沒有綁定時才綁定便捷鍵 |

在 tmux 3.0 或以後，`client-attached` 和 `client-detached` 鉤子會執行 `sensible-revamped resize-sync`。只要有 iTerm2 控制模式用戶端連接，鉤子便保存全域 `aggressive-resize` 的值並將其關閉，因為開啟時控制模式會出錯。最後一個控制模式用戶端離開後，還原保存的值。普通用戶端連接不會改變任何東西。

`sensible-revamped list` 列出 `apply` 會執行的每個指令而不作任何修改，可以用它查看插件在你的伺服器上會做甚麼。

<a id="畫面"></a>

## 畫面

<details>
<summary>所有畫面，在真實的 tmux 中用 <code>make screens</code> 錄製，每個按鍵顯示在狀態列上</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/defaults.png" alt="sensible-revamped：apply 調高 tmux 本身的預設值"><br><sub><code>apply</code> 調高 tmux 本身的預設值，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/next-window.png" alt="sensible-revamped：prefix C-n 切換到下一個視窗"><br><sub><code>prefix C-n</code> 切換到下一個視窗，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu.png" alt="sensible-revamped：選單"><br><sub>選單，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="sensible-revamped：doctor"><br><sub><code>doctor</code>，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/reload.png" alt="sensible-revamped：重新載入鍵再次載入設定"><br><sub>重新載入鍵再次載入設定，來自 <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/last-window.png" alt="sensible-revamped：返回上一個視窗的按鍵"><br><sub>返回上一個視窗的按鍵，來自 <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/copy.png" alt="sensible-revamped：在 vi 複製模式中用 v 選取"><br><sub>在 vi 複製模式中用 <code>v</code> 選取，來自 <code>keys.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/copied.png" alt="sensible-revamped：y 複製到剪貼簿工具"><br><sub><code>y</code> 複製到剪貼簿工具，來自 <code>keys.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/list.png" alt="sensible-revamped：list 列出每個指令"><br><sub><code>list</code> 列出每個指令，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="sensible-revamped：沒有 gum 的選單"><br><sub>沒有 gum 的選單，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="sensible-revamped：從選單執行 doctor"><br><sub>從選單執行 <code>doctor</code>，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="sensible-revamped：版本"><br><sub>版本，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="sensible-revamped：不明命令"><br><sub>不明命令，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/themes.png" alt="sensible-revamped：六種主題下的標題"><br><sub>六種主題下的標題，來自 <code>themes.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/help.png" alt="sensible-revamped：說明頁"><br><sub>說明頁，來自 <code>help.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="sensible-revamped：來自 SENSIBLE_REVAMPED_ACCENT 的強調色"><br><sub>來自 <code>SENSIBLE_REVAMPED_ACCENT</code> 的強調色，來自 <code>stills.tape</code></sub></td>
</tr>
</table>

</details>

## 可攜性

插件是 POSIX `sh`。CI 在下列每一行上執行全部測試。

| Shell | 狀態 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支援 |
| `bash` 3.2 和 5.x、系統內建的 `zsh` 和 Homebrew 的 `zsh` | 支援 |

| 系統 | 狀態 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用內建的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |

## 開發

| 指令 | 執行內容 |
|:--------|:-------------|
| `make fmt` | 對每個腳本執行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零警告 |
| `make test` | 在系統 `sh` 下執行 bats 測試 |
| `make test-all` | 在每個已安裝的 shell 下執行測試，macOS 上包括 bash 和 zsh 的兩種版本 |
| `make test-linux` | 在 Ubuntu 容器中執行測試 |
| `make coverage` | 在這部 Mac 和 Ubuntu 容器中執行 bashcov，合併後以 100% 為門檻 |
| `make screens` | 以 VHS 在 tmux 中從真實插件錄製上述畫面，在 macOS 上執行 |
| `make install` | 把指令、man 手冊和自動完成安裝到 `PREFIX` 下 |

在 macOS 上，執行 `brew bundle` 會根據 [`Brewfile`](Brewfile) 安裝這些目標用到的所有工具。

提交遵循 Conventional Commits 格式，直接進入 `main`。`main` 上的 `ci` 通過後，`release.yml` 會執行 semantic-release：自上一個標籤以來的每個 `feat` 或 `fix` 都會發佈新版本，更新版本常數，並把說明寫入 [`CHANGELOG.md`](CHANGELOG.md)。

## 授權

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

這個插件是 tmux-revamped 插件家族的一員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中相同的約定和相同的共用程式庫，並且設計為一起安裝：沒有成員佔用另一個成員佔用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在全部成員中排查後才算修正完成。

| 成員 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 編輯並儲存 tmux 設定後，它會自動重新載入，毋須按鍵，也毋須指令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 狀態列顯示電池狀態，從不阻塞狀態列繪製 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 狀態列顯示 CPU 負載、溫度及頻率，從不阻塞繪製 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 狀態列顯示磁碟用量，從不阻塞狀態列繪製 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 從畫面上揀選 URL、路徑、雜湊值或任何其他字詞，並輸入到游標位置，全部以純 shell 實現 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在彈出視窗的 fzf 選擇器中切換、關閉、重新命名或建立 tmux 工作階段、視窗和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 狀態列顯示當前窗格的 git 分支、改動和託管平台數目，而不會阻塞顯示 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 狀態列顯示 NVIDIA、AMD、Intel 及 Apple GPU 的負載、溫度、時脈、功耗及記憶體 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 狀態列顯示目前的 Kubernetes 上下文及命名空間，毋須 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在彈出視窗或新視窗中啟動任何 TUI 應用程式，從目前窗格的目錄開始，每個應用程式可設定一個按鍵 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 將任何窗格儲存到檔案：即時記錄、完整捲動緩衝區或一次性截圖 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 狀態列顯示正在播放的歌曲，從不阻塞狀態列的繪製 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 狀態列顯示網絡傳輸量，從不阻塞繪製 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和視窗管理按鍵，配合 tmux 版本，與 vim 相容，每個 prefix 按鍵都可停用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 儲存 tmux 的所有工作階段、視窗及窗格，按計時器自動儲存，並在重新開機後全部還原 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 狀態列中的番茄鐘計時器，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠在 tmux 狀態列上拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | **本插件**，按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

<!-- family:end -->
