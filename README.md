# DevContainer Template

VS Code Dev Containers で、再現可能な開発環境をすぐ立ち上げるためのテンプレート集。
clone して対象バージョンのフォルダを VS Code で開き、「Reopen in Container」するだけ。
新しい PC や職場の異動で環境がリセットされても、ここから即再構築できる。

## 利用可能なテンプレート

| フォルダ | 内容 |
|---|---|
| [`python312/`](python312/) | Python 3.12 + uv（Ruff / mypy / pytest）。VS Code 拡張・設定込み。コンテナメモリ上限 16GB。 |

（将来、`python313/` など他バージョンを横に追加予定。）

## ホスト側セットアップ samples（バージョン非依存・一度だけ）

WSL(Ubuntu) 側で一度やっておくと快適な設定。

- [`gitconfig`](gitconfig) … `~/.gitconfig` のサンプル。**`name` / `email` を自分のものに記入**してから使う：
  ```bash
  cp gitconfig ~/.gitconfig   # その後 name/email を記入
  ```
  含む設定：`init.defaultBranch=main`（新規リポジトリの既定ブランチ）／`push.default=current`（引数なし push は現在ブランチを同名で送る）／`fetch.prune=true`（削除済みリモートブランチの追跡を自動掃除）／`core.editor=vim`。
- [`bashrc`](bashrc) … `~/.bashrc` 追記サンプル。alias と、Git ブランチを色付き表示するプロンプト（カレントディレクトリ名のみ・入力は次の行）：
  ```bash
  sudo apt install -y git bash-completion   # git-prompt に必要
  cat bashrc >> ~/.bashrc && source ~/.bashrc
  ```

## 前提（共通）

Windows に WSL(Ubuntu)、Docker（Docker Desktop の WSL integration か WSL 内 Docker Engine）、VS Code ＋ Dev Containers 拡張、GitHub への SSH 鍵登録。解説つきの詳しい構築手順は Qiita 記事（準備中）を参照。
