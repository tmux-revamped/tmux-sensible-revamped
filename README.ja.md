<div align="center">

# tmux-sensible-revamped

<strong>tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-sensible-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-sensible-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-sensible-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-sensible-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-sensible-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-sensible-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-sensible-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#クイックスタート"><strong>クイックスタート</strong></a> &nbsp;|&nbsp;
  <a href="#使い方">使い方</a> &nbsp;|&nbsp;
  <a href="#設定される内容">設定される内容</a> &nbsp;|&nbsp;
  <a href="#キーバインド">キーバインド</a> &nbsp;|&nbsp;
  <a href="#仕組み">仕組み</a> &nbsp;|&nbsp;
  <a href="#画面">画面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="1 つのコマンドで tmux の既定値を引き上げ、prefix C-n と C-p でウィンドウを切り替える sensible-revamped" width="800">
</p>

```console
$ tmux show-option -gv history-limit
2000
$ sensible-revamped apply
$ tmux show-option -gv history-limit
50000
```

多くのtmuxユーザーが手で書くことになる初期設定を、このプラグインが行います。ESCの遅延をなくし、スクロールバックを大きくし、ウィンドウ番号を1から始め、truecolorを有効にし、コピーをシステムのクリップボードに送ります。各設定は、実行中のtmuxのバージョンと外側の端末を確認してから適用します。お使いのtmuxにないオプションは飛ばします。

---

## クイックスタート

### 前提条件

| ツール | バージョン | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 以降 | ファミリー共通の最低バージョン。実行中の tmux にないオプションは飛ばします |
| クリップボードのツール | 任意 | `wl-copy`、`termux-clipboard-set`、`pbcopy`、`xclip`、`xsel`、`clip.exe` のいずれか。なければコピーは OSC 52 で端末を通ります |
| `infocmp` | 任意 | `default-terminal` に `tmux-direct` か `tmux-256color` を選びます。なければ `screen-256color` になります |
| gum | 任意 | `sensible-revamped` のメニュー、表、色。なくてもすべてのコマンドがプレーンテキストで動きます |

### インストール

```tmux
set -g @plugin 'tmux-revamped/tmux-sensible-revamped'
```

続けて `prefix + I` を押します。TPM を使わない場合は、リポジトリをクローンし、`~/.tmux.conf` からエントリーポイントを実行します。

```bash
git clone https://github.com/tmux-revamped/tmux-sensible-revamped ~/.tmux/plugins/tmux-sensible-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-sensible-revamped/sensible-revamped.tmux
```

クローンで `make install` を実行すると、`sensible-revamped` が `~/.local/bin` に、manページと補完が `~/.local/share` の下に入ります。

### 確認

```bash
~/.tmux/plugins/tmux-sensible-revamped/bin/sensible-revamped doctor
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

| コマンド | 動作 |
|:--------|:-------------|
| `sensible-revamped apply` | 既定値を設定し、キーを今すぐ割り当てます。プラグインの読み込み時にエントリーポイントが実行します |
| `sensible-revamped list` | `apply` が実行する tmux のコマンドをすべて表示し、何も変更しません。`--json` で 1 つのオブジェクトを出力します |
| `sensible-revamped resize-sync` | コントロールモードのクライアントが接続している間 `aggressive-resize` をオフにし、あとで元に戻します。クライアントのフックが実行します |
| `sensible-revamped doctor` | 依存関係ごとに 1 行。クリップボードのツールと、触れなかったキーも含みます |
| `sensible-revamped version` | バージョンと tmux のバージョン |
| `sensible-revamped help` | ヘルプ。`man sensible-revamped` にも同じコマンドと設定があります |
| `sensible-revamped` | 端末ではメニュー |

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

どのオプションも、ダッシュ区切りのコマンドオプション（例 `--reload-key R`）と環境変数（例 `SENSIBLE_REVAMPED_RELOAD_KEY`）で指定できます。優先順位はコマンドライン、環境変数、tmux オプションの順です。空の tmux オプションは既定値を意味します。`doctor` は、プラグインが認識できない値を持つ設定の名前を表示します。`@sensible_revamped_resize_saved` はプラグイン自身が書き込みます。

<a id="設定される内容"></a>

## 設定される内容

| 分野 | 設定 | 必要なtmux |
|:-----|:---------|:-------------|
| 遅延とフォーカス | `escape-time 10`、`focus-events on` | 1.9 |
| 端末の種類 | `default-terminal`は、truecolorとそのterminfoがあれば`tmux-direct`、`tmux-256color`のterminfoがあればそれ、なければ`screen-256color`になります。現在値が`screen`か`screen-256color`なら未設定とみなします | すべて |
| truecolor | 3.2以降は端末機能`RGB`、それより前は`Tc`の上書きです。`COLORTERM`が`truecolor`か`24bit`のとき、または`COLORTERM`が空でterminfoが`RGB`か`Tc`を報告するときに有効にします。`TERM`が入れ子の`screen`や`tmux`なら有効にしません | すべて |
| 下線 | `Smulx`と`Setulc`の上書きによる波線と色付き下線 | 3.0 |
| クリップボードとパススルー | `set-clipboard on`、3.3では`allow-passthrough on`、3.4以降では`all`、そして端末機能`clipboard`、`ccolour`、`cstyle`、`focus`、`title` | 機能は3.2 |
| 古いtmux向けのエスケープ | OSC 52の`Ms`上書きと、カーソル形状の`Ss`と`Se`上書き。対応が分かっている端末に限ります | 3.2未満のみ |
| グラフィックス | 対応する端末向けの端末機能`sixel`と`hyperlinks` | 3.4 |
| 拡張キー | サーバーがどの`TERM`で起動しても`extended-keys on`、3.5以降では`extended-keys-format csi-u`。tmuxは機能`extkeys`を持つと分かっている端末にだけ要求を送ります。機能`extkeys`自体はCSI uを話す端末に対してだけ宣言します | 3.2 |
| スクロールバックとステータス | `history-limit 50000`、`display-time 4000`、`status-interval 5`、`repeat-time 1000`、`display-panes-time 2000`、`set-titles on` | すべて |
| ウィンドウとペイン | `base-index 1`、`pane-base-index 1`、`renumber-windows on`、`aggressive-resize on` | 2つ目は1.6、3つ目は1.7 |
| コピーモード | `$EDITOR`か`$VISUAL`に`vi`が含まれれば`mode-keys vi`、そうでなければ`emacs`。`word-separators`を空白1文字にするので、ダブルクリックでパスやURL全体を選択できます | すべて |

CSI u対応とみなす端末は、xterm、kitty、foot、Alacritty、Contour、Rio、st、Konsole、iTerm2、WezTerm、Ghostty、minttyで、`TERM`と`TERM_PROGRAM`で判定します。

端末は、tmux サーバーが起動したときのものです。tmux はプラグインに自身の `TERM` と `TERM_PROGRAM` を渡すため、プラグインはどちらも tmux のグローバル環境から読み取ります。

<a id="キーバインド"></a>

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

<a id="仕組み"></a>

## 仕組み

[`sensible-revamped.tmux`](sensible-revamped.tmux)は読み込み時に`bin/sensible-revamped apply`を一度実行します。tmuxのバージョン、変更するかもしれないすべてのオプション、キーの表、端末を3回のtmux呼び出しで読み取り、4回目ですべてのコマンドを送ります。各コマンドは次の3つのガードのいずれかを通ります。

| ガード | 規則 |
|:------|:-----|
| 既定値を確認するセッター | オプションが空か、tmuxの既定値と等しいときだけ書き込みます |
| 一度だけ追加 | `terminal-overrides`や`terminal-features`の項目は、ないときだけ追加するので、再読み込みで一覧が伸びません |
| 空きキーの確認 | `tmux list-keys`にそのキーの割り当てがないときだけ、便利キーを割り当てます |

tmux 3.0以降では、`client-attached`と`client-detached`のフックが`sensible-revamped resize-sync`を実行します。iTerm2のコントロールモードのクライアントが1つでも接続している間、フックはグローバルの`aggressive-resize`の値を保存してオフにします。オンのままだとコントロールモードが壊れるためです。最後のコントロールモードのクライアントが離れると、保存した値に戻します。通常のクライアントの接続では何も変わりません。

`sensible-revamped list`は、`apply`が実行するコマンドをすべて表示し、何も変更しません。お使いのサーバーでプラグインが何をするかを確かめられます。

<a id="画面"></a>

## 画面

<details>
<summary>すべての画面。本物の tmux の中で <code>make screens</code> で録画し、押したキーをステータスラインに表示しています</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/defaults.png" alt="sensible-revamped: apply で tmux の既定値を引き上げる"><br><sub><code>apply</code> で tmux の既定値を引き上げる。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/next-window.png" alt="sensible-revamped: prefix C-n で次のウィンドウへ"><br><sub><code>prefix C-n</code> で次のウィンドウへ。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu.png" alt="sensible-revamped: メニュー"><br><sub>メニュー。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="sensible-revamped: doctor"><br><sub><code>doctor</code>。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/reload.png" alt="sensible-revamped: 再読み込みキーで設定をもう一度読み込む"><br><sub>再読み込みキーで設定をもう一度読み込む。<code>keys.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/last-window.png" alt="sensible-revamped: 直前のウィンドウに戻るキー"><br><sub>直前のウィンドウに戻るキー。<code>keys.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/copy.png" alt="sensible-revamped: vi のコピーモードで v が選択する"><br><sub>vi のコピーモードで <code>v</code> が選択する。<code>keys.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/copied.png" alt="sensible-revamped: y がクリップボードのツールにコピーする"><br><sub><code>y</code> がクリップボードのツールにコピーする。<code>keys.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/list.png" alt="sensible-revamped: list がすべてのコマンドを表示する"><br><sub><code>list</code> がすべてのコマンドを表示する。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="sensible-revamped: gum なしのメニュー"><br><sub>gum なしのメニュー。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="sensible-revamped: メニューからの doctor"><br><sub>メニューからの <code>doctor</code>。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="sensible-revamped: バージョン"><br><sub>バージョン。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="sensible-revamped: 不明なコマンド"><br><sub>不明なコマンド。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/themes.png" alt="sensible-revamped: 6 つのテーマのヘッダー"><br><sub>6 つのテーマのヘッダー。<code>themes.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/help.png" alt="sensible-revamped: ヘルプ"><br><sub>ヘルプ。<code>help.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="sensible-revamped: SENSIBLE_REVAMPED_ACCENT によるアクセント"><br><sub><code>SENSIBLE_REVAMPED_ACCENT</code> によるアクセント。<code>stills.tape</code>より</sub></td>
</tr>
</table>

</details>

## 移植性

プラグインは POSIX `sh` です。CI は下の各行ですべてのテストを実行します。

| シェル | 状態 |
|:------|:-------|
| `dash`、macOS の `/bin/sh` | 対応 |
| `bash` 3.2 と 5.x、システムの `zsh` と Homebrew の `zsh` | 対応 |

| システム | 状態 |
|:-------|:-------|
| macOS | Apple Silicon と Intel の Tahoe。付属のツール、Homebrew の GNU ツール、Homebrew の uutils で確認 |
| Linux | x86_64 と arm64 の Ubuntu 26.04。GNU coreutils、uutils、BusyBox で確認 |

## 開発

| コマンド | 実行内容 |
|:--------|:-------------|
| `make fmt` | すべてのスクリプトに shfmt `-i 2` をかけます |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint、actionlint を、指摘ゼロで通します |
| `make test` | システムの `sh` で bats のテスト |
| `make test-all` | インストール済みのすべてのシェルでテスト。macOS では bash と zsh の両方のビルドを含みます |
| `make test-linux` | Ubuntu のコンテナでテスト |
| `make coverage` | この Mac と Ubuntu のコンテナで bashcov を実行し、合算して 100 パーセントで判定します |
| `make screens` | 上の画面を、本物のプラグインから tmux の中で VHS で録画します。macOS で実行します |
| `make install` | コマンド、manページ、補完を `PREFIX` の下に置きます |

macOS では、`brew bundle` を実行すると、これらのターゲットが使うツールがすべて [`Brewfile`](Brewfile) からインストールされます。

コミットは Conventional Commits の形式に従い、そのまま `main` に入ります。`main` で `ci` が成功すると、`release.yml` が semantic-release を実行します。前回のタグ以降に `feat` か `fix` があればリリースを公開し、バージョン定数を更新し、変更内容を [`CHANGELOG.md`](CHANGELOG.md) に追加します。

## ライセンス

[MIT](LICENSE)、copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約と同じ共有ライブラリを持ちます。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。

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
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CIを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | **このプラグイン**、tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

<!-- family:end -->
