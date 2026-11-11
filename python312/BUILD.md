# python312 テンプレートを一から作る（Dev Container + compose + uv）

> この手順は、**clone せずに `python312/` テンプレートを空から作る**ための記録です。ふだんは [README](README.md) のとおり clone →「Reopen in Container」で十分ですが、「中で何が起きているか」を理解したい・別バージョン（`python313/` など）を自分で起こしたいときはこちらをたどってください。
>
> **前提（WSL・git・コンテナエンジン・Podman 切替・ホスト設定の入り方）は、リポジトリ直下の [README](../README.md) の「共通ガイド」を参照。** ここでは `python312/` の中身を作ることに集中します。作業は、開発する**ホスト側**（WSL／Rocky VM など、コンテナエンジンが動く側）のターミナルで行います。

## 0. 全体像（何を作るか）

`python312/` は「自己完結した1つのテンプレート」です。最終的に次の構成を作ります。

```text
python312/
├── .devcontainer/
│   ├── devcontainer.json   # VS Code にコンテナの開き方を伝える（compose を参照）
│   ├── compose.yaml        # サービス（コンテナ）の起動条件＝ビルド・マウント・環境変数
│   ├── Dockerfile          # イメージの作り方（3.12-slim＋uv＋OSツール＋JST/日本語）
│   └── shell-rc.sh         # コンテナ内シェルの alias／git ブランチ表示
├── .vscode/
│   ├── settings.json       # 型チェック・整形・除外・UI など
│   ├── launch.json         # デバッグ構成
│   ├── cspell.json         # スペルチェック設定（cSpell は .vscode/ も探索）
│   └── project-words.txt   # 専用辞書
├── pyproject.toml          # 依存とツール設定（uv／Ruff／mypy／pytest）
├── .gitignore
├── .editorconfig
├── AGENTS.md               # AI 開発ツール向けの共通コンテキスト
├── CLAUDE.md               # AGENTS.md への入口
└── software_test/          # テスト（unit / integration）
```

`.venv/`・`uv.lock`・`.python-version` は書きません。これらは最後の `uv sync`（§7）で **uv が生成**します（`.venv/` は `.gitignore`、`uv.lock`・`.python-version` はコミット対象）。

まずフォルダの骨格を作ります。

```bash
mkdir -p python312/.devcontainer python312/.vscode python312/software_test/unit python312/software_test/integration
```

以降、`python312/` の中に各ファイルを作っていきます。順番は「依存の土台（`pyproject.toml`）→ コンテナ定義（`.devcontainer/`）→ エディタ・品質設定 → AI 向け」。

## 1. `pyproject.toml`（依存とツールの土台）

最初に作ります。コンテナ作成直後に走る `uv sync`（§7）がこのファイルを読むので、これが無いと依存をそろえられません。

```toml
[project]
name = "my-app"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []

[dependency-groups]
dev = ["ruff", "mypy", "pytest"]

[tool.ruff]
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "B", "UP"]

[tool.mypy]
strict = true

[tool.pytest.ini_options]
testpaths = ["software_test"]
```

- **`[project]`**：`name`・`version` は識別用、`requires-python = ">=3.12"` は「Python 3.12 以上が必要」の宣言です（別バージョンのテンプレを作るときは、ここと `Dockerfile` の `FROM` をそろえます）。`dependencies` は本番で使う依存の一覧で、最初は空。`uv add <pkg>` で増えます。
- **`[dependency-groups].dev`**：開発時だけ使う依存のグループ。Ruff（lint＋整形）・mypy（型）・pytest（テスト）を入れています（`uv add --dev <pkg>` で追加）。
- **`[tool.ruff]` / `[tool.ruff.lint]`**：1行の長さを 100 文字に。有効ルールは `E`（pycodestyle）・`F`（Pyflakes＝未使用 import 等）・`I`（isort＝import 整列）・`B`（bugbear＝バグになりやすい書き方）・`UP`（pyupgrade＝新しい書き方へ）。
- **`[tool.mypy].strict`**：型チェックを厳格モードに。型注釈の抜けや曖昧さに厳しくなり、実行前に食い違いを捕まえられます（エディタ側の Pylance strict＝§3.1 と二重に効く）。
- **`[tool.pytest.ini_options].testpaths`**：pytest がテストを探す場所を `software_test` に固定。引数なしの `uv run pytest` でここだけを対象に走ります。

## 2. `.devcontainer/`（コンテナの定義）

コンテナの姿は4ファイルで決めます。**土台のイメージ（`Dockerfile`）→ シェル設定（`shell-rc.sh`）→ 起動条件（`compose.yaml`）→ VS Code への橋渡し（`devcontainer.json`）** の順に作ります。

### 2.1 `.devcontainer/Dockerfile`

コンテナのもとになるイメージの作り方です。Python の軽量公式イメージを土台に、開発に要る OS ツール・uv・日本語/JST の設定を足します。

```dockerfile
FROM python:3.12-slim

# OSツール（git/ssh/curl/証明書）＋ SQLite CLI ＋ TZ/ロケール素材 ＋ bash 補完、日本語ロケール生成
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git \
      openssh-client \
      curl \
      ca-certificates \
      sqlite3 \
      tzdata \
      locales \
      bash-completion \
 && sed -i '/ja_JP.UTF-8/ s/^# //' /etc/locale.gen \
 && locale-gen \
 && rm -rf /var/lib/apt/lists/*

# uv を公式イメージからコピー（再現性重視なら :latest でなく版をピン留め）
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# タイムゾーン＝JST／ロケール＝日本語
ENV TZ=Asia/Tokyo \
    LANG=ja_JP.UTF-8 \
    LANGUAGE=ja_JP:ja \
    LC_ALL=ja_JP.UTF-8
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV UV_LINK_MODE=copy \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# コンテナのシェル設定（エイリアス＋ git ブランチ表示プロンプト）を焼き込む。
# VS Code はホストの ~/.gitconfig は自動コピーするが ~/.bashrc は持ち込まないため、ここで入れる。
COPY --chmod=644 shell-rc.sh /tmp/shell-rc.sh
RUN cat /tmp/shell-rc.sh >> /etc/bash.bashrc && rm /tmp/shell-rc.sh

WORKDIR /workspace
```

- **`FROM python:3.12-slim`**：Python を載せた公式イメージの軽量版。`slim` は最小限の Debian パッケージだけを含み軽いぶん、開発用コマンド（git・ssh・sqlite など）は入っていないので次の `RUN` で補います。別バージョンは `FROM` のタグと `pyproject.toml` の `requires-python` をそろえます。
- **`RUN apt-get …`**：git・openssh-client（git が SSH でやり取りする本体）・curl・sqlite3・bash 補完などを入れ、同じレイヤで日本語ロケール（`ja_JP.UTF-8`）を生成します（`/etc/locale.gen` の該当行のコメントを `sed` で外して `locale-gen`）。末尾の `--no-install-recommends` と `rm -rf …/apt/lists/*` はイメージを膨らませないための定石です。
- **`COPY --from=ghcr.io/astral-sh/uv:latest …`**：uv 公式イメージから `uv`／`uvx` のバイナリだけを写し取ります。uv は静的バイナリなので pip 不要でこの一行で入ります（厳密な再現性を求めるなら `:latest` でなく版をピン留め）。
- **`ENV TZ…` ＋ `ln -snf … /etc/localtime`**：タイムゾーンを JST、ロケールを日本語に。環境変数と `/etc/localtime` のリンクの両方を Tokyo に向け、`date` や git のコミット時刻が +0900 になるようにします。
- **`ENV UV_LINK_MODE=copy …`**：bind mount 上で uv がリンクを張れず警告になるのを避ける `copy`、`.pyc` を書かせない、出力をためない、の開発向け定番設定。
- **`COPY shell-rc.sh …` ＋ `RUN cat … >> /etc/bash.bashrc`**：次の `shell-rc.sh` をイメージに焼き込みます。VS Code はホストの `~/.gitconfig` は持ち込みますが `~/.bashrc` は持ち込まないため、シェルの alias／プロンプトはここで入れます。
- **`WORKDIR /workspace`**：既定の作業ディレクトリを、compose がマウントする `/workspace` に合わせます。

### 2.2 `.devcontainer/shell-rc.sh`

Dockerfile が `/etc/bash.bashrc` に焼き込む中身。alias と、いまいる Git ブランチを色付きで出すプロンプトを定義します。

```bash
# --- DevContainer シェル設定（Dockerfile により /etc/bash.bashrc へ追記される）---

# エイリアス
alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias grep='grep --color=auto'

# git ブランチを色付きで表示（カレントディレクトリ名のみ・入力は次の行）
__git_branch() { git branch 2>/dev/null | sed -n 's/^\* \(.*\)/ (\1)/p'; }
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[33m\]$(__git_branch)\[\033[00m\]\n\$ '
```

`__git_branch` は `git branch` の出力から**いまいるブランチ（先頭が `*` の行）だけ**を `sed` で取り出す自作関数で、`git-prompt` 等に依存せずどのコンテナでも動きます。`PS1` の `\W` は**カレントディレクトリ名だけ**（フルパスの `\w` ではない）、末尾の `\n` で**プロンプトと入力行を改行で分け**ます（パスやブランチ名が長くても入力位置がぶれない）。色はユーザー名＝緑・ディレクトリ＝青・ブランチ＝黄。

### 2.3 `.devcontainer/compose.yaml`

「このイメージを、どんな条件で1つのサービスとして起動するか」を宣言します。次の `devcontainer.json` がこれを指して「Reopen in Container」につなげます。

```yaml
services:
  dev:
    build:
      context: .
      dockerfile: Dockerfile
    init: true
    mem_limit: 16g
    volumes:
      - ..:/workspace:Z
    working_dir: /workspace
    environment:
      - TZ=Asia/Tokyo
      - LANG=ja_JP.UTF-8
      - LC_ALL=ja_JP.UTF-8
      - PYTHONDONTWRITEBYTECODE=1
      - PYTHONUNBUFFERED=1
      - UV_LINK_MODE=copy
    tty: true
    stdin_open: true
```

- **`services.dev` / `build`**：`dev` という1サービスを定義し、イメージは同じ `.devcontainer/` の `Dockerfile` からビルド。`context: .` はビルドの基準フォルダを `.devcontainer/` にする指定で、Dockerfile が `COPY` する `shell-rc.sh` がこの中にあるため、ここを基準にします（`compose.yaml` 自身のある場所からの相対）。
- **`init: true`**：コンテナの PID 1 に軽量な init（Docker では tini、Podman では catatonit）を据えます。無いと停止シグナルがアプリに届かず `Ctrl+C`・停止が効きにくかったり、終了した子プロセスが「ゾンビ」として残ったりします。init がシグナル転送と後片付けを担います。
- **`mem_limit: 16g`**：コンテナのメモリ上限を 16 GiB に固定。言語サーバやテストが暴走しても被害をコンテナ内（OOM）に閉じ込め、ホスト全体を巻き込まない安全弁です（マシンに合わせて増減）。
- **`volumes: - ..:/workspace:Z`**：1つ上＝このテンプレのフォルダ（`python312/`）をコンテナの `/workspace` に bind mount（ホスト側にファイルが残るので VS Code で編集できる）。末尾の **`:Z`** は SELinux（RHEL 系＝Rocky など）向けの再ラベル付けで、無いとマウント先に触れず `Permission denied` になります（SELinux の無い環境では無視されるだけで害なし）。
- **`working_dir: /workspace`**：コンテナに入った直後の作業ディレクトリをマウント先に合わせます。
- **`environment`**：TZ（JST）・ロケール（日本語 UTF-8）・Python/uv 変数を**実行時にも明示**。Dockerfile にも焼いていますが、compose を見れば実効値が分かるようここでも宣言します。
- **`tty: true` / `stdin_open: true`**：擬似端末と標準入力を割り当て**コンテナを起動したまま保つ**2つ。開発コンテナは「入って対話的に作業する」用途なので、無いと起動直後に落ちます。

### 2.4 `.devcontainer/devcontainer.json`

VS Code に「どのコンテナを、どう開き、何を入れるか」を伝えます。コンテナの起動そのものは `compose.yaml` に任せ、ここでは**どの compose のどのサービスを使うか**と、**入れる拡張・開いたあとの処理**を書きます。

```jsonc
{
  "name": "python-uv-devcontainer",
  "dockerComposeFile": "compose.yaml",
  "service": "dev",
  "workspaceFolder": "/workspace",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-python.debugpy",
        "charliermarsh.ruff",
        "njpwerner.autodocstring",
        "usernamehw.errorlens",
        "streetsidesoftware.code-spell-checker",
        "DmitryDorofeev.empty-indent",
        "mhutchie.git-graph",
        "waderyan.gitblame",
        "adam-bender.commit-message-editor",
        "DavidAnson.vscode-markdownlint",
        "shd101wyy.markdown-preview-enhanced",
        "bpruitt-goddard.mermaid-markdown-syntax-highlighting",
        "yy0931.vscode-sqlite3-editor",
        "MS-CEINTL.vscode-language-pack-ja",
        "mutantdino.resourcemonitor",
        "redhat.vscode-yaml",
        "tamasfe.even-better-toml",
        "mikestead.dotenv"
      ],
      "settings": {
        "python.defaultInterpreterPath": "${containerWorkspaceFolder}/.venv/bin/python"
      }
    }
  },
  "postCreateCommand": "uv sync"
}
```

- **`dockerComposeFile` / `service`**：コンテナ定義を `compose.yaml` に委ね、その `dev` サービスを開発環境として使う指定。メモリ上限やマウントを `devcontainer.json` に書かずに済むのは、それらを compose 側（`mem_limit`・`volumes`）が持つためです。
- **`workspaceFolder: /workspace`**：接続後に VS Code が開くフォルダ。compose の `volumes`（`..:/workspace`）・`working_dir` と `/workspace` でそろえます。
- **`customizations.vscode.extensions`**：コンテナに自動で入れる拡張（Python 本体・Pylance・Ruff・デバッガ・Git 可視化・Markdown・YAML/TOML/.env・日本語 UI・リソース表示 など）。用途に応じて足し引きしてよい部分です。
- **`settings`**：ここは「使う Python を `/workspace/.venv/bin/python` に固定」する1行だけ。整形・型チェックなどの細かな設定は `.vscode/settings.json`（§3.1）に集約し、バージョン管理します。
- **`postCreateCommand: uv sync`**：コンテナ作成直後に一度だけ `uv sync` を走らせ、`pyproject.toml`・`uv.lock` に基づいて依存をそろえます。だからコンテナに入った時点で依存のインストールが済んでいます。

> `remoteUser` を指定していないので、コンテナ内では **root** で動きます。手早く試すには十分ですが、実運用では非 root ユーザーで動かすほうが安全です。

## 3. `.vscode/`（エディタ設定）

### 3.1 `.vscode/settings.json`

ワークスペースに効く設定。§2.4 で触れたとおり、整形・型チェック・UI まわりはここに集約します。

```jsonc
{
  // --- Python / 型チェック（Pylance = Pyright エンジン） ---
  "python.defaultInterpreterPath": "/workspace/.venv/bin/python",
  "python.analysis.typeCheckingMode": "strict",
  "python.analysis.autoImportCompletions": true,
  "python.analysis.inlayHints.functionReturnTypes": true,
  "python.analysis.inlayHints.variableTypes": true,

  // --- Ruff を Python の既定フォーマッタに（保存時に整形＋import整理） ---
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.ruff": "explicit",
      "source.organizeImports.ruff": "explicit"
    }
  },

  // --- 検索・監視の除外＝VSCode 軽量化 ---
  "search.followSymlinks": false,
  "search.exclude": {
    "**/.venv": true,
    "**/.git": true,
    "**/__pycache__": true,
    "**/.ruff_cache": true,
    "**/.mypy_cache": true,
    "**/.pytest_cache": true,
    "**/*.db": true
  },
  "files.watcherExclude": {
    "**/.venv/**": true,
    "**/.git/**": true,
    "**/__pycache__/**": true,
    "**/.ruff_cache/**": true,
    "**/.mypy_cache/**": true,
    "**/.pytest_cache/**": true
  },

  // --- スペルチェック（cSpell）の設定は .vscode/cspell.json に外出し ---

  // --- errorlens / markdownlint / autoDocstring ---
  "errorLens.enabledDiagnosticLevels": ["error", "warning", "info"],
  "markdownlint.config": {
    "MD013": false,
    "MD033": false,
    "MD041": false
  },
  "autoDocstring.docstringFormat": "google",

  // --- resourcemonitor（ステータスバーに CPU使用率・メモリのみ） ---
  "resmon.show.cpuusage": true,
  "resmon.show.mem": true,
  "resmon.show.cpufreq": false,
  "resmon.show.battery": false,
  "resmon.show.disk": false,

  // --- インデント/括弧を6段階で色分け（ネイティブ・拡張不要） ---
  "editor.guides.indentation": true,
  "editor.guides.highlightActiveIndentation": true,
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": "active",
  "workbench.colorCustomizations": {
    "editorIndentGuide.background1": "#F8766D55",
    "editorIndentGuide.background2": "#C49A0055",
    "editorIndentGuide.background3": "#53B40055",
    "editorIndentGuide.background4": "#00C0AF55",
    "editorIndentGuide.background5": "#00A5FF55",
    "editorIndentGuide.background6": "#E76BF355",
    "editorIndentGuide.activeBackground1": "#F8766DBB",
    "editorIndentGuide.activeBackground2": "#C49A00BB",
    "editorIndentGuide.activeBackground3": "#53B400BB",
    "editorIndentGuide.activeBackground4": "#00C0AFBB",
    "editorIndentGuide.activeBackground5": "#00A5FFBB",
    "editorIndentGuide.activeBackground6": "#E76BF3BB"
  },

  // --- commit-message-editor（Conventional Commits を網羅） ---
  "commit-message-editor.view.defaultView": "form",
  "commit-message-editor.view.showRecentCommits": true,
  "commit-message-editor.tokens": [
    {
      "label": "種類",
      "name": "type",
      "type": "enum",
      "description": "変更の種類（Conventional Commits）",
      "options": [
        { "label": "feat",     "description": "新機能" },
        { "label": "fix",      "description": "バグ修正" },
        { "label": "docs",     "description": "ドキュメントのみ" },
        { "label": "style",    "description": "整形（空白・セミコロン等・動作不変）" },
        { "label": "refactor", "description": "リファクタ（機能変更なし）" },
        { "label": "perf",     "description": "性能改善" },
        { "label": "test",     "description": "テストの追加・修正" },
        { "label": "build",    "description": "ビルド・依存（uv 等）" },
        { "label": "ci",       "description": "CI 設定" },
        { "label": "chore",    "description": "雑務（本番コード変更なし）" },
        { "label": "revert",   "description": "以前のコミットを戻す" }
      ]
    },
    {
      "label": "スコープ",
      "name": "scope",
      "type": "text",
      "description": "影響範囲（任意。例: api, domain, adapter）",
      "prefix": "(",
      "suffix": ")"
    },
    {
      "label": "要約",
      "name": "description",
      "type": "text",
      "description": "要約（命令形・50字以内）"
    },
    {
      "label": "本文",
      "name": "body",
      "type": "text",
      "description": "本文（なぜ・何を）",
      "multiline": true,
      "lines": 5,
      "maxLines": 10
    },
    {
      "label": "破壊的変更",
      "name": "breaking_change",
      "type": "boolean",
      "description": "破壊的変更があるか（チェックで本文に BREAKING CHANGE: を付与）",
      "value": "BREAKING CHANGE: ",
      "default": false
    },
    {
      "label": "フッター",
      "name": "footer",
      "type": "text",
      "description": "フッター（例: Closes #123）",
      "multiline": true
    }
  ],
  "commit-message-editor.dynamicTemplate": [
    "{type}{scope}: {description}",
    "",
    "{body}",
    "",
    "{breaking_change}{footer}"
  ]
}
```

ブロックごとの要点：

- **Python / 型チェック**：インタプリタを `/workspace/.venv/bin/python` に固定（`devcontainer.json` 側と同じ場所）、`typeCheckingMode` を `strict`、補完時の import 自動追加・戻り型/変数型の inlay ヒントを有効化。
- **Ruff**：`[python]` に限定し、保存時に Ruff で整形（`formatOnSave`）＋自動修正（`source.fixAll.ruff`）＋import 整理（`source.organizeImports.ruff`）を `explicit`（保存操作のときだけ）で実行。
- **検索・監視の除外**：`.venv`・`.git`・各種キャッシュ・`*.db` を検索とファイル監視から外し、bind mount 上の大量ファイルで VS Code が重くなるのを防ぎます。
- **errorlens / markdownlint / autoDocstring**：行末インライン診断、技術文書で邪魔なルール（`MD013`/`MD033`/`MD041`）の無効化、docstring は Google スタイル。
- **resourcemonitor**：ステータスバーに CPU・メモリだけ表示（`mem_limit` と合わせて負荷を見る）。
- **インデント/括弧の6段階色分け**：VS Code ネイティブ機能。入れ子の深さが目で追えます。
- **commit-message-editor**：コミットメッセージをフォーム入力で書ける設定（Conventional Commits を暗記しなくても選ぶだけで規約に沿う）。

### 3.2 `.vscode/launch.json`

デバッグ構成。`debugpy` で2つの起動方法を用意します。

```jsonc
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: 現在のファイルを実行",
      "type": "debugpy",
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal",
      "justMyCode": true
    },
    {
      "name": "Python: pytest（現在のファイル）",
      "type": "debugpy",
      "request": "launch",
      "module": "pytest",
      "args": ["${file}", "-q"],
      "console": "integratedTerminal",
      "justMyCode": false
    }
  ]
}
```

- **現在のファイルを実行**：開いているファイル（`${file}`）をデバッグ実行。`justMyCode: true` で自分のコードだけをステップ対象に（ライブラリ内部に潜らない）。
- **pytest（現在のファイル）**：開いているテストを `pytest`（`python -m pytest` 相当）でデバッグ。`-q` で簡潔表示、こちらは `justMyCode: false` でライブラリ側も追えます。

## 4. ルートの設定ファイル

### 4.1 `.gitignore`

```text
.venv/
__pycache__/
*.pyc
.env
.env.*
.mypy_cache/
.ruff_cache/
.pytest_cache/
*.db
```

- **`.venv/`**：uv が作る仮想環境。`pyproject.toml`・`uv.lock` から再生成できる生成物で容量も大きいので除外。
- **`__pycache__/`・`*.pyc`**：Python のバイトコードキャッシュ（自動生成の一時物）。
- **`.env`・`.env.*`**：API キーやパスワードを書く環境変数ファイル。**絶対にコミットしない**ので最初から除外。
- **各種キャッシュ**：mypy・Ruff・pytest のキャッシュ（§3.1 で検索・監視からも除外済み）。
- **`*.db`**：SQLite などのローカル DB ファイル。

### 4.2 `.editorconfig`

エディタをまたいで整形ルールを統一します（VS Code 以外で開く人がいても崩れない）。

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 4

[*.{yml,yaml,json,jsonc,toml}]
indent_size = 2

[*.md]
trim_trailing_whitespace = false
```

- **`[*]`**：文字コード UTF-8、改行 LF、末尾改行あり、行末空白を削る、インデントはスペース4。
- **`[*.{yml,yaml,json,jsonc,toml}]`**：設定ファイル系はインデント2（浅いほうが読みやすい慣習）。
- **`[*.md]`**：Markdown だけ行末空白を削らない（行末の半角スペース2つが「改行」の意味を持つため）。

### 4.3 `.vscode/cspell.json` と `project-words.txt`

英単語のスペルチェック（Code Spell Checker 拡張）の設定と、その専用辞書です。cSpell は設定ファイルを、版フォルダ直下の `cspell.json` → `.vscode/cspell.json` → `.config/cspell.json` の順で探すので、`settings.json`・`launch.json` と同じ **`.vscode/`** に置きます（辞書 `project-words.txt` も隣に置けば `path` は `./project-words.txt` のままでよい）。

```jsonc
{
  "version": "0.2",
  "language": "en",
  "dictionaryDefinitions": [
    { "name": "project-words", "path": "./project-words.txt", "addWords": true }
  ],
  "dictionaries": ["project-words"],
  "words": [
    "pyproject",
    "venv",
    "devcontainer",
    "dockerfile",
    "pytest",
    "mypy",
    "ruff",
    "astral",
    "uvx",
    "pylance",
    "pyright",
    "dotenv",
    "toml",
    "autodocstring",
    "resmon",
    "markdownlint",
    "pydantic",
    "sqlite",
    "zoneinfo"
  ],
  "ignorePaths": [
    ".venv",
    "**/*.db",
    "uv.lock",
    ".git",
    "**/__pycache__",
    "**/.ruff_cache",
    "node_modules",
    "**/*.lock",
    "project-words.txt"
  ]
}
```

`dictionaryDefinitions`／`dictionaries` で `project-words.txt` を**追加可能な専用辞書**として登録（`addWords: true`＝エディタの「Add to Dictionary」でここに書き足される）。`words` は最初から許可する語、`ignorePaths` はそもそも見ない場所（生成物）です。`project-words.txt` は1行1語の素朴なテキストで、最初はコメントだけ。

```text
# プロジェクト固有の許可語辞書（1行1語）
# cSpell の「辞書に追加（Add to Dictionary）」操作でここに追記されます。
# 開発を進めながら必要な語を足していってください。
```

## 5. `AGENTS.md` と `CLAUDE.md`

AI コーディングツール（Claude Code 等）に、このテンプレの技術スタック・コマンド・規約を一枚で渡すファイル。`AGENTS.md` が本体（単一の正典）、`CLAUDE.md` はそこを指す入口にして二重管理を避けます。人が最初に読む「このリポジトリの歩き方」としても機能します。

`AGENTS.md`（例）:

```markdown
# AGENTS.md — Python + uv DevContainer テンプレート

このリポジトリで開発する AI コーディングツール（Claude Code 等）向けの共通コンテキスト。
技術スタック・コマンド・規約・ドキュメントの書き方をここに集約する（単一の正典）。

## 技術スタック

- Python 3.12 / uv（依存管理）/ Ruff（lint ＋ 整形）/ mypy（型・strict）/ pytest。
- 開発環境は VS Code Dev Containers（`.devcontainer/`）。立ち上げ方は README を参照。

## よく使うコマンド

- 依存同期：`uv sync`
- 追加：`uv add <pkg>` ／ `uv add --dev <pkg>`
- テスト：`uv run pytest`
- 型チェック：`uv run mypy src software_test`
- Lint／整形：`uv run ruff check` ／ `uv run ruff format`

## 規約

- コミットは Conventional Commits（`feat:` `fix:` `docs:` `refactor:` `test:` `chore:`）。1コミット＝1つの意味。
- 型は strict 前提（Pylance／Pyright strict）。公開関数には docstring。
- 秘密（API キー・トークン）は `.env`（コミット禁止）。`*.db`・`.venv` もコミットしない。
- テストは `software_test/unit`・`software_test/integration` に置く。
```

`CLAUDE.md`（中身を重複させず入口だけ）:

```markdown
# CLAUDE.md

このリポジトリの技術スタック・コマンド・規約・ドキュメントの書き方は [AGENTS.md](./AGENTS.md) を参照（単一の正典）。
```

## 6. `software_test/`

テストの置き場です。`pyproject.toml` の `testpaths` がここを指します。`unit/` と `integration/` の空フォルダを作っておきます（**Git は空フォルダを追跡しない**ので、テストを置いた時点でコミットされます）。§0 の `mkdir -p` で作成済みです。

## 7. 起動して確認する

ここまでで全ファイルがそろいました。あとは開いて動作を確かめます。

1. **`python312/` を VS Code で開く**。リモートのホスト（Rocky VM など）で作った場合は、VS Code の **Remote-SSH でホストに入ってから** `python312/` を開きます（手元で直接動かす場合はそのまま開く）。Podman を使うなら、ホスト側 settings に `dev.containers.dockerPath`／`dockerComposePath` を入れておきます（[README](../README.md) の「コンテナエンジン」参照）。
2. コマンドパレット（`F1`）→ **`Dev Containers: Reopen in Container`**（初回は `Open Folder in Container…` で `python312/` を指定）。VS Code が `devcontainer.json` → `compose.yaml` → `Dockerfile` とたどってビルドし、コンテナへ入れてくれます。`postCreateCommand` の `uv sync` が走り、`.venv`・`uv.lock`・`.python-version` が生成されます。
3. コンテナ内のターミナルで動作確認：

   ```bash
   python -V
   uv --version
   git --version
   date
   echo "$LANG"
   uv run pytest
   ```

   `Python 3.12.x`／uv・git が応答／`date` が +0900（JST）／`$LANG` が `ja_JP.UTF-8` になり、`uv run pytest` が走れば完成です（テストがまだ無ければ「no tests ran」）。

あとは `uv add <pkg>` で依存を足し、`uv run python <ファイル>` で実行していきます。

> **別バージョンを作るとき**：この `python312/` を丸ごと `python313/` にコピーし、`Dockerfile` の `FROM python:3.13-slim` と `pyproject.toml` の `requires-python = ">=3.13"` をそろえれば、同じ手順で新しい版が立ちます。1つのリポジトリが「環境テンプレ集」として育ちます。
