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
