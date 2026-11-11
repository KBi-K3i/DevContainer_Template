# Python 3.12 DevContainer テンプレート（uv）

WSL / Rocky-Podman などの上で、VS Code Dev Containers による再現可能な Python 3.12 開発環境。
依存は `uv` で管理し、Ruff（lint＋整形）・mypy（型・strict）・pytest を同梱。コンテナは `compose.yaml` で起動する。

## 構成

```text
python312/
├── .devcontainer/
│   ├── devcontainer.json   # VS Code のコンテナ設定（compose を参照・拡張・postCreate: uv sync）
│   ├── compose.yaml        # サービス dev の起動条件（ビルド・/workspace マウント・メモリ16GB・環境変数）
│   ├── Dockerfile          # python:3.12-slim + uv + git/ssh/curl/sqlite3 + JST/日本語ロケール + シェル設定の焼き込み
│   └── shell-rc.sh         # コンテナのシェル設定（alias ＋ git ブランチ表示プロンプト。Dockerfile が /etc/bash.bashrc へ追記）
├── .vscode/
│   ├── settings.json       # Pylance strict・Ruff 既定フォーマッタ・検索除外・インデント色 ほか
│   ├── launch.json         # デバッグ構成（現在のファイル / pytest）
│   ├── cspell.json         # スペルチェック辞書（cSpell は .vscode/ も探索・＋ project-words.txt）
│   └── project-words.txt
├── pyproject.toml          # 依存・ツール設定（uv / Ruff / mypy / pytest）
├── .gitignore
├── .editorconfig
└── software_test/          # テスト（unit / integration）
    ├── unit/
    └── integration/
```

## 使い方

前提：WSL(Ubuntu) または Rocky-Podman など + コンテナエンジン（Docker / Podman）+ VS Code（Dev Containers 拡張）。git の名前/メールや SSH 鍵は**ホスト側で一度設定**すれば、VS Code が起動時に `~/.gitconfig` をコンテナへ自動コピー・SSH エージェントを転送するので、コンテナ内の git でもそのまま使える（ホスト設定・Podman 切替は、リポジトリ直下の [README](../README.md) 参照）。シェルのプロンプト/alias は、VS Code が持ち込まないぶん **Dockerfile でコンテナに焼き込み済み**（`.devcontainer/shell-rc.sh`）。

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

> **一から作る手順**は [BUILD.md](BUILD.md)（ファイルを空から1つずつ作って解説）。

## 複数リポジトリ／ブランチを1つの環境で扱う（A / B / C）

「環境」はこのテンプレが焼くイメージ（Python 3.12＋uv＋ツール）で固定され、依存は uv が各リポジトリの `pyproject.toml` の隣に `.venv` を作る（プロジェクト単位・キャッシュ `~/.cache/uv` は共有）。だから「環境は統一・リポジトリは別」を両立できる。

- **A（隔離）**：各リポジトリに `.devcontainer/` を置き、別コンテナで開く。リポジトリごとに独立。Python 版やサービス構成が枝分かれしうるならこれ。
- **B（横断）**：マウント先を版フォルダ単体でなく**親ディレクトリ**（例 `~/src`）へ向け、その中へ複数リポジトリを `git clone` して並べる。`devcontainer.json` の `workspaceFolder`/`workspaceMount`（compose なら `volumes`）が `/workspace` を結ぶ先を**親へ変える1か所**で B になる。各リポジトリで `uv sync`。分けたくなったら A へ。
- **C（同一リポジトリの複数ブランチ）**：`git worktree add ../feature-x feature-x` で、1つの clone から複数ブランチを別フォルダに同時チェックアウト。

> **`uv init` は要る？** 「clone してすぐ使える・手作業不要」の本線では不要。各リポジトリが `pyproject.toml`（＋`uv.lock`）を**同梱して配られ、clone 後は `uv sync` だけ**で揃う（`uv init` は初期化済みの既存リポジトリにはエラーになる）。`uv init` は**新規にプロジェクトを起こすとき**の足場生成に使い、作ったら commit すれば以後は「clone してすぐ」になる。生成物は uv の版で変わる（既定 build-backend＝`uv_build`／src レイアウト等）ので、決まった形を確実に配りたい足場は init 任せにせず**同梱（コミット）する**のがこのテンプレの方針。

## メモリ上限

`compose.yaml` の `mem_limit: 16g` でコンテナのメモリを 16 GiB に制限している。変えたい場合はこの値を編集する（rootless Podman では cgroup v2 が前提）。

## 拡充の指針

- 依存：`uv add <pkg>`（本番）／`uv add --dev <pkg>`（開発）。`pyproject.toml` と `uv.lock` が更新されるので両方コミットする。
- Python 版：`Dockerfile` の `FROM python:3.x-slim` と `pyproject.toml` の `requires-python` を合わせる。別バージョンは `python3xx/` を横に作る（[BUILD.md](BUILD.md) 末尾参照）。
- 拡張機能：`devcontainer.json` の `customizations.vscode.extensions`（用途依存＝自由に）。
- シェル設定：`.devcontainer/shell-rc.sh` を編集（alias やプロンプト）。Dockerfile が `/etc/bash.bashrc` に焼き込む。
- テスト：`software_test/unit`・`software_test/integration` に置く（`pyproject.toml` の `testpaths`）。
- CI：GitHub Actions で `uv sync` → `uv run ruff check` → `uv run mypy` → `uv run pytest`。

## 公式ガイド

リポジトリ直下 [README](../README.md) の「公式リファレンス」を参照。
