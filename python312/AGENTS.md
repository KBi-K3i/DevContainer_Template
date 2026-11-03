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

## ドキュメント・説明の書き方（README・設計メモ・コメント）

- **F型（見出し → 小見出し → 本文）**：設定キーや用語の解説は、キーごとに番号付きの小見出し（例 `#### 6.1`／`##### 6.1.1. name`）＋本文で書く。`- **key**: …` の平箇条書きで並べない（Markdown の見出し階層で「どのキーの話か」を一目で分かるようにする）。
- **反要約（流れる説明文）**：「意味＝…／理由＝…」のようなラベル＋`＝`の電報体にせず、「何をするか」と「なぜそうするか」を流れる文で綴る。その設定を触ったことがない人でも情景が浮かぶ濃さ（具体例・対比・効き目まで）を目安にし、名前だけ・言い切りだけで終えない。
- **出典主義**：ツールの既定挙動や公式仕様といった事実の主張には、一次情報（公式ドキュメント）を脚注で裏づける。URL は実在を確認してから載せる（捏造しない）。
