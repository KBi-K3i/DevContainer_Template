# DevContainer Template

VS Code Dev Containers で、再現可能な開発環境をすぐ立ち上げるためのテンプレート集。
clone して対象バージョンのフォルダ（例 `python312/`）を VS Code で開き、「Reopen in Container」するだけ。
新しい PC や職場の異動で環境がリセットされても、ここから即再構築できる。

## 利用可能なテンプレート

| フォルダ | 内容 |
|---|---|
| [`python312/`](python312/) | Python 3.12 + uv（Ruff / mypy / pytest）。VS Code 拡張・設定込み。コンテナメモリ上限 16GB。 |

（将来 `python313/` など他バージョンを横に追加予定。各フォルダが自己完結したテンプレート。）

## 「開くフォルダ」と「ビルドコンテキスト」はどこか

- VS Code で開くのは**各テンプレのフォルダ**（例 `python312/`）。その中の `.devcontainer/` を VS Code が読み、`.devcontainer/Dockerfile` から **ビルドコンテキスト ＝ `python312/`** としてイメージを作り、`python312/` を `/workspace` にマウントしてコンテナへ入る。
- つまり**ビルドコンテキストはリポジトリ直下ではなく、開いた個別フォルダ（`python312/`）**。リポジトリ直下の `README.md` / `gitconfig` / `bashrc` はコンテナには入らない（下記のとおり、これは意図どおり）。

## ホスト側セットアップ samples（リポジトリ直下・バージョン非依存・一度だけ）

`gitconfig` と `bashrc` は **WSL(Ubuntu) ホストの `~/.gitconfig` / `~/.bashrc` に適用する「ホスト設定のサンプル」**。コンテナの中身（ビルドコンテキスト）ではないので、**あえて各テンプレフォルダの外＝リポジトリ直下**に置いている（全バージョンで共通に使えるように）。

- [`gitconfig`](gitconfig) … `~/.gitconfig` のサンプル。**`name` / `email` を記入**してから使う：
  ```bash
  cp gitconfig ~/.gitconfig   # その後 name/email を記入
  ```
  設定：`init.defaultBranch=main`（新規リポジトリの既定ブランチ）／`push.default=current`（引数なし push は現在ブランチを同名で送る）／`fetch.prune=true`（削除済みリモートブランチの追跡を自動掃除）／`core.editor=vim`。
- [`bashrc`](bashrc) … `~/.bashrc` 追記サンプル（alias ＋ Git ブランチ表示プロンプト）：
  ```bash
  sudo apt install -y git bash-completion   # git-prompt に必要
  cat bashrc >> ~/.bashrc && source ~/.bashrc
  ```

## 共通ガイド

### 前提（どのテンプレでも共通）

Windows に **WSL(Ubuntu)** ／ **コンテナエンジン（Docker か Podman）** ／ **VS Code ＋ Dev Containers 拡張** ／ **GitHub への SSH 鍵**。

### コンテナエンジン：Docker か Podman か

既定は Docker（Docker Desktop の WSL integration、または WSL 内の Docker Engine）。**Podman を使う場合**は、Dev Containers 拡張が動く側（ローカル WSL／Remote-SSH 先の VM）の **VS Code「Remote/Machine」settings.json** に次を入れて、エンジンを podman に切り替える：

```json
{
  "dev.containers.dockerPath": "podman",
  "dev.containers.dockerComposePath": "docker-compose"
}
```

- これは**リポジトリ内の `.vscode/settings.json` ではなく、VS Code のユーザー／リモート設定**に置く（エンジンの選択は"環境側"の設定のため）。コマンドパレット（F1）→「Preferences: Open Remote Settings」等で開く。
- 入れたら VS Code を再読み込みする。以後「Reopen in Container」が podman で動く。

### 公式リファレンス

- WSL インストール（Microsoft）: https://learn.microsoft.com/windows/wsl/install
- GitHub への SSH 接続: https://docs.github.com/authentication/connecting-to-github-with-ssh
- Docker Desktop WSL 2 backend: https://docs.docker.com/desktop/features/wsl/
- Podman（公式ドキュメント）: https://podman.io/docs
- VS Code Dev Containers: https://code.visualstudio.com/docs/devcontainers/containers
- devcontainer.json リファレンス: https://containers.dev/implementors/json_reference/
- uv（Astral）: https://docs.astral.sh/uv/ ／ uv in Docker: https://docs.astral.sh/uv/guides/integration/docker/

解説つきの詳しい構築手順は Qiita 記事（準備中）を参照。
