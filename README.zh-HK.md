<div align="center">

# tmux-sensible-revamped

<strong>按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; 繁體中文（香港）

[![Tests](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#功能">功能</a> &nbsp;|&nbsp;
  <a href="#系統要求">系統要求</a> &nbsp;|&nbsp;
  <a href="#安裝">安裝</a> &nbsp;|&nbsp;
  <a href="#設定">設定</a> &nbsp;|&nbsp;
  <a href="#快捷鍵">快捷鍵</a> &nbsp;|&nbsp;
  <a href="#運作原理">運作原理</a>
</p>

</div>

**22** 個 tmux 選項，只在仍為 tmux 預設值時才設定。**11** 個終端機功能項目，每個只附加一次。每個選項只在具備它的 tmux 版本上套用，範圍由 **1.9** 起。

---

## 功能

本插件替你完成大部分 tmux 用戶最終都會親手寫的預設設定：去除 ESC 延遲、加大回捲緩衝區、視窗由 1 開始編號、啟用真彩色，以及把複製內容送到系統剪貼簿。每項設定在套用前都會檢查正在運行的 tmux 版本和外層終端機。你的 tmux 沒有的選項會被略過。

| 範疇 | 設定 | 最低 tmux 版本 |
|:-----|:---------|:-------------|
| 延遲與焦點 | `escape-time 10`、`focus-events on` | 1.9 |
| 終端機類型 | 若有真彩色且有對應的 terminfo，`default-terminal` 設為 `tmux-direct`；否則若有 `tmux-256color` 的 terminfo 便使用它；再否則使用 `screen-256color`。目前值為 `screen` 或 `screen-256color` 時視為未設定 | 任何 |
| 真彩色 | 3.2 或以後使用終端機功能 `RGB`，之前使用 `Tc` 覆寫。當 `COLORTERM` 為 `truecolor` 或 `24bit`，或 `COLORTERM` 為空而 terminfo 報告 `RGB` 或 `Tc` 時啟用。`TERM` 為巢狀的 `screen` 或 `tmux` 時一律不啟用 | 任何 |
| 底線 | 透過 `Smulx` 和 `Setulc` 覆寫實現波浪底線和彩色底線 | 3.0 |
| 剪貼簿與穿透 | `set-clipboard on`，3.3 上為 `allow-passthrough on`，3.4 或以後為 `all`，以及終端機功能 `clipboard`、`ccolour`、`cstyle`、`focus` 和 `title` | 功能需要 3.2 |
| 舊版 tmux 的跳脫序列 | OSC 52 的 `Ms` 覆寫，以及游標形狀的 `Ss` 和 `Se` 覆寫，只用於已知支援的終端機 | 只限 3.2 以下 |
| 圖形 | 為支援的終端機啟用 `sixel` 和 `hyperlinks` 終端機功能 | 3.4 |
| 擴展按鍵 | 為支援 CSI u 的終端機設定 `extended-keys on` 和 `extkeys` 功能，3.5 或以後設定 `extended-keys-format csi-u` | 3.2 |
| 回捲與狀態列 | `history-limit 50000`、`display-time 4000`、`status-interval 5`、`repeat-time 1000`、`display-panes-time 2000`、`set-titles on` | 任何 |
| 視窗與窗格 | `base-index 1`、`pane-base-index 1`、`renumber-windows on`、`aggressive-resize on` | 第二項需要 1.6，第三項需要 1.7 |
| 複製模式 | `$EDITOR` 或 `$VISUAL` 含有 `vi` 時為 `mode-keys vi`，否則為 `emacs`。`word-separators` 設為單一空格，因此按兩下會選取整個路徑或 URL | 任何 |

視為支援 CSI u 的終端機有 xterm、kitty、foot、Alacritty、Contour、Rio、st、Konsole、iTerm2、WezTerm、Ghostty 和 mintty，根據 `TERM` 和 `TERM_PROGRAM` 判斷。

## 系統要求

| 工具 | 版本 | 備註 |
|:-----|:--------|:------|
| tmux | 1.9 或以上 | 比正在運行的 tmux 更新的選項會被略過 |
| bash | 3.2 或以上 | 可使用 macOS 的 `/bin/bash` |
| 剪貼簿工具 | 可選 | `wl-copy`、`termux-clipboard-set`、`pbcopy`、`xclip`、`xsel` 或 `clip.exe`。沒有時透過 OSC 52 複製 |

CI 在 Ubuntu LTS 的 x86_64 和 arm64 上使用 GNU 和 uutils coreutils 執行測試，在 macOS 的 Apple Silicon 和 Intel 上使用系統工具、GNU 工具和 uutils 執行測試。

## 安裝

使用 [TPM](https://github.com/tmux-plugins/tpm) 時，把以下這行加入 `~/.tmux.conf`，然後按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-sensible-revamped'
```

TPM 會在讀完其餘設定後才載入插件，所以這行放在哪裏都可以。

不使用 TPM 時，複製儲存庫並在設定中執行入口腳本：

```bash
git clone https://github.com/tmux-revamped/tmux-sensible-revamped ~/.tmux/plugins/tmux-sensible-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-sensible-revamped/sensible-revamped.tmux
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

## 設定

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

### 內部狀態

此選項由插件自行管理，請勿設定。

| 選項 | 保存內容 |
|:-------|:------|
| `@sensible_revamped_resize_saved` | 有控制模式用戶端連接期間保存的全域 `aggressive-resize` 值。最後一個控制模式用戶端離開時還原並刪除 |

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

## 運作原理

[`sensible-revamped.tmux`](sensible-revamped.tmux) 在載入時執行一次 [`src/sensible.sh`](src/sensible.sh)。該腳本讀取 tmux 版本、作業系統、`TERM`、`TERM_PROGRAM` 和 `COLORTERM`，然後透過以下三種保護之一寫入每項設定：

| 保護 | 規則 |
|:------|:-----|
| 檢查預設值的寫入 | 只在選項為空或等於 tmux 預設值時寫入 |
| 只附加一次 | `terminal-overrides` 或 `terminal-features` 的項目只在缺少時加入，因此重新載入不會令清單變長 |
| 空閒鍵檢查 | 只在 `tmux list-keys` 顯示該鍵沒有綁定時才綁定便捷鍵 |

在 tmux 3.0 或以後，`client-attached` 和 `client-detached` 鉤子會以 `--resize-sync` 呼叫該腳本。只要有 iTerm2 控制模式用戶端連接，鉤子便保存全域 `aggressive-resize` 的值並將其關閉，因為開啟時控制模式會出錯。最後一個控制模式用戶端離開後，還原保存的值。普通用戶端連接不會改變任何東西。

判斷邏輯以純函數形式放在 [`src/lib/sensible/sensible.sh`](src/lib/sensible/sensible.sh) 中。設定 `SENSIBLE_DRY_RUN` 後，套用程序會列印每條 tmux 指令而不執行，測試正是藉此覆蓋各版本組合。

## 開發

| 指令 | 執行內容 |
|:--------|:-------------|
| `make test` | bats 測試套件 |
| `make lint` | 對所有 shell 檔案執行 warning 級別的 shellcheck |
| `make coverage` | kcov 行覆蓋率，下限 95%，只限 Linux |
| [`family/bin/audit`](family/bin/audit) | 按系列約定檢查本儲存庫 |

## 授權

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 系列

本插件是 tmux-revamped 系列的成員之一。每個成員都附有 [`FAMILY.md`](FAMILY.md) 中的同一份約定、`family/` 下的同一套工具和同一個共用程式庫，並由校驗和清單保持逐位元組一致。這些成員按一併安裝而設計：一個成員佔用的按鍵或 tmux 選項，不會被另一個成員佔用。

在一個成員中發現的缺陷，要在所有成員中排查後才算修正完成。這項責任寫在約定之中而非依賴記憶，`family/bin/sweep` 就是履行它的方法。

| 成員 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 編輯並儲存 tmux 設定後自動重新載入，毋須按鍵或指令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在狀態列顯示電池狀態，不阻塞狀態列繪製 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在狀態列顯示 CPU 負載、溫度和頻率，不阻塞繪製 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在狀態列顯示磁碟用量，不阻塞狀態列繪製 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 從螢幕上選取 URL、路徑、雜湊值或其他文字並輸入到游標位置，純 shell 實作 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在彈出視窗的 fzf 選擇器中切換、關閉、重新命名或建立 tmux 工作階段、視窗和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在狀態列顯示當前窗格的 git 分支、變更和託管平台計數，不阻塞狀態列 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在狀態列顯示 NVIDIA、AMD、Intel 和 Apple GPU 的負載、溫度、時脈、功耗和記憶體 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在狀態列顯示當前 Kubernetes 上下文和命名空間，直接解析 kubeconfig，毋須 kubectl |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 以當前窗格的目錄，在彈出視窗或新視窗中啟動任何 TUI 應用程式 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 將任何窗格儲存到檔案：即時記錄、完整回捲緩衝區或一次性截圖 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在狀態列顯示正在播放的音樂，不阻塞狀態列繪製 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在狀態列顯示網絡吞吐量，不阻塞繪製 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | 標準的 tmux 窗格和視窗管理快捷鍵，區分版本、兼容 vim，並且全部可以設定 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 儲存所有 tmux 工作階段、視窗和窗格，按計時器自動儲存，重新開機後全部還原 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架、CI 和系列工具 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | 狀態列中的番茄鐘，所有狀態都存放在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在背景取樣 RAM、交換區和記憶體壓力並顯示在狀態列，繪製毋須等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠沿狀態列拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 把滑鼠滾輪交給自行捲動的應用程式，其他情況則進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | **本插件**，按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

### 檢查安裝

所有成員都在磁碟上時，一條指令即可報告它們之間的衝突：

```sh
family/bin/doctor --live
```

它讀取每個成員和正在運行的 tmux 伺服器，報告重複的按鍵、重複的狀態佔位符、不符合命名規則的選項，以及約定版本落後的成員。

<!-- family:end -->
