FROM python:3.12-slim

# OSツール（git/ssh/curl/証明書）＋ SQLite CLI ＋ TZ/ロケール素材、日本語ロケール生成
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git openssh-client curl ca-certificates sqlite3 tzdata locales \
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

WORKDIR /workspace
