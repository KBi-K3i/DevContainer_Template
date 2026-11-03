# DevContainer Template

VS Code Dev Containers で、再現可能な開発環境をすぐ立ち上げるためのテンプレート集。
clone して対象バージョンのフォルダ（例 `python312/`）を VS Code で開き、「Reopen in Container」するだけ。
新しい PC や職場の異動で環境がリセットされても、ここから即再構築できる。

## 利用可能なテンプレート

| フォルダ | 内容 |
|---|---|
| [`python312/`](python312/) | Python 3.12 + uv（Ruff / mypy / pytest）。VS Code 拡張・設定込み。コンテナメモリ上限 16GB。 |

（将来 `python313/` など他バージョンを横に追加予定。各フォルダが自己完結したテンプレート。）

## 開くフォルダとビルドコンテキスト

VS Code で開くのは**各テンプレのフォルダ**（例 `python312/`）。その中の `.devcontainer/` を VS Code が読み、`.devcontainer/Dockerfile` から **ビルドコンテキスト ＝ `python312/`** としてイメージを作り、`python312/` を `/workspace` にマウントしてコンテナへ入る。コマンドパレット（F1）→ `Dev Containers: Reopen in Container`（初回は `Open Folder in Container…`）。

## 共通ガイド

### 前提（どのテンプレでも共通）

Windows に **WSL(Ubuntu)** ／ **コンテナエンジン（Docker か Podman）** ／ **VS Code ＋ Dev Containers 拡張** ／ **GitHub への SSH 鍵**。

### Git の名前・鍵はコンテナに同梱しない（ホストから自動共有される）

VS Code Dev Containers は、起動時に**ホストの `~/.gitconfig` をコンテナへ自動コピー**し、**ローカルの SSH エージェントを自動フォワード**する（HTTPS のクレデンシャルヘルパも共有）。そのため **git の名前/メールや SSH 鍵をテンプレに同梱する必要はない**——ホスト側（WSL）で一度設定しておけば、コンテナ内の git でもそのまま使える。

ホスト側（WSL）で一度だけ行っておくと快適な git 設定：

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main   # 新規リポジトリの既定ブランチ
git config --global push.default current       # 引数なし push は現在ブランチを同名で送る
git config --global fetch.prune true           # 削除済みリモートブランチの追跡を自動掃除
```

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
- Git 認証の共有（VS Code）: https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials
- Docker Desktop WSL 2 backend: https://docs.docker.com/desktop/features/wsl/
- Podman（公式ドキュメント）: https://podman.io/docs
- VS Code Dev Containers: https://code.visualstudio.com/docs/devcontainers/containers
- devcontainer.json リファレンス: https://containers.dev/implementors/json_reference/
- uv（Astral）: https://docs.astral.sh/uv/ ／ uv in Docker: https://docs.astral.sh/uv/guides/integration/docker/

解説つきの詳しい構築手順は Qiita 記事（準備中）を参照。
