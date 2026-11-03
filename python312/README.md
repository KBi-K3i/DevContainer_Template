# Python 3.12 DevContainer テンプレート（uv）

WSL + Docker + VS Code Dev Containers による、再現可能な Python 3.12 開発環境。
依存は `uv` で管理し、Ruff（lint＋整形）・mypy（型・strict）・pytest を同梱。

## 構成

```text
python312/
├── .devcontainer/
│   ├── devcontainer.json   # VS Code のコンテナ設定（拡張・/workspace マウント・メモリ16GB・postCreate: uv sync）
│   └── Dockerfile          # python:3.12-slim + uv + git/ssh/curl/sqlite3 + JST/日本語ロケール
├── .vscode/
│   ├── settings.json       # Pylance strict・Ruff 既定フォーマッタ・検索除外・インデント色 ほか
│   └── launch.json         # デバッグ構成（現在のファイル / pytest）
├── pyproject.toml          # 依存・ツール設定（uv / Ruff / mypy / pytest）
├── .gitignore
├── .editorconfig
├── cspell.json             # スペルチェック辞書（＋ project-words.txt）
├── project-words.txt
└── software_test/          # テスト（unit / integration）
    ├── unit/
    └── integration/
```

## 使い方

前提：WSL(Ubuntu) + Docker + VS Code（Dev Containers 拡張）＋ GitHub SSH。ホスト側の git / シェル設定は、リポジトリ直下の [`../gitconfig`](../gitconfig) / [`../bashrc`](../bashrc) を参照。

1. リポジトリを clone し、この `python312/` フォルダを VS Code で開く：
   ```bash
   cd ~/git/DevContainer_Template/python312 && code .
   ```
2. コマンドパレット（F1）→ `Dev Containers: Reopen in Container`。初回は `Open Folder in Container…`。
3. コンテナ内で動作確認：
   ```bash
   python -V && uv --version && git --version && uv sync
   ```

これで、エディタ・拡張・ターミナル・Python インタプリタがすべてコンテナの中で動く。

## メモリ上限

`devcontainer.json` の `runArgs: ["--memory=16g"]` でコンテナのメモリを 16GB に制限している。変えたい場合はこの値を編集する。

## 拡充の指針

- 依存：`uv add <pkg>`（本番）／`uv add --dev <pkg>`（開発）。`pyproject.toml` と `uv.lock` が更新されるので両方コミットする。
- Python 版：`Dockerfile` の `FROM python:3.x-slim` と `pyproject.toml` の `requires-python` を合わせる。別バージョンは `python3xx/` を横に作る。
- 拡張機能：`devcontainer.json` の `customizations.vscode.extensions`（用途依存＝自由に）。
- テスト：`software_test/unit`・`software_test/integration` に置く（`pyproject.toml` の `testpaths`）。
- CI：GitHub Actions で `uv sync` → `uv run ruff check` → `uv run mypy` → `uv run pytest`。

## 公式ガイド

- WSL: https://learn.microsoft.com/windows/wsl/install
- GitHub SSH: https://docs.github.com/authentication/connecting-to-github-with-ssh
- Docker（WSL）: https://docs.docker.com/desktop/features/wsl/
- Dev Containers: https://code.visualstudio.com/docs/devcontainers/containers
- uv: https://docs.astral.sh/uv/
