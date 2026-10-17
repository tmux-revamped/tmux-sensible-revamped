<div align="center">

# tmux-sensible-revamped

<strong>tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#機能">機能</a> &nbsp;|&nbsp;
  <a href="#動作要件">動作要件</a> &nbsp;|&nbsp;
  <a href="#インストール">インストール</a> &nbsp;|&nbsp;
  <a href="#設定">設定</a> &nbsp;|&nbsp;
  <a href="#キーバインド">キーバインド</a> &nbsp;|&nbsp;
  <a href="#仕組み">仕組み</a>
</p>

</div>

tmuxの既定値のままのときだけ設定するオプションが**22**個。それぞれ一度だけ追加する端末機能の項目が**11**個。すべてのオプションは、それを持つtmuxのバージョンに限って適用され、対象は**1.9**以降です。

---

## 機能

多くのtmuxユーザーが手で書くことになる初期設定を、このプラグインが行います。ESCの遅延をなくし、スクロールバックを大きくし、ウィンドウ番号を1から始め、truecolorを有効にし、コピーをシステムのクリップボードに送ります。各設定は、実行中のtmuxのバージョンと外側の端末を確認してから適用します。お使いのtmuxにないオプションは飛ばします。

| 分野 | 設定 | 必要なtmux |
|:-----|:---------|:-------------|
| 遅延とフォーカス | `escape-time 10`、`focus-events on` | 1.9 |
| 端末の種類 | `default-terminal`は、truecolorとそのterminfoがあれば`tmux-direct`、`tmux-256color`のterminfoがあればそれ、なければ`screen-256color`になります。現在値が`screen`か`screen-256color`なら未設定とみなします | すべて |
| truecolor | 3.2以降は端末機能`RGB`、それより前は`Tc`の上書きです。`COLORTERM`が`truecolor`か`24bit`のとき、または`COLORTERM`が空でterminfoが`RGB`か`Tc`を報告するときに有効にします。`TERM`が入れ子の`screen`や`tmux`なら有効にしません | すべて |
| 下線 | `Smulx`と`Setulc`の上書きによる波線と色付き下線 | 3.0 |
| クリップボードとパススルー | `set-clipboard on`、3.3では`allow-passthrough on`、3.4以降では`all`、そして端末機能`clipboard`、`ccolour`、`cstyle`、`focus`、`title` | 機能は3.2 |
| 古いtmux向けのエスケープ | OSC 52の`Ms`上書きと、カーソル形状の`Ss`と`Se`上書き。対応が分かっている端末に限ります | 3.2未満のみ |
| グラフィックス | 対応する端末向けの端末機能`sixel`と`hyperlinks` | 3.4 |
| 拡張キー | CSI uを話す端末向けの`extended-keys on`と機能`extkeys`、3.5以降では`extended-keys-format csi-u` | 3.2 |
| スクロールバックとステータス | `history-limit 50000`、`display-time 4000`、`status-interval 5`、`repeat-time 1000`、`display-panes-time 2000`、`set-titles on` | すべて |
| ウィンドウとペイン | `base-index 1`、`pane-base-index 1`、`renumber-windows on`、`aggressive-resize on` | 2つ目は1.6、3つ目は1.7 |
| コピーモード | `$EDITOR`か`$VISUAL`に`vi`が含まれれば`mode-keys vi`、そうでなければ`emacs`。`word-separators`を空白1文字にするので、ダブルクリックでパスやURL全体を選択できます | すべて |

CSI u対応とみなす端末は、xterm、kitty、foot、Alacritty、Contour、Rio、st、Konsole、iTerm2、WezTerm、Ghostty、minttyで、`TERM`と`TERM_PROGRAM`で判定します。

## 動作要件

| ツール | バージョン | 備考 |
|:-----|:--------|:------|
| tmux | 1.9以降 | 実行中のtmuxより新しいオプションは飛ばします |
| bash | 3.2以降 | macOSの`/bin/bash`で動きます |
| クリップボードのツール | 任意 | `wl-copy`、`termux-clipboard-set`、`pbcopy`、`xclip`、`xsel`、`clip.exe`のいずれか。なければOSC 52でコピーします |

CIは、Ubuntu LTSのx86_64とarm64でGNUとuutilsのcoreutilsを使い、macOSのApple SiliconとIntelでシステムのツール、GNUのツール、uutilsを使ってテストを実行します。

## インストール

[TPM](https://github.com/tmux-plugins/tpm)を使う場合は、次の行を`~/.tmux.conf`に追加して`prefix + I`を押します。

```tmux
set -g @plugin 'tmux-revamped/tmux-sensible-revamped'
```

TPMは設定の残りを読んだ後にプラグインを読み込むので、この行の位置は問いません。

TPMを使わない場合は、リポジトリをクローンし、設定からエントリーポイントを実行します。

```bash
git clone https://github.com/tmux-revamped/tmux-sensible-revamped ~/.tmux/plugins/tmux-sensible-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-sensible-revamped/sensible-revamped.tmux
```

## 使い方

呼び出すものはありません。tmuxを再読み込みして、値の1つを確認します。

```bash
tmux show-option -gv history-limit
```

```text
50000
```

表のオプションに自分の値を使いたい場合は、`~/.tmux.conf`で設定します。プラグインは書き込む前に各オプションをtmuxの既定値と比べ、異なる値には触れません。tmuxの既定値と同じ値を設定した場合は未設定と区別できないため、プラグインが置き換えます。

## 設定

| オプション | 既定値 | 意味 |
|:-------|:--------|:--------|
| `@sensible_revamped_keys` | `on` | `off`にすると、再読み込み、直前のウィンドウ、`C-p`、`C-n`のキーを設定しません。プレフィックスの設定とコピーモードのキーは適用されます |
| `@sensible_revamped_reload_key` | 空 | 設定を読み直すプレフィックスキー。設定するまで割り当てません |
| `@sensible_revamped_last_window_key` | 空 | 直前のウィンドウに切り替えるプレフィックスキー。設定するまで割り当てません |

```tmux
set -g @sensible_revamped_reload_key 'R'
set -g @sensible_revamped_last_window_key 'a'
```

再読み込みのキーは、`$XDG_CONFIG_HOME/tmux/tmux.conf`、`~/.config/tmux/tmux.conf`、`~/.tmux.conf`のうち最初に存在するものを読み込み、`tmux-sensible-revamped: reloaded`と表示します。

### 内部状態

このオプションはプラグインが管理します。設定しないでください。

| オプション | 保持する内容 |
|:-------|:------|
| `@sensible_revamped_resize_saved` | コントロールモードのクライアントが接続している間に保存した、グローバルの`aggressive-resize`の値。最後のコントロールモードのクライアントが離れると元に戻して削除します |

## キーバインド

| キー | テーブル | 動作 | 既定 |
|:----|:------|:-------|:--------|
| `C-p` | prefix | 前のウィンドウ | 読み込み時にキーが空いていれば割り当て |
| `C-n` | prefix | 次のウィンドウ | 読み込み時にキーが空いていれば割り当て |
| 自分のプレフィックス | prefix | `send-prefix` | プレフィックスが`C-b`でなければ割り当て、`C-b`は解除 |
| `@sensible_revamped_reload_key` | prefix | 設定の読み直し | 割り当てなし |
| `@sensible_revamped_last_window_key` | prefix | 直前のウィンドウ | 割り当てなし |
| `y`、`Enter`、`MouseDragEnd1Pane` | copy-mode-vi | コピーしてコピーモードを抜ける | 常に割り当て |
| `M-w`、`MouseDragEnd1Pane` | copy-mode | コピーしてコピーモードを抜ける | 常に割り当て |
| `v`、`C-v` | copy-mode-vi | 選択開始、矩形選択の切り替え | 常に割り当て |

プラグインの読み込み時点でそのキーの割り当てがなければ、空いているとみなします。後から読み込まれたプラグインは同じキーを割り当てられるので、そのために`@sensible_revamped_keys 'off'`があります。

コピーモードのキーは、それらのキーに対する自分の割り当てを置き換えます。自分の割り当てを残すには、TPMの`run`行の後で割り当ててください。tmux 2.4以降はクリップボードのツールへの`copy-pipe-and-cancel`、ツールがなければ`copy-selection-and-cancel`を使います。2.4未満では古い`vi-copy`と`emacs-copy`のテーブルを使います。

クリップボードのツールは次の順で選びます。Waylandでは`wl-copy`、次に`termux-clipboard-set`、macOSでは`pbcopy`、X11では`xclip`、次に`xsel`、WSLでは`clip.exe`です。WSLgのセッションでUTF-8を正しく扱えるよう、`clip.exe`はX11のツールより後にしています。macOSでは、`reattach-to-user-namespace`がインストールされていれば、`default-command`がそれを通してシェルを起動します。

## 仕組み

[`sensible-revamped.tmux`](sensible-revamped.tmux)は読み込み時に[`src/sensible.sh`](src/sensible.sh)を一度実行します。このスクリプトはtmuxのバージョン、OS、`TERM`、`TERM_PROGRAM`、`COLORTERM`を読み取り、各設定を次の3つのガードのいずれかを通して書き込みます。

| ガード | 規則 |
|:------|:-----|
| 既定値を確認するセッター | オプションが空か、tmuxの既定値と等しいときだけ書き込みます |
| 一度だけ追加 | `terminal-overrides`や`terminal-features`の項目は、ないときだけ追加するので、再読み込みで一覧が伸びません |
| 空きキーの確認 | `tmux list-keys`にそのキーの割り当てがないときだけ、便利キーを割り当てます |

tmux 3.0以降では、`client-attached`と`client-detached`のフックがこのスクリプトを`--resize-sync`付きで呼びます。iTerm2のコントロールモードのクライアントが1つでも接続している間、フックはグローバルの`aggressive-resize`の値を保存してオフにします。オンのままだとコントロールモードが壊れるためです。最後のコントロールモードのクライアントが離れると、保存した値に戻します。通常のクライアントの接続では何も変わりません。

判定は[`src/lib/sensible/sensible.sh`](src/lib/sensible/sensible.sh)に純粋な関数としてまとめています。`SENSIBLE_DRY_RUN`を設定すると、適用処理はtmuxのコマンドを実行せずに表示します。テストはこれでバージョンごとの組み合わせを確かめています。

## 開発

| コマンド | 実行するもの |
|:--------|:-------------|
| `make test` | batsのテストスイート |
| `make lint` | すべてのシェルファイルに対するwarningレベルのshellcheck |
| `make coverage` | 下限95パーセントのkcovによる行カバレッジ、Linuxのみ |
| [`family/bin/audit`](family/bin/audit) | ファミリーの規約に対するこのリポジトリの検査 |

## ライセンス

[MIT](LICENSE)、copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約、`family/` 配下の同じツール、同じ共有ライブラリを持ち、チェックサムの一覧によってバイト単位で同一に保たれています。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。この義務は記憶に頼らず規約に書かれており、`family/bin/sweep` がその作業を行います。

| メンバー | 機能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | tmuxの設定を編集して保存するだけで、キーもコマンドも使わずに自動で再読み込みされます |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | tmuxのステータスバーに電池の状態を表示し、ステータスの描画を一切止めません |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 接続中のすべてのBluetooth機器とその電池残量をtmuxのステータスバーに表示し、描画を止めません |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPUの負荷、温度、周波数をtmuxのステータスバーに表示し、描画を一切止めません |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | tmuxのステータスバーにディスク使用量を表示し、ステータスの描画を一切止めません |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 画面上の URL、パス、ハッシュなどのトークンを fzf で選び、カーソル位置に入力します。純粋なシェルだけで動きます |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | ポップアップ内の fzf ピッカーから、tmux のセッション、ウィンドウ、ペインの切り替え、終了、名前変更、作成を行います |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | アクティブなペインのgitブランチ、変更、プロバイダーの件数を、描画を止めずにtmuxのステータスバーに表示します |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | NVIDIA、AMD、Intel、Apple の GPU の負荷、温度、クロック、電力、メモリを tmux のステータスバーに表示します |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 現在の Kubernetes コンテキストと名前空間を、kubectl を使わずに kubeconfig から解析して tmux のステータスバーに表示します |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 任意の TUI アプリを、現在のペインのディレクトリでポップアップまたはウィンドウとして起動します。アプリごとにキーを設定できます |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 任意のペインをファイルに保存します。ライブのログ記録、スクロールバック全体、1 回限りのスクリーンショットに対応します |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 再生中の曲をステータスバーに表示し、ステータスの描画を止めません |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | ネットワークのスループットをステータスバーに表示し、描画を止めません |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux のペインとウィンドウの操作キー。tmux のバージョンに対応し、vim と共存でき、どの prefix キーも無効にできます |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | tmuxのすべてのセッション、ウィンドウ、ペインを保存し、タイマーで自動保存して、再起動後にすべて復元します |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CI、ファミリーのツールを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | **このプラグイン**、tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

### インストールの確認

全メンバーがディスク上にあれば、1 つのコマンドでメンバー間の衝突を報告できます。

```sh
family/bin/doctor --live
```

各メンバーと実行中の tmux サーバーを読み取り、重複したキー、重複したステータスのプレースホルダー、命名規則に合わないオプション、規約のバージョンが古いメンバーを報告します。

<!-- family:end -->
